import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests runtime permissions used by Chat App across platforms.
class AppPermissions {
  static Future<void> requestStartupPermissions() async {
    if (kIsWeb) return;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await _requestAndroid();
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        await _requestApple();
      case TargetPlatform.windows:
        // Windows notification permission is handled by the OS /
        // flutter_local_notifications on first toast.
        break;
      default:
        break;
    }
  }

  static Future<void> _requestAndroid() async {
    final permissions = <Permission>[
      Permission.location,
      Permission.notification,
      Permission.camera,
    ];

    await permissions.request();

    // Background location must be requested after foreground location is granted on Android 10+
    final locationStatus = await Permission.location.status;
    if (locationStatus.isGranted || locationStatus.isLimited) {
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }
    }

    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  static Future<void> _requestApple() async {
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.notification,
      Permission.camera,
    ];

    await permissions.request();

    if (await Permission.locationWhenInUse.isGranted) {
      if (await Permission.locationAlways.isDenied) {
        await Permission.locationAlways.request();
      }
    }
  }

  static Future<bool> ensureLocation() async {
    var status = await Permission.location.status;
    if (!status.isGranted && !status.isLimited) {
      status = await Permission.location.request();
    }
    return status.isGranted || status.isLimited;
  }

  static Future<bool> ensureCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> ensurePhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  static Future<bool> ensureMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> ensureNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
