import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:school_desk_app/analytics/posthog_analytics_service.dart';
import 'package:school_desk_app/analytics/posthog_feature.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool get _supportsFirebaseMessaging {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static String? pendingPayload;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const darwinInitializationSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
      macOS: darwinInitializationSettings,
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'pushnotificationapp',
        'Push Notification App',
        description: 'This channel is for push notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(channel);
      await androidPlugin?.requestNotificationsPermission();
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (_supportsFirebaseMessaging) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    _initialized = true;
  }

  static Future<void> createAndDisplayNotification(
    RemoteMessage message,
  ) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final title =
          message.notification?.title ??
          message.data['title'] ??
          message.data['heading'] ??
          'Notification';
      final body =
          message.notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          '';

      const androidDetails = AndroidNotificationDetails(
        'pushnotificationapp',
        'Push Notification App',
        channelDescription: 'This channel is for push notifications',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e, stackTrace) {
      unawaited(
        posthogAnalytics.captureException(
          e,
          stackTrace: stackTrace,
          feature: PosthogFeature.notifications,
          action: 'display_notification',
        ),
      );
    }
  }

  /// Show a local notification (works on Windows without FCM).
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const androidDetails = AndroidNotificationDetails(
        'pushnotificationapp',
        'Push Notification App',
        channelDescription: 'This channel is for push notifications',
        importance: Importance.max,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: data == null ? null : jsonEncode(data),
      );
    } catch (_) {}
  }

  static void checkPendingNotification() {
    if (pendingPayload != null) {
      pendingPayload = null;
    }
  }
}
