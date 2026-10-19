import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/utils/app_url.dart';
import 'package:school_desk_app/services/storage/local_storage.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, Map<String, dynamic> data) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'accessToken': 'old-token',
      'refreshToken': 'refresh-token',
      'role': 'DRIVER',
    }),
  );

  for (final accepts401 in [true, false]) {
    test(
      'expired start-trip token refreshes and returns without hanging (response401=$accepts401)',
      () async {
        var requests = 0;
        var refreshes = 0;
        final dio = Dio(
          BaseOptions(
            validateStatus: (s) => s == 200 || (accepts401 && s == 401),
          ),
        );
        dio.httpClientAdapter = FakeAdapter((options) {
          requests++;
          expect(options.uri.queryParameters.containsKey('email'), isFalse);
          expect(options.data, {'routeId': 1, 'busId': 7});
          return options.headers['Authorization'] == 'Bearer new-token'
              ? body(200, {'tripId': 10, 'status': 'IN_PROGRESS'})
              : body(401, {'message': 'Driver authentication required'});
        });
        final refresh = Dio()
          ..httpClientAdapter = FakeAdapter((options) {
            refreshes++;
            return body(200, {
              'accessToken': 'new-token',
              'refreshToken': 'next-refresh',
            });
          });
        final api = NetworkApiService(dio: dio, refreshDio: refresh);
        final result = await api
            .postApi(AppUrl.transportStartTrip(), {'routeId': 1, 'busId': 7})
            .timeout(const Duration(seconds: 3));
        expect(result['status'], 'IN_PROGRESS');
        expect(requests, 2);
        expect(refreshes, 1);
      },
    );
  }

  test('a repeated 401 stops after one refresh and one retry', () async {
    var requests = 0, refreshes = 0;
    final dio = Dio(BaseOptions(validateStatus: (_) => true))
      ..httpClientAdapter = FakeAdapter((_) {
        requests++;
        return body(401, {'message': 'Not authorized'});
      });
    final refresh = Dio()
      ..httpClientAdapter = FakeAdapter((_) {
        refreshes++;
        return body(200, {'accessToken': 'new-token'});
      });
    final api = NetworkApiService(dio: dio, refreshDio: refresh);
    await expectLater(
      api
          .postApi(AppUrl.transportStartTrip(), {})
          .timeout(const Duration(seconds: 3)),
      throwsException,
    );
    expect(requests, 2);
    expect(refreshes, 1);
  });

  test('concurrent expired requests share a single refresh', () async {
    var refreshes = 0;
    final started = Completer<void>(), release = Completer<void>();
    final dio = Dio(BaseOptions(validateStatus: (_) => true))
      ..httpClientAdapter = FakeAdapter(
        (options) => options.headers['Authorization'] == 'Bearer new-token'
            ? body(200, {'success': true})
            : body(401, {}),
      );
    final refresh = Dio()
      ..httpClientAdapter = FakeAdapter((_) async {
        refreshes++;
        started.complete();
        await release.future;
        return body(200, {'accessToken': 'new-token'});
      });
    final api = NetworkApiService(dio: dio, refreshDio: refresh);
    final results = Future.wait([
      api.getApi('https://example.test/a'),
      api.getApi('https://example.test/b'),
    ]);
    await started.future;
    release.complete();
    expect(await results.timeout(const Duration(seconds: 3)), hasLength(2));
    expect(refreshes, 1);
  });

  test('offline refresh preserves stored driver credentials', () async {
    final dio = Dio(BaseOptions(validateStatus: (_) => true))
      ..httpClientAdapter = FakeAdapter((_) => body(401, {}));
    final refresh = Dio()
      ..httpClientAdapter = FakeAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
    final api = NetworkApiService(dio: dio, refreshDio: refresh);
    await expectLater(
      api.getApi('https://example.test/a').timeout(const Duration(seconds: 3)),
      throwsException,
    );
    expect(await StorageHelper.getAccessToken(), 'old-token');
    expect(await StorageHelper.getRefreshToken(), 'refresh-token');
  });
}
