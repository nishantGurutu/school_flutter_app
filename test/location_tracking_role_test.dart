import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_desk_app/location_tracking/data/datasources/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final role in ['STUDENT', 'PARENT']) {
    test('$role cannot start background location service', () async {
      FlutterSecureStorage.setMockInitialValues({
        'accessToken': 'test-token',
        'userId': '3',
        'name': 'Test user',
        'email': 'user@school.com',
        'role': role,
      });
      // No platform channels are mocked: reaching a service/GPS call would fail.
      await expectLater(
        LocationService.start(tripId: 1, driverEmail: 'user@school.com'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Only the signed-in driver'),
          ),
        ),
      );
    });
  }
  test(
    'driver cannot start tracking for a different signed-in identity',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'accessToken': 'test-token',
        'userId': '3',
        'name': 'Driver',
        'email': 'driver@school.com',
        'role': 'DRIVER',
      });
      await expectLater(
        LocationService.start(tripId: 1, driverEmail: 'other@school.com'),
        throwsStateError,
      );
    },
  );
}
