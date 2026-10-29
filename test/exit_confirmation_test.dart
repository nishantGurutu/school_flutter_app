import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/view/widgets/exit_confirmation.dart';

void main() {
  testWidgets('Back asks before exiting; cancel and dismiss keep app open', (
    tester,
  ) async {
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: ExitConfirmation(child: Scaffold(body: Text('Home'))),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to close the app?'),
      findsOneWidget,
    );
    expect(
      platformCalls.where((c) => c.method == 'SystemNavigator.pop'),
      isEmpty,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      platformCalls.where((c) => c.method == 'SystemNavigator.pop'),
      isEmpty,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(
      platformCalls.where((c) => c.method == 'SystemNavigator.pop'),
      hasLength(1),
    );
  });

  testWidgets('Back closes drawer and child pages before asking to exit', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: ExitConfirmation(
          child: Scaffold(
            key: scaffoldKey,
            drawer: const Drawer(child: Text('Menu')),
            body: const Text('Home'),
          ),
        ),
      ),
    );
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(scaffoldKey.currentState!.isDrawerOpen, isFalse);
    expect(find.byType(AlertDialog), findsNothing);

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Details')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
