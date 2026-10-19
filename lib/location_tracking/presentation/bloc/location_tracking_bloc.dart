import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:school_desk_app/analytics/posthog_analytics_service.dart';
import 'package:school_desk_app/analytics/posthog_feature.dart';
import '../../data/datasources/location_tracking_service_gateway.dart';
import '../../domain/repositories/location_tracking_service.dart';
import 'location_tracking_event.dart';
import 'location_tracking_state.dart';

export 'location_tracking_event.dart';
export 'location_tracking_state.dart';

class LocationTrackingBloc
    extends Bloc<LocationTrackingEvent, LocationTrackingState> {
  LocationTrackingBloc({LocationTrackingServiceGateway? service})
    : _service = service ?? BackgroundLocationTrackingGateway(),
      super(const LocationTrackingState()) {
    // Serialize lifecycle requests and service events to avoid start/stop races.
    on<LocationTrackingEvent>(
      _onEvent,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    add(const LocationTrackingStatusRequested());
  }

  final LocationTrackingServiceGateway _service;
  bool _restarting = false;
  final List<StreamSubscription<Map<String, dynamic>?>> _subscriptions = [];

  void _subscribe() {
    if (_subscriptions.isNotEmpty) return;
    for (final name in [
      'on_location_update',
      'on_error',
      'on_tracking_stopped',
    ]) {
      _subscriptions.add(
        _service
            .events(name)
            .listen(
              (data) {
                if (_restarting && name == 'on_tracking_stopped') return;
                if (!isClosed) add(_ServiceEvent(name, data));
              },
              onError: (Object error) {
                if (!isClosed) {
                  add(_ServiceEvent('on_error', {'message': error.toString()}));
                }
              },
            ),
      );
    }
  }

  Future<void> _onEvent(
    LocationTrackingEvent event,
    Emitter<LocationTrackingState> emit,
  ) async {
    try {
      switch (event) {
        case LocationTrackingStatusRequested():
          emit(state.copyWith(status: LocationTrackingStatus.checking));
          _subscribe();
          final running = await _service.isRunning();
          if (emit.isDone) return;
          emit(
            state.copyWith(
              status: running
                  ? LocationTrackingStatus.tracking
                  : LocationTrackingStatus.stopped,
            ),
          );
        case LocationTrackingStarted():
          if (state.isTracking && !event.restart) {
            emit(state.copyWith(tripId: event.tripId));
            return;
          }
          emit(
            state.copyWith(
              status: LocationTrackingStatus.starting,
              tripId: event.tripId,
              distanceKm: 0,
              clearLocation: true,
            ),
          );
          _subscribe();
          if (event.restart) {
            _restarting = true;
            try {
              await _service.stop();
            } finally {
              _restarting = false;
            }
          }
          await _service.start(
            tripId: event.tripId,
            driverEmail: event.driverEmail,
          );
          if (emit.isDone) return;
          emit(state.copyWith(status: LocationTrackingStatus.tracking));
        case LocationTrackingStopped():
          final wasTracking = state.isTracking;
          emit(state.copyWith(status: LocationTrackingStatus.stopping));
          try {
            await _service.stop();
          } catch (_) {
            if (!emit.isDone) {
              emit(
                state.copyWith(
                  status: wasTracking
                      ? LocationTrackingStatus.tracking
                      : LocationTrackingStatus.stopped,
                ),
              );
            }
            rethrow;
          }
          if (emit.isDone) return;
          emit(
            state.copyWith(
              status: LocationTrackingStatus.stopped,
              clearLocation: true,
            ),
          );
        case _ServiceEvent():
          switch (event.name) {
            case 'on_tracking_stopped':
              emit(
                state.copyWith(
                  status: LocationTrackingStatus.stopped,
                  clearLocation: true,
                  errorMessage: state.errorMessage,
                ),
              );
            case 'on_error':
              emit(
                state.copyWith(
                  errorMessage:
                      event.data?['message']?.toString() ??
                      'Location service error',
                ),
              );
            case 'on_location_update':
              if (!state.isTracking || event.data == null) return;
              final data = event.data!;
              // Ignore malformed native messages without crashing the event loop.
              final latitude = data['latitude'];
              final longitude = data['longitude'];
              final timestamp = DateTime.tryParse(
                data['timestamp']?.toString() ?? '',
              );
              if (latitude is! num || longitude is! num || timestamp == null) {
                return;
              }
              emit(
                state.copyWith(
                  distanceKm:
                      (data['distanceKm'] as num?)?.toDouble() ??
                      state.distanceKm,
                  lastLocation: Position(
                    latitude: latitude.toDouble(),
                    longitude: longitude.toDouble(),
                    timestamp: timestamp,
                    accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0,
                    altitude: 0,
                    altitudeAccuracy: 0,
                    heading: (data['heading'] as num?)?.toDouble() ?? 0,
                    headingAccuracy: 0,
                    speed: (data['speed'] as num?)?.toDouble() ?? 0,
                    speedAccuracy: 0,
                  ),
                ),
              );
          }
      }
    } catch (error, stackTrace) {
      if (emit.isDone) return;
      final status = switch (state.status) {
        LocationTrackingStatus.starting ||
        LocationTrackingStatus.checking => LocationTrackingStatus.stopped,
        _ => state.status,
      };
      emit(state.copyWith(status: status, errorMessage: error.toString()));
      unawaited(
        posthogAnalytics.captureException(
          error,
          stackTrace: stackTrace,
          feature: PosthogFeature.locationTracking,
          action: event.runtimeType.toString(),
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    // Closing the UI does not stop the background tracking session.
    await Future.wait(
      _subscriptions.map((subscription) => subscription.cancel()),
    );
    _subscriptions.clear();
    await super.close();
  }
}

final class _ServiceEvent extends LocationTrackingEvent {
  const _ServiceEvent(this.name, this.data);
  final String name;
  final Map<String, dynamic>? data;
}
