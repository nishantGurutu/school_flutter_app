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

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

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

  messaging.onTokenRefresh.listen((newToken) {
    deviceTokenToSendPushNotification = newToken;
    debugPrint("Firebase Device Token (Refreshed): $deviceTokenToSendPushNotification");
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
    debugPrint("==================================================");
    debugPrint("🔥 Firebase Device Token: $deviceTokenToSendPushNotification");
    debugPrint("==================================================");
  }
}
