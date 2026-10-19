import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_desk_app/location_tracking/data/datasources/trip_location_store.dart';

Map<String, dynamic> point(int second) => {
  'latitude': 25.6,
  'longitude': 85.1,
  'speedKmh': 20.0,
  'heading': 90.0,
  'accuracyMeters': 5.0,
  'recordedAt': '2026-10-19T10:00:${second.toString().padLeft(2, '0')}',
};

void main() {
  sqfliteFfiInit();
  late Directory folder;
  late TripLocationStore store;
  late String databasePath;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('trip_sqlite_test');
    databasePath = '${folder.path}/trips.db';
    store = TripLocationStore(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });
  tearDown(() async {
    await store.close();
    await folder.delete(recursive: true);
  });

  test('trip points survive a process reopen and a failed completion', () async {
    await store.begin(1, 'driver@school.com');
    await store.append(1, point(1), 0.2);
    await store.append(1, point(2), 0.4);
    await store.close();
    store = TripLocationStore(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    expect(await store.points(1), hasLength(2));
    expect((await store.session(1))!['distance_km'], 0.4);
    await store.stop(1);
    await store.append(
      1,
      point(3),
      0.6,
    ); // A late background callback cannot change the frozen batch.
    expect(await store.points(1), hasLength(2));
    expect((await store.session(1))!['state'], 'pending');
    // No acknowledgement on HTTP failure: same batch remains available for retry.
    await store.close();
    store = TripLocationStore(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    expect(await store.points(1), hasLength(2));
    await store.acknowledge(1);
    expect(await store.points(1), isEmpty);
    expect((await store.session(1))!['state'], 'uploaded');
  });

  test(
    'trip isolation, duplicate fixes and resume preserve the journal',
    () async {
      await store.begin(1, 'driver@school.com');
      await store.append(1, point(1), 0);
      await store.append(1, point(1), 0);
      await store.begin(1, 'driver@school.com');
      expect(await store.points(1), hasLength(1));
      await expectLater(store.begin(1, 'other@school.com'), throwsStateError);
      await expectLater(store.begin(2, 'driver@school.com'), throwsStateError);
      await store.stop(1);
      await store.begin(2, 'driver@school.com');
      expect(await store.points(2), isEmpty);
      expect(await store.points(1), hasLength(1));
    },
  );
}
