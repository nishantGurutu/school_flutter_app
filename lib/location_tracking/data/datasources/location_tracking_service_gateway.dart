import 'package:flutter_background_service/flutter_background_service.dart';
import '../../domain/repositories/location_tracking_service.dart';
import 'location_service.dart';

class BackgroundLocationTrackingGateway
    implements LocationTrackingServiceGateway {
  @override
  Future<bool> isRunning() => LocationService.isRunning();

  @override
  Future<void> start({
    required int empId,
    required String companyCode,
    required String token,
    required String deviceId,
    required String baseUrl,
    required String uploadUrl,
  }) => LocationService.start(
    empId: empId,
    companyCode: companyCode,
    token: token,
    deviceId: deviceId,
    baseUrl: baseUrl,
    uploadUrl: uploadUrl,
  );

  @override
  Future<void> stop() => LocationService.stop();

  @override
  Stream<Map<String, dynamic>?> events(String name) =>
      FlutterBackgroundService().on(name);
}
