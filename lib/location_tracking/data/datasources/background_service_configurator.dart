import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Configures the background service and notification channels.
///
/// Single Responsibility: only handles service initialization configuration.
class BackgroundServiceConfigurator {
  static const String _channelId = 'school_location_service';
  static const String _channelName = 'Trip location tracking';
  static const String _channelDescription =
      'Location updates for your active school trip.';
  static const String _notificationTitle = 'Location tracking active';
  static const String _notificationContent =
      'Sharing location for your active trip.';

  static Future<void> initialize({
    required Function(ServiceInstance) onStart,
    required Future<bool> Function(ServiceInstance) onBackground,
  }) async {
    final service = FlutterBackgroundService();
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    if (!kIsWeb) {
      await flutterLocalNotificationsPlugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.low,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: _notificationTitle,
        initialNotificationContent: _notificationContent,
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onBackground,
      ),
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      if (!await service.startService()) {
        throw StateError('Unable to start location tracking service.');
      }
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return service.isRunning();
  }
}
