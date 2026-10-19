import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../data/network/network_api_services.dart';
import '../utils/app_url.dart';

/// Public Firebase app values are build configuration; service account secrets stay on the server.
class PushNotifications {
  static final instance = PushNotifications._();
  PushNotifications._();
  static const _key = String.fromEnvironment('FIREBASE_API_KEY');
  static const _app = String.fromEnvironment('FIREBASE_APP_ID');
  static const _sender = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _project = String.fromEnvironment('FIREBASE_PROJECT_ID');
  bool _ready = false, _signedIn = false;
  String? _token;
  StreamSubscription<String>? _refresh;
  final NetworkApiService _api = NetworkApiService();
  final StreamController<RemoteMessage> _messages =
      StreamController.broadcast();
  Stream<RemoteMessage> get messages => _messages.stream;
  String? lastError;
  Future<void> initialize() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        [_key, _app, _sender, _project].any((v) => v.isEmpty))
      return;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: _key,
          appId: _app,
          messagingSenderId: _sender,
          projectId: _project,
        ),
      );
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      FirebaseMessaging.onMessage.listen(_messages.add);
      FirebaseMessaging.onMessageOpenedApp.listen(_messages.add);
      _ready = true;
    } catch (e) {
      lastError = 'Push initialization failed';
    }
  }

  Future<void> signedIn() async {
    _signedIn = true;
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      await _register(await FirebaseMessaging.instance.getToken());
      await _refresh?.cancel();
      _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        unawaited(_register(token));
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _messages.add(initial);
    } catch (e) {
      lastError = 'Notifications are available in the inbox; phone push registration needs a retry.';
    }
  }

  Future<void> _register(String? token) async {
    if (!_signedIn || token == null) return;
    try {
      await _api.postApi('${AppUrl.baseUrl}/mobile/push-devices', {
        'token': token,
      });
      _token = token;
      lastError = null;
    } catch (e) {
      lastError = 'Phone push registration failed';
    }
  }

  Future<void> signedOut() async {
    _signedIn = false;
    await _refresh?.cancel();
    _refresh = null;
    if (!_ready) return;
    try {
      if (_token != null)
        await _api.postApi('${AppUrl.baseUrl}/mobile/push-devices/remove', {
          'token': _token,
        });
    } catch (e) {
      lastError = 'Device unregister deferred';
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
    } catch (e) {
      lastError = 'Phone push unregister failed';
    }
    _token = null;
  }
}
