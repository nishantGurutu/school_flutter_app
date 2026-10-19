import 'package:flutter_background_service/flutter_background_service.dart';
import '../../domain/repositories/location_tracking_service.dart';
import 'location_service.dart';

class BackgroundLocationTrackingGateway
    implements LocationTrackingServiceGateway {
  @override
  Future<bool> isRunning() => LocationService.isRunning();

  @override
  Future<void> start({required int tripId, required String driverEmail}) =>
      LocationService.start(tripId: tripId, driverEmail: driverEmail);

  @override
  Future<void> stop() => LocationService.stop();

  @override
  Stream<Map<String, dynamic>?> events(String name) =>
      FlutterBackgroundService().on(name);
}
