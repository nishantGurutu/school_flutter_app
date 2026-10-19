import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// The foreground UI and background isolate share this SQLite journal.
class TripLocationStore {
  TripLocationStore({DatabaseFactory? factory, String? databasePath})
    : _factory = factory ?? databaseFactory,
      _path = databasePath;
  final DatabaseFactory _factory;
  final String? _path;
  Database? _db;

  Future<Database> get database async => _db ??= await _factory.openDatabase(
    _path ?? path.join(await getDatabasesPath(), 'driver_trip_locations.db'),
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE trips (trip_id INTEGER PRIMARY KEY, driver_email TEXT NOT NULL, state TEXT NOT NULL, distance_km REAL NOT NULL DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE points (id INTEGER PRIMARY KEY AUTOINCREMENT, trip_id INTEGER NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL, speedKmh REAL NOT NULL, heading REAL NOT NULL, accuracyMeters REAL NOT NULL, recordedAt TEXT NOT NULL, UNIQUE(trip_id, recordedAt))',
        );
        await db.execute('CREATE INDEX points_trip ON points(trip_id, id)');
      },
    ),
  );

  Future<void> begin(int tripId, String email) async {
    final db = await database;
    await db.transaction((txn) async {
      final active = await txn.query(
        'trips',
        where: "state = 'active' AND trip_id != ?",
        whereArgs: [tripId],
      );
      if (active.isNotEmpty) {
        throw StateError('Finish the current trip before starting another.');
      }
      final existing = await txn.query(
        'trips',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
      if (existing.isNotEmpty) {
        if (existing.first['driver_email'] != email ||
            existing.first['state'] != 'active') {
          throw StateError(
            'This trip is already stopped or belongs to another driver.',
          );
        }
        return;
      }
      await txn.insert('trips', {
        'trip_id': tripId,
        'driver_email': email,
        'state': 'active',
      });
    });
  }

  Future<Map<String, Object?>?> session(int tripId) async {
    final rows = await (await database).query(
      'trips',
      where: 'trip_id = ?',
      whereArgs: [tripId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, Object?>?> active() async {
    final rows = await (await database).query(
      'trips',
      where: "state = 'active'",
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, Object?>>> pending(String email) async =>
      (await database).query(
        'trips',
        where: "driver_email = ? AND state = 'pending'",
        whereArgs: [email],
        orderBy: 'trip_id',
      );

  Future<void> append(
    int tripId,
    Map<String, dynamic> point,
    double distanceKm,
  ) async {
    await (await database).transaction((txn) async {
      final session = await txn.query(
        'trips',
        where: "trip_id = ? AND state = 'active'",
        whereArgs: [tripId],
      );
      if (session.isEmpty) return;
      await txn.insert('points', {
        'trip_id': tripId,
        ...point,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.update(
        'trips',
        {'distance_km': distanceKm},
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> points(int tripId) async =>
      (await (await database).query(
        'points',
        columns: [
          'latitude',
          'longitude',
          'speedKmh',
          'heading',
          'accuracyMeters',
          'recordedAt',
        ],
        where: 'trip_id = ?',
        whereArgs: [tripId],
        orderBy: 'id',
      )).map((p) => Map<String, dynamic>.from(p)).toList();
  Future<void> stop(int tripId) async => (await database).update(
    'trips',
    {'state': 'pending'},
    where: "trip_id = ? AND state = 'active'",
    whereArgs: [tripId],
  );
  Future<void> acknowledge(int tripId) async {
    await (await database).transaction((txn) async {
      await txn.update(
        'trips',
        {'state': 'uploaded'},
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
      await txn.delete('points', where: 'trip_id = ?', whereArgs: [tripId]);
    });
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
