/// Lifecycle and service events consumed by the tracking BLoC.
abstract class LocationTrackingServiceGateway {
  Future<bool> isRunning();
  Future<void> start({required int tripId, required String driverEmail});
  Future<void> stop();
  Stream<Map<String, dynamic>?> events(String name);
}
