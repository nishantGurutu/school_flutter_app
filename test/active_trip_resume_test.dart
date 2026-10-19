import 'package:geolocator/geolocator.dart';
import 'support/fake_driver_location.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:school_desk_app/location_tracking/index.dart';
import 'package:school_desk_app/location_tracking/presentation/trip_navigation_data.dart';
import 'package:school_desk_app/view/screens/modules/transport/active_trip_screen.dart';
import 'location_tracking_bloc_test.dart' show FakeTrackingService;

class FakeMaps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox(key: Key('trip-native-map'));
}

void main() {
  late GeolocatorPlatform originalLocation;
  late FakeDriverLocation location;
  setUp(() {
    originalLocation = GeolocatorPlatform.instance;
    location = FakeDriverLocation();
    GeolocatorPlatform.instance = location;
  });
  tearDown(() async {
    GeolocatorPlatform.instance = originalLocation;
    await location.statuses.close();
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory temporary;
  late GoogleMapsFlutterPlatform original;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('resume_trip_test');
    databaseFactory = databaseFactoryFfi;
    await databaseFactory.setDatabasesPath(temporary.path);
    original = GoogleMapsFlutterPlatform.instance;
    GoogleMapsFlutterPlatform.instance = FakeMaps();
    FlutterSecureStorage.setMockInitialValues({
      'accessToken': 'token',
      'email': 'driver@school.com',
      'role': 'DRIVER',
    });
  });
  tearDown(() async {
    await LocationService.store.close();
    GoogleMapsFlutterPlatform.instance = original;
    await temporary.delete(recursive: true);
  });

  test(
    'resume arguments normalize string IDs, nested active trip, and invalid coordinates',
    () {
      final navigation = TripNavigationData({
        'trip': {'tripId': '10'},
        'duty': {
          'activeTrip': {'actualStartTime': '2026-10-19T10:00:00'},
          'route': {
            'stops': [
              null,
              {'stopOrder': '2', 'latitude': '28.6', 'longitude': '77.0'},
              {'stopOrder': '1'},
            ],
          },
        },
      });
      expect(navigation.tripId, 10);
      expect(navigation.stops.first['stopOrder'], '1');
      expect(navigation.startedAt, DateTime(2026, 10, 19, 10));
      expect(TripNavigationData.coordinate('NaN', '77'), isNull);
      expect(TripNavigationData.coordinate(100, 77), isNull);
    },
  );

  testWidgets(
    'resume renders saved trip map, and leaving UI keeps service running',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeTrackingService()..running = true;
      final bloc = LocationTrackingBloc(service: service);
      await tester.runAsync(
        () => LocationService.store.begin(10, 'driver@school.com'),
      );
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => BlocProvider.value(
            value: bloc,
            child: const MaterialApp(
              home: ActiveTripScreen(
                initialData: {
                  'trip': {'tripId': '10'},
                  'duty': {
                    'busNumber': 'Bus 7',
                    'routeName': 'Assigned Route',
                    'route': {'stops': []},
                  },
                },
              ),
            ),
          ),
        ),
      );
      for (
        var attempt = 0;
        attempt < 20 &&
            find.byKey(const Key('trip-native-map')).evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
      }
      expect(find.text('Active Trip Tracking'), findsOneWidget);
      expect(find.textContaining('Route Stops Sequence'), findsNothing);
      expect(find.text('Arrived'), findsNothing);
      expect(find.text('Depart'), findsNothing);
      expect(find.byKey(const Key('trip-native-map')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('End Trip'));
      await tester.pump();
      expect(find.text('Complete Transport Trip?'), findsOneWidget);
      await tester.tap(find.text('Resume Trip'));
      await tester.pumpAndSettle();
      expect(service.calls, isEmpty);
      await tester.pumpWidget(const SizedBox());
      expect(service.running, isTrue);
      expect(service.calls, isEmpty);
      await tester.runAsync(() async {
        await bloc.close();
        await service.close();
        await LocationService.store.close();
      });
    },
  );

  testWidgets('invalid resume shows recoverable error instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => const MaterialApp(
          home: ActiveTripScreen(initialData: {'trip': 'invalid'}),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
