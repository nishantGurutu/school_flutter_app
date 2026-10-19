/// Lifecycle and service events consumed by the tracking BLoC.
abstract class LocationTrackingServiceGateway {
  Future<bool> isRunning();
  Future<void> start({
    required int empId,
    required String companyCode,
    required String token,
    required String deviceId,
    required String baseUrl,
    required String uploadUrl,
  });
  Future<void> stop();
  Stream<Map<String, dynamic>?> events(String name);
}
