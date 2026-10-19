import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/location_tracking/index.dart';

class FakeTrackingService implements LocationTrackingServiceGateway {
  bool running = false;
  final calls = <String>[];
  Completer<void>? startGate;
  final channels = <String, StreamController<Map<String, dynamic>?>>{};
  @override
  Stream<Map<String, dynamic>?> events(String name) => channels
      .putIfAbsent(
        name,
        () => StreamController<Map<String, dynamic>?>.broadcast(),
      )
      .stream;
  @override
  Future<bool> isRunning() async => running;
  @override
  Future<void> start({
    required int empId,
    required String companyCode,
    required String token,
    required String deviceId,
    required String baseUrl,
    required String uploadUrl,
  }) async {
    calls.add('start');
    await startGate?.future;
    running = true;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    running = false;
  }

  Future<void> close() async {
    for (final channel in channels.values) {
      await channel.close();
    }
  }
}

const start = LocationTrackingStarted(
  empId: 1,
  companyCode: 'school',
  token: 'token',
  deviceId: 'device',
  baseUrl: 'https://example.test',
  uploadUrl: 'https://example.test/locations',
);

Future<LocationTrackingState> until(
  LocationTrackingBloc bloc,
  bool Function(LocationTrackingState) condition,
) {
  if (condition(bloc.state)) return Future.value(bloc.state);
  return bloc.stream.firstWhere(condition).timeout(const Duration(seconds: 3));
}

void main() {
  test(
    'restores service status and handles GPS, error, and service stop',
    () async {
      final service = FakeTrackingService()..running = true;
      final bloc = LocationTrackingBloc(service: service);
      await until(bloc, (s) => s.isTracking);
      service.channels['on_location_update']!.add({
        'latitude': 25.6,
        'longitude': 85.1,
        'timestamp': '2026-10-19T10:00:00.000',
      });
      final location = await until(bloc, (s) => s.lastLocation != null);
      expect(location.lastLocation!.latitude, 25.6);
      service.channels['on_error']!.add({'message': 'offline'});
      final failure = await until(bloc, (s) => s.errorMessage != null);
      expect(failure.errorMessage, 'offline');
      expect(failure.isTracking, isTrue);
      service.channels['on_tracking_stopped']!.add(null);
      final stopped = await until(
        bloc,
        (s) => s.status == LocationTrackingStatus.stopped,
      );
      expect(stopped.lastLocation, isNull);
      await bloc.close();
      expect(service.channels.values.every((c) => !c.hasListener), isTrue);
      expect(service.calls, isEmpty); // UI disposal must not stop the service.
      await service.close();
    },
  );

  test('stop waits for pending start and duplicate start is ignored', () async {
    final service = FakeTrackingService()..startGate = Completer<void>();
    final bloc = LocationTrackingBloc(service: service);
    await until(bloc, (s) => s.status == LocationTrackingStatus.stopped);
    bloc.add(start);
    await until(bloc, (s) => s.status == LocationTrackingStatus.starting);
    bloc.add(start);
    bloc.add(const LocationTrackingStopped());
    service.startGate!.complete();
    await until(bloc, (s) => s.status == LocationTrackingStatus.stopped);
    expect(service.calls, ['start', 'stop']);
    expect(service.running, isFalse);
    await bloc.close();
    await service.close();
  });
}
