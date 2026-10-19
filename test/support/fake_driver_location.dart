import 'dart:async';
import 'package:geolocator/geolocator.dart';

class FakeDriverLocation extends GeolocatorPlatform {
  bool gps = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requestResult = LocationPermission.denied;
  int appSettingsOpened = 0;
  int gpsSettingsOpened = 0;
  final statuses = StreamController<ServiceStatus>.broadcast();
  @override
  Future<bool> isLocationServiceEnabled() async => gps;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async =>
      permission = requestResult;
  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    gpsSettingsOpened++;
    return true;
  }

  @override
  Stream<ServiceStatus> getServiceStatusStream() => statuses.stream;
}
