import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_service_configurator.dart';
import 'background_service_locator.dart';

/// Facade for location tracking background operations.
///
/// Delegates all work to focused sub-services:
/// - [BackgroundServiceConfigurator] for service lifecycle
/// - [LocationTracker] for GPS stream management
/// - [LocationUploadScheduler] for periodic upload loop
class LocationService {
  static const String _prefsEmpIdKey = 'location_tracking_emp_id';
  static const String _prefsCompanyCodeKey = 'location_tracking_company_code';
  static const String _prefsTokenKey = 'location_tracking_token';
  static const String _prefsDeviceIdKey = 'location_tracking_device_id';
  static const String _prefsBaseUrlKey = 'location_tracking_base_url';
  static const String _prefsUploadUrlKey = 'location_tracking_upload_url';
  static const String _prefsUserStoppedDateKey =
      'location_tracking_user_stopped_date';

  static Future<void> initialize() async {
    await BackgroundServiceConfigurator.initialize(
      onStart: onStart,
      onBackground: onBackground,
    );
  }

  static Future<void> start({
    required int empId,
    required String companyCode,
    required String token,
    required String deviceId,
    required String baseUrl,
    required String uploadUrl,
  }) async {
    if (empId <= 0 ||
        companyCode.trim().isEmpty ||
        token.trim().isEmpty ||
        deviceId.trim().isEmpty) {
      throw ArgumentError(
        'A valid user, company, token and device are required.',
      );
    }
    for (final url in [baseUrl, uploadUrl]) {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !uri.hasAuthority ||
          !['http', 'https'].contains(uri.scheme)) {
        throw ArgumentError('Location API URLs must be absolute HTTP(S) URLs.');
      }
    }
    if (await isRunning()) {
      throw StateError(
        'Stop the current tracking session before starting another.',
      );
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Enable device location services before tracking.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw StateError('Location permission is required to start tracking.');
    }
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsEmpIdKey, empId);
    await prefs.setString(_prefsCompanyCodeKey, companyCode);
    await prefs.setString(_prefsTokenKey, token);
    await prefs.setString(_prefsDeviceIdKey, deviceId);
    await prefs.setString(_prefsBaseUrlKey, baseUrl);
    await prefs.setString(_prefsUploadUrlKey, uploadUrl);
    await prefs.remove(_prefsUserStoppedDateKey);

    await BackgroundServiceConfigurator.startService();
  }

  static Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    await prefs.setString(_prefsUserStoppedDateKey, todayStr);
    await BackgroundServiceConfigurator.stopService();
  }

  static Future<bool> isRunning() async {
    return BackgroundServiceConfigurator.isRunning();
  }

  static Future<bool> wasExplicitlyStopped() async {
    final prefs = await SharedPreferences.getInstance();
    final stoppedDate = prefs.getString(_prefsUserStoppedDateKey);
    if (stoppedDate == null) return false;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    return stoppedDate == todayStr;
  }
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Location tracking active",
      content: "Sharing location for your active trip.",
    );
  }

  try {
    final locator = BackgroundServiceLocator();
    await locator.init();

    final scheduler = locator.createScheduler(service);

    scheduler.start(
      empId: locator.empId,
      companyCode: locator.companyCode,
      token: locator.token,
      deviceId: locator.deviceId,
      getAddress: (double lat, double lng) async => '',
      getBatteryLevel: _getBatteryLevel,
    );
  } catch (error) {
    service.invoke('on_error', {
      'message': 'Location service failed to initialize: $error',
    });
    service.invoke('on_tracking_stopped');
    await service.stopSelf();
  }
}

Future<int> _getBatteryLevel() async {
  try {
    return await Battery().batteryLevel;
  } catch (_) {
    return -1; // Unknown; do not report a fabricated full battery.
  }
}

@pragma('vm:entry-point')
void onForeground(ServiceInstance service) {
  // iOS foreground handler – no-op because onStart handles both.
}

@pragma('vm:entry-point')
Future<bool> onBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  // iOS fetch callbacks are bounded; they cannot run a continuous GPS service.
  return true;
}
