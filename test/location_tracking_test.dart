import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_desk_app/location_tracking/data/datasources/location_local_data_source.dart';
import 'package:school_desk_app/location_tracking/data/models/periodic_location_payload.dart';
import 'package:school_desk_app/location_tracking/data/repositories/location_tracking_repository_impl.dart';

PeriodicLocationPayload point(int second) =>
    PeriodicLocationPayload.fromDetails(
      latitude: 25.6,
      longitude: 85.1,
      address: '',
      batteryLevel: 70,
      deviceId: 'device',
      empId: 1,
      foreground: true,
      timestamp: DateTime(2026, 10, 19, 10, 0, second),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failed upload survives restart and retries all points in order',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final local = LocationLocalDataSource(prefs);
      var online = false;
      List<dynamic>? sent;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (!online) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.connectionError,
                ),
              );
            } else {
              sent = options.data as List<dynamic>;
              handler.resolve(
                Response(requestOptions: options, statusCode: 200),
              );
            }
          },
        ),
      );
      LocationTrackingRepositoryImpl repository(
        LocationLocalDataSource source,
      ) => LocationTrackingRepositoryImpl(
        dioClient: dio,
        localDataSource: source,
        uploadUrl: 'https://example.test/locations',
      );
      Future<void> upload(LocationTrackingRepositoryImpl repo, int second) =>
          repo.uploadLocation(
            empId: 1,
            companyCode: 'school',
            token: 'token',
            payload: point(second),
          );
      await expectLater(
        upload(repository(local), 1),
        throwsA(isA<DioException>()),
      );
      final restored = LocationLocalDataSource(prefs);
      expect(restored.getQueue(), hasLength(1));
      online = true;
      await upload(repository(restored), 2);
      expect(sent, hasLength(2));
      expect(sent!.map((p) => p['time']), ['10:00:01', '10:00:02']);
      expect(restored.getQueue(), isEmpty);
    },
  );

  test('queues from different users stay separate', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = LocationLocalDataSource(prefs, queueKey: 'user1');
    final second = LocationLocalDataSource(prefs, queueKey: 'user2');
    await first.enqueue(point(1));
    expect(first.getQueue(), hasLength(1));
    expect(second.getQueue(), isEmpty);
  });
}
