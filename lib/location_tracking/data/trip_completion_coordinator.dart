import 'datasources/trip_location_store.dart';

/// Freeze and upload exactly the saved trip; keep failed uploads retryable.
class TripCompletionCoordinator {
  TripCompletionCoordinator({
    required this.store,
    required this.stopTracking,
    required this.upload,
  });
  final TripLocationStore store;
  final Future<void> Function() stopTracking;
  final Future<Map<String, dynamic>?> Function(int, Map<String, dynamic>)
  upload;
  final Map<int, Future<Map<String, dynamic>>> _inFlight = {};

  Future<Map<String, dynamic>> complete({
    required int tripId,
    required String driverEmail,
    double? distanceKm,
    String? notes,
  }) {
    return _inFlight.putIfAbsent(
      tripId,
      () => _complete(tripId, driverEmail, distanceKm, notes).whenComplete(() {
        _inFlight.remove(tripId);
      }),
    );
  }

  Future<Map<String, dynamic>> _complete(
    int tripId,
    String email,
    double? distance,
    String? notes,
  ) async {
    if (tripId <= 0 || email.trim().isEmpty) {
      throw ArgumentError('A valid driver trip is required.');
    }
    var session = await store.session(tripId);
    if (session == null) {
      await store.begin(tripId, email);
      session = await store.session(tripId);
    }
    if (session?['driver_email'] != email) {
      throw StateError('This trip belongs to another driver.');
    }
    if (session?['state'] == 'active') {
      await stopTracking();
      await store.stop(tripId);
    }
    final frozen = await store.session(tripId);
    final points = await store.points(tripId);
    final result = await upload(tripId, {
      'points': points,
      'totalDistanceKm': frozen?['distance_km'] ?? distance ?? 0,
      'endLatitude': points.isEmpty ? null : points.last['latitude'],
      'endLongitude': points.isEmpty ? null : points.last['longitude'],
      'notes': notes ?? 'Driver completed trip',
    });
    if (result?['tripId'] != tripId || result?['status'] != 'COMPLETED') {
      throw StateError(
        'Trip completion was not confirmed. Local GPS points retained.',
      );
    }
    await store.acknowledge(tripId);
    return result!;
  }
}
