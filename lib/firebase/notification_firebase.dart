import '../data/network/network_api_services.dart';
import '../services/storage/local_storage.dart';
import '../utils/app_url.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_services.dart';

String deviceTokenToSendPushNotification = '';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handles incoming background notifications
}

Future<void> firebaseNotification([BuildContext? context]) async {
  await LocalNotificationService.initialize();

  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.instance.getInitialMessage().then((_) {});

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (message.notification == null && message.data.isNotEmpty) {
        LocalNotificationService.createAndDisplayNotification(message);
      }
    } else {
      if (message.notification != null || message.data.isNotEmpty) {
        LocalNotificationService.createAndDisplayNotification(message);
      }
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((_) {});

  messaging.onTokenRefresh.listen((newToken) async {
    deviceTokenToSendPushNotification = newToken;
    await syncPushDeviceToken();
  });

  String? token;
  for (int attempt = 0; attempt < 5; attempt++) {
    try {
      token = await messaging.getToken();
      if (token != null && token.isNotEmpty) break;
    } catch (e) {
      debugPrint("FCM getToken attempt $attempt error: $e");
    }
    await Future.delayed(const Duration(seconds: 1));
  }

  if (token != null) {
    deviceTokenToSendPushNotification = token;
    await syncPushDeviceToken();
  }
}

/// Handles FCM rotation and tokens that become available after login.
Future<void> syncPushDeviceToken() async {
  if (deviceTokenToSendPushNotification.isEmpty) return;
  final accessToken = await StorageHelper.getAccessToken();
  if (accessToken == null || accessToken.isEmpty) return;
  try {
    await NetworkApiService().postApi('${AppUrl.baseUrl}/mobile/push-devices', {
      'token': deviceTokenToSendPushNotification,
    });
  } catch (_) {
    debugPrint(
      'Push device registration unavailable; token will be sent on next login/start.',
    );
  }
}
