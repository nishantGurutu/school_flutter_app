import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_desk_app/services/transport_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:school_desk_app/services/driver_location_gate.dart';
import 'support/fake_driver_location.dart';

void main() {
  late GeolocatorPlatform original;
  late FakeDriverLocation location;
  setUp(() {
    original = GeolocatorPlatform.instance;
    location = FakeDriverLocation();
    GeolocatorPlatform.instance = location;
  });
  tearDown(() async {
    GeolocatorPlatform.instance = original;
    await location.statuses.close();
  });

  test('both device GPS and permission are required', () async {
    expect(await DriverLocationGate.isReady(), isTrue);
    location.gps = false;
    expect(await DriverLocationGate.isReady(), isFalse);
    await expectLater(DriverLocationGate.requireReady(), throwsStateError);
    location.gps = true;
    for (final denied in [
      LocationPermission.denied,
      LocationPermission.deniedForever,
      LocationPermission.unableToDetermine,
    ]) {
      location.permission = denied;
      expect(await DriverLocationGate.isReady(), isFalse);
      await expectLater(DriverLocationGate.requireReady(), throwsStateError);
    }
  });

  test(
    'trip service blocks start and end before API or local trip changes',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'role': 'DRIVER',
        'email': 'driver@school.com',
        'accessToken': 'token',
      });
      location.gps = false;
      expect(await TransportService.startTrip(routeId: 4, busId: 3), isNull);
      await expectLater(TransportService.endTrip(tripId: 10), throwsStateError);
      location.gps = true;
      location.permission = LocationPermission.deniedForever;
      expect(await TransportService.startTrip(routeId: 4, busId: 3), isNull);
      await expectLater(TransportService.endTrip(tripId: 10), throwsStateError);
    },
  );

  testWidgets(
    'settings sheet blocks action until GPS and permission are both enabled',
    (tester) async {
      location.gps = false;
      location.permission = LocationPermission.deniedForever;
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  completed = await DriverLocationGate.ensureReady(context);
                },
                child: const Text('Trip action'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Trip action'));
      await tester.pumpAndSettle();
      expect(find.text('Location required'), findsOneWidget);
      expect(completed, isFalse);
      await tester.tap(find.text('Open GPS / Location Settings'));
      await tester.pumpAndSettle();
      expect(location.gpsSettingsOpened, 1);
      await tester.tap(find.text('Open App Permission Settings'));
      await tester.pumpAndSettle();
      expect(location.appSettingsOpened, 1);
      location.permission = LocationPermission.always;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Location required'), findsOneWidget);
      expect(completed, isFalse);
      location.gps = true;
      location.statuses.add(ServiceStatus.enabled);
      await tester.pumpAndSettle();
      expect(find.text('Location required'), findsNothing);
      expect(completed, isTrue);
    },
  );

  testWidgets(
    'denying permission keeps action blocked and cancel does not proceed',
    (tester) async {
      location.permission = LocationPermission.denied;
      bool? allowed;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  allowed = await DriverLocationGate.ensureReady(context);
                },
                child: const Text('End Trip'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('End Trip'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allow location permission'));
      await tester.pumpAndSettle();
      expect(find.text('Location required'), findsOneWidget);
      expect(allowed, isNull);
      await tester.tap(find.text('Cancel trip action'));
      await tester.pumpAndSettle();
      expect(allowed, isFalse);
    },
  );
}
