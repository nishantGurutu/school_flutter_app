import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_desk_app/location_tracking/data/datasources/trip_location_store.dart';
import 'package:school_desk_app/location_tracking/data/trip_completion_coordinator.dart';

void main() {
  sqfliteFfiInit();
  late TripLocationStore store;
  setUp(() async {
    store = TripLocationStore(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    await store.begin(10, 'driver@school.com');
    await store.append(10, {
      'latitude': 28.6,
      'longitude': 77.0,
      'speedKmh': 20.0,
      'heading': 0.0,
      'accuracyMeters': 5.0,
      'recordedAt': '2026-10-19T10:00:00',
    }, 1.2);
  });
  tearDown(() => store.close());

  test(
    'end waits for service stop, freezes SQLite, and only then uploads',
    () async {
      final calls = <String>[];
      final coordinator = TripCompletionCoordinator(
        store: store,
        stopTracking: () async {
          calls.add('stop');
          // Final GPS callback must be drained into SQLite before the service stops.
          await store.append(10, {
            'latitude': 28.7,
            'longitude': 77.0,
            'speedKmh': 0.0,
            'heading': 0.0,
            'accuracyMeters': 5.0,
            'recordedAt': '2026-10-19T10:01:00',
          }, 2.4);
        },
        upload: (id, body) async {
          calls.add('upload');
          expect((await store.session(id))!['state'], 'pending');
          expect(body['points'], hasLength(2));
          expect(body['totalDistanceKm'], 2.4);
          return {'tripId': id, 'status': 'COMPLETED'};
        },
      );
      await coordinator.complete(tripId: 10, driverEmail: 'driver@school.com');
      expect(calls, ['stop', 'upload']);
      expect(await store.points(10), isEmpty);
      expect((await store.session(10))!['state'], 'uploaded');
    },
  );

  test('failed upload stays stopped and retries the same points', () async {
    var stops = 0, uploads = 0;
    List<dynamic>? firstBatch;
    final coordinator = TripCompletionCoordinator(
      store: store,
      stopTracking: () async {
        stops++;
      },
      upload: (id, body) async {
        uploads++;
        if (uploads == 1) {
          firstBatch = body['points'] as List;
          throw StateError('offline');
        }
        expect(body['points'], firstBatch);
        return {'tripId': id, 'status': 'COMPLETED'};
      },
    );
    await expectLater(
      coordinator.complete(tripId: 10, driverEmail: 'driver@school.com'),
      throwsStateError,
    );
    expect((await store.session(10))!['state'], 'pending');
    expect(await store.points(10), hasLength(1));
    await coordinator.complete(tripId: 10, driverEmail: 'driver@school.com');
    expect(stops, 1);
    expect(uploads, 2);
    expect(await store.points(10), isEmpty);
  });

  test('duplicate end taps share one upload', () async {
    final release = Completer<void>();
    var stops = 0, uploads = 0;
    final coordinator = TripCompletionCoordinator(
      store: store,
      stopTracking: () async {
        stops++;
      },
      upload: (id, body) async {
        uploads++;
        await release.future;
        return {'tripId': id, 'status': 'COMPLETED'};
      },
    );
    final first = coordinator.complete(
      tripId: 10,
      driverEmail: 'driver@school.com',
    );
    final second = coordinator.complete(
      tripId: 10,
      driverEmail: 'driver@school.com',
    );
    release.complete();
    await Future.wait([first, second]);
    expect(stops, 1);
    expect(uploads, 1);
  });

  test(
    'stop failure or wrong driver must not upload or clear local points',
    () async {
      final coordinator = TripCompletionCoordinator(
        store: store,
        stopTracking: () async {
          throw StateError('service still running');
        },
        upload: (_, _) async => fail('must not upload'),
      );
      await expectLater(
        coordinator.complete(tripId: 10, driverEmail: 'other@school.com'),
        throwsStateError,
      );
      await expectLater(
        coordinator.complete(tripId: 10, driverEmail: 'driver@school.com'),
        throwsStateError,
      );
      expect((await store.session(10))!['state'], 'active');
      expect(await store.points(10), hasLength(1));
    },
  );
}
