import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/user_model.dart';
import '../../../services/storage/local_storage.dart';
import '../../../services/transport_service.dart';
import 'background_service_configurator.dart';
import 'trip_location_store.dart';

/// Driver-only trip tracking. GPS history never uploads while the trip is active.
class LocationService {
  static final store = TripLocationStore();

  static Future<void>? _initialization;
  static Future<void>? _stopping;

  /// Also reconnects the UI event channel when resuming an existing service.
  static Future<void> initialize() async {
    if (_initialization != null) return _initialization;
    final initialization = BackgroundServiceConfigurator.initialize(
      onStart: onStart,
      onBackground: onBackground,
    );
    _initialization = initialization;
    try {
      await initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  static Future<void> start({
    required int tripId,
    required String driverEmail,
  }) async {
    final user = await StorageHelper.getUserSession();
    if (user?.role != UserRole.driver ||
        user?.email != driverEmail ||
        tripId <= 0) {
      throw StateError('Only the signed-in driver can track an active trip.');
    }
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError(
        'Background trip tracking requires Android or iOS.',
      );
    }
    // A journal created after a confirmed start lets an interrupted trip resume offline.
    final journal = await store.session(tripId);
    if (journal == null) {
      final duty = await TransportService.getDriverDuty(email: driverEmail);
      if (duty?['tripStatus'] != 'IN_PROGRESS' ||
          duty?['activeTripId'] != tripId) {
        throw StateError(
          'Start the assigned trip successfully before tracking.',
        );
      }
    } else if (journal['driver_email'] != driverEmail ||
        journal['state'] != 'active') {
      throw StateError('This trip is stopped or belongs to another driver.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Enable device location.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw StateError('Location permission is required.');
    }
    await store.begin(tripId, driverEmail);
    await initialize();
    if (await BackgroundServiceConfigurator.isRunning()) return;
    final service = FlutterBackgroundService();
    final ready = Completer<Map<String, dynamic>?>();
    final readySubscription = service.on('tracking_ready').listen((event) {
      if (!ready.isCompleted) ready.complete(event);
    });
    // Attach the listener before starting the new isolate.
    try {
      await BackgroundServiceConfigurator.startService();
      final event = await ready.future.timeout(const Duration(seconds: 20));
      if (event?['error'] != null) throw StateError(event!['error'].toString());
    } catch (_) {
      await stop();
      rethrow;
    } finally {
      await readySubscription.cancel();
    }
  }

  static bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> stop() {
    return _stopping ??= _stop().whenComplete(() => _stopping = null);
  }

  static Future<void> _stop() async {
    if (!_mobile) return;
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) return;
    await initialize();
    service.invoke('stopService');
    // Native state is authoritative; a service event can be lost when an isolate exits.
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (await service.isRunning()) {
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Location service is still stopping. Retry End Trip.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<bool> isRunning() async {
    if (!_mobile) return false;
    final running = await BackgroundServiceConfigurator.isRunning();
    if (running) await initialize();
    return running;
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final store = TripLocationStore();
  StreamSubscription<Position>? gps;
  StreamSubscription<Map<String, dynamic>?>? stopSubscription;
  Future<void> writes = Future.value();
  bool stopping = false;
  Timer? liveTimer;
  Map<String, dynamic>? latest;
  int? tripId;
  double distance = 0;
  Position? previous;
  bool sending = false;

  Future<void> stop() async {
    if (stopping) return;
    stopping = true;
    liveTimer?.cancel();
    try {
      await gps?.cancel();
      await writes;
      await stopSubscription?.cancel();
      await store.close();
    } catch (error) {
      service.invoke('on_error', {
        'message': 'Tracking cleanup failed: $error',
      });
    } finally {
      service.invoke('on_tracking_stopped', {'tripId': tripId});
      await service.stopSelf();
    }
  }

  stopSubscription = service.on('stopService').listen((_) async {
    await stop();
  });
  try {
    final session = await store.active();
    final user = await StorageHelper.getUserSession();
    if (session == null ||
        user?.role != UserRole.driver ||
        session['driver_email'] != user?.email) {
      throw StateError('No active trip for the signed-in driver.');
    }
    tripId = session['trip_id'] as int;
    distance = (session['distance_km'] as num).toDouble();
    final savedPoints = await store.points(tripId);
    final last = savedPoints.isEmpty ? null : savedPoints.last;
    double? previousLat = (last?['latitude'] as num?)?.toDouble();
    double? previousLon = (last?['longitude'] as num?)?.toDouble();
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 25,
            intervalDuration: const Duration(seconds: 15),
          )
        : AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 25,
            activityType: ActivityType.automotiveNavigation,
            pauseLocationUpdatesAutomatically: true,
            allowBackgroundLocationUpdates: true,
            showBackgroundLocationIndicator: true,
          );
    if (stopping) return;
    gps = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        if (stopping || position.accuracy > 100 || position.isMocked) return;
        if (previous != null &&
            position.timestamp.difference(previous!.timestamp).inSeconds < 10) {
          return;
        }
        previous = position;
        final point = <String, dynamic>{
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speedKmh': position.speed > 0 ? position.speed * 3.6 : 0.0,
          'heading': position.heading,
          'accuracyMeters': position.accuracy,
          'recordedAt': position.timestamp
              .toUtc()
              .toIso8601String()
              .replaceFirst('Z', ''),
        };
        if (previousLat != null && previousLon != null) {
          final delta = Geolocator.distanceBetween(
            previousLat!,
            previousLon!,
            position.latitude,
            position.longitude,
          );
          if (delta >= 5 && delta < 2000) distance += delta / 1000;
        }
        previousLat = position.latitude;
        previousLon = position.longitude;
        final distanceAtPoint = distance;
        writes = writes
            .then((_) async {
              await store.append(tripId!, point, distanceAtPoint);
              latest = point;
              service.invoke('on_location_update', {
                ...point,
                'timestamp': position.timestamp.toIso8601String(),
                'accuracy': position.accuracy,
                'speed': position.speed,
                'distanceKm': distanceAtPoint,
              });
            })
            .catchError((Object error) {
              service.invoke('on_error', {
                'message': 'Local GPS save failed: $error',
              });
            });
      },
      onError: (Object error) {
        service.invoke('on_error', {'message': 'GPS unavailable: $error'});
      },
    );
    // Only one transient latest point is sent per 30s; the server never persists it.
    liveTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (sending || stopping || latest == null) return;
      sending = true;
      try {
        final currentUser = await StorageHelper.getUserSession();
        if (currentUser?.role != UserRole.driver ||
            currentUser?.email != session['driver_email']) {
          await stop();
          return;
        }
        await TransportService.publishLiveLocation(tripId!, latest!);
      } catch (_) {
        /* SQLite history remains intact while offline. */
      } finally {
        sending = false;
      }
    });
    service.invoke('tracking_ready', {'tripId': tripId});
  } catch (error) {
    service.invoke('tracking_ready', {'error': error.toString()});
    service.invoke('on_error', {'message': error.toString()});
    await stop();
  }
}

@pragma('vm:entry-point')
Future<bool> onBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  // iOS fetch cannot promise an always-running Dart GPS service.
  return true;
}
