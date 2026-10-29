import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network_token_refresh_test.dart' show FakeAdapter, body;
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/services/runtime_environment.dart';
import 'package:school_desk_app/utils/app_url.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  final original = RuntimeEnvironment.baseUrl;
  tearDown(() {
    RuntimeEnvironment.baseUrl = original;
  });
  test('all computed endpoints follow a changed environment', () {
    RuntimeEnvironment.baseUrl = 'http://192.168.1.5:8080/api';
    expect(AppUrl.login, 'http://192.168.1.5:8080/api/auth/login');
    expect(AppUrl.transportBase, 'http://192.168.1.5:8080/api/v1/transport');
    RuntimeEnvironment.baseUrl = 'https://live.example/api';
    expect(AppUrl.login, 'https://live.example/api/auth/login');
    expect(AppUrl.homework, 'https://live.example/api/mobile/homework');
  });
  test('previously captured API endpoints use current server', () {
    final captured = AppUrl.login;
    RuntimeEnvironment.baseUrl = 'https://live.example/api';
    expect(
      RuntimeEnvironment.resolve(captured),
      'https://live.example/api/auth/login',
    );
  });
  test('external URLs and similar hostname prefixes are unchanged', () {
    RuntimeEnvironment.baseUrl = 'https://live.example/api';
    expect(
      RuntimeEnvironment.resolve('https://files.example/note.pdf'),
      'https://files.example/note.pdf',
    );
    expect(
      RuntimeEnvironment.resolve('$original-elsewhere/auth/login'),
      '$original-elsewhere/auth/login',
    );
  });
  test(
    'DB development remaps captured Render login; outage retains it; explicit live update switches it',
    () async {
      var active = 'http://10.103.180.61:8080/api';
      final client = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(
            options.uri.toString(),
            '${RuntimeEnvironment.configBaseUrl}/runtime-config',
          );
          return body(200, {'environment': 'development', 'activeUrl': active});
        });
      const capturedLogin =
          'https://school-springboot-backend.onrender.com/api/auth/login';
      await RuntimeEnvironment.refresh(force: true, client: client);
      expect(AppUrl.login, '$active/auth/login');
      expect(RuntimeEnvironment.resolve(capturedLogin), '$active/auth/login');
      client.httpClientAdapter = FakeAdapter(
        (_) => throw StateError('offline'),
      );
      await RuntimeEnvironment.refresh(force: true, client: client);
      expect(RuntimeEnvironment.resolve(capturedLogin), '$active/auth/login');
      active = 'https://live.example/api';
      client.httpClientAdapter = FakeAdapter(
        (_) => body(200, {'environment': 'live', 'activeUrl': active}),
      );
      await RuntimeEnvironment.refresh(force: true, client: client);
      expect(RuntimeEnvironment.resolve(capturedLogin), '$active/auth/login');
    },
  );
}
