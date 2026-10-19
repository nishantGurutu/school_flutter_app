import 'package:geolocator/geolocator.dart';
import 'support/fake_driver_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/user_model.dart';
import 'package:school_desk_app/model/chat_item_model.dart';
import 'package:school_desk_app/view/screens/dashboard/driver_dashboard.dart';
import 'package:school_desk_app/view/widget/chat_tile.dart';
import 'package:school_desk_app/view/widgets/glass_card.dart';

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
  testWidgets(
    'GlassCard with CheckboxListTile renders without assertion failure',
    (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: GlassCard(
                child: CheckboxListTile(
                  value: true,
                  onChanged: (v) {},
                  title: const Text('Test'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Test'), findsOneWidget);
    },
  );

  testWidgets('ChatTile renders without assertion failure', (tester) async {
    final chat = ChatItem(
      name: 'John Doe',
      message: 'Hello driver',
      timeLabel: '10:00 AM',
      unreadCount: 0,
      isVerified: true,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: ChatTile(chat: chat, badgeColor: Colors.blue),
          ),
        ),
      ),
    );
    expect(find.text('John Doe'), findsOneWidget);
  });

  testWidgets('DriverDashboard renders and is smoothly scrollable', (
    tester,
  ) async {
    final user = UserModel(
      id: '1',
      name: 'Ramesh Kumar',
      email: 'driver@school.com',
      role: UserRole.driver,
      avatarUrl: '',
      details: 'Route 1 Bus Driver',
      token: 'fake-token',
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          home: DriverDashboard(
            user: user,
            onOpenDrawer: () {},
            initialDuty: {
              'busNumber': 'Bus 04',
              'registrationNumber': 'MH-02-EF-4004',
              'routeName': 'Route 1 - North Campus Loop',
              'plannedDepartureTime': '07:15 AM',
              'shift': 'MORNING',
              'tripStatus': 'SCHEDULED',
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    // Verify it scrolls smoothly when dragged vertically
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('Driver Companion'), findsOneWidget);
  });
  testWidgets('active trip action ends the trip instead of starting again', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: DriverDashboard(
            user: UserModel(
              id: '2',
              name: 'Driver',
              email: 'driver@school.com',
              role: UserRole.driver,
              avatarUrl: '',
              details: '',
              token: 'token',
            ),
            onOpenDrawer: () {},
            initialDuty: const {
              'busId': 3,
              'routeId': 4,
              'activeTripId': 10,
              'busNumber': 'Bus 3',
              'tripStatus': 'IN_PROGRESS',
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(const Key('driver-trip-action'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: action, matching: find.text('End Trip')),
      findsOneWidget,
    );
    expect(find.text('Start Scheduled Trip'), findsNothing);
    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Complete Transport Trip?'), findsOneWidget);
    await tester.tap(find.text('Resume Trip'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: action, matching: find.text('End Trip')),
      findsOneWidget,
    );
  });
}
