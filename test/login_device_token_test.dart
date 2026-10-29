import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/data/repositories/api_auth_repository.dart';
import 'package:school_desk_app/firebase/notification_firebase.dart';

class LoginApi extends NetworkApiService {
  Map<String, dynamic>? payload;
  @override
  Future<dynamic> postApi(String url, dynamic data) async {
    payload = Map<String, dynamic>.from(data as Map);
    return {
      'accessToken': 'access',
      'refreshToken': 'refresh',
      'userId': 1,
      'email': 'user@test.local',
      'role': 'ADMIN',
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() {
    deviceTokenToSendPushNotification = '';
    debugDefaultTargetPlatformOverride = null;
  });
  test('Firebase device token is included in login request', () async {
    deviceTokenToSendPushNotification = 'fcm-login-device-token-123456789';
    final api = LoginApi();
    await ApiAuthRepository(
      apiService: api,
    ).login(' user@test.local ', 'secret');
    expect(api.payload, {
      'email': 'user@test.local',
      'password': 'secret',
      'deviceToken': deviceTokenToSendPushNotification,
    });
  });
  test('login without Firebase token remains supported', () async {
    final api = LoginApi();
    await ApiAuthRepository(apiService: api).login('user@test.local', 'secret');
    expect(api.payload!.containsKey('deviceToken'), isFalse);
  });
}
