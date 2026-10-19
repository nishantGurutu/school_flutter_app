import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../location_tracking/data/datasources/location_service.dart';

class LocationTrackingService {
  static final _instance = LocationTrackingService._();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._();

  Stream<Map<String, dynamic>> get locationStream => FlutterBackgroundService()
      .on('on_location_update')
      .where((event) => event != null)
      .map((event) => event!);

  Future<bool> checkAndRequestPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    if (!await checkAndRequestPermissions()) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> stopTracking() => LocationService.stop();
}
