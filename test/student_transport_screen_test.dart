import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:school_desk_app/view/screens/modules/transport/student_transport_screen.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    Future<Map<String, dynamic>> Function() load,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: StudentTransportScreen(loadTransport: load)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('No assignment shows No transport and no map', (tester) async {
    await open(tester, () async => {'assigned': false});
    expect(find.text('No transport'), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
    await close(tester);
  });

  testWidgets(
    'Roll 31 with Patna stop coordinates waits for actual driver GPS',
    (tester) async {
      await open(
        tester,
        () async => {
          'assigned': true,
          'studentName': 'Student 31',
          'rollNo': '31',
          'admissionNo': 'ADM31',
          'routeName': 'Assigned route',
          'tripStatus': 'IN_PROGRESS',
          'gpsFresh': false,
          'stopLatitude': 25.6100,
          'stopLongitude': 85.1350,
          'dropLatitude': 25.5970,
          'dropLongitude': 85.1550,
          'busLatitude': 25.6150,
          'busLongitude': 85.1280,
        },
      );
      expect(find.byType(GoogleMap), findsNothing);
      expect(find.textContaining('Waiting for driver GPS'), findsWidgets);
      expect(find.text('Assigned route'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Roll number'), 200);
      expect(find.text('31'), findsOneWidget);
      expect(find.text('ADM31'), findsOneWidget);
      await close(tester);
    },
  );

  testWidgets('Inactive trip cannot show map even with cached coordinates', (
    tester,
  ) async {
    await open(
      tester,
      () async => {
        'assigned': true,
        'tripStatus': 'COMPLETED',
        'gpsFresh': true,
        'busLatitude': 25.6150,
        'busLongitude': 85.1280,
      },
    );
    expect(find.text('Trip completed'), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
    await close(tester);
  });

  testWidgets('API failure shows retry instead of a dummy map', (tester) async {
    await open(tester, () async => throw StateError('Network failed'));
    expect(find.text('Transport unavailable'), findsOneWidget);
    expect(find.byType(GoogleMap), findsNothing);
    await close(tester);
  });
}
