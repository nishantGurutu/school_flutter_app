import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/guardian_model.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/data/repositories/guardian_repository.dart';
import 'package:school_desk_app/view/widgets/guardian_list_dialog.dart';
import 'package:school_desk_app/view/screens/modules/guardian_details_screen.dart';

class GuardianApi extends NetworkApiService {
  dynamic response = <dynamic>[];
  bool fail = false;
  String? url;
  @override
  Future<dynamic> getApi(String url) async {
    this.url = url;
    if (fail) throw Exception('Offline');
    return response;
  }
}

void main() {
  test(
    'Fetches all linked guardians and encodes the selected student',
    () async {
      final api = GuardianApi()
        ..response = [
          {'id': 1, 'name': 'Asha', 'relation': 'MOTHER'},
          {'id': 2, 'name': 'Ravi', 'guardianType': 'FATHER'},
          {'id': 3, 'name': 'Neha', 'relation': 'SISTER'},
        ];
      final guardians = await GuardianRepository(
        api: api,
      ).getGuardians(admissionNo: 'ADM/42');
      expect(
        api.url,
        endsWith('/mobile/student/guardians?admissionNo=ADM%2F42'),
      );
      expect(guardians.map((g) => g.name), ['Asha', 'Ravi', 'Neha']);
      expect(guardians.last.relation, 'Sister');
    },
  );

  test(
    'Uses authenticated identity when admission is absent, propagates failures',
    () async {
      final api = GuardianApi();
      final repo = GuardianRepository(api: api);
      expect(await repo.getGuardians(), isEmpty);
      expect(api.url, endsWith('/mobile/student/guardians'));
      api.fail = true;
      await expectLater(repo.getGuardians(), throwsException);
    },
  );

  testWidgets('Dialog shows error, retries, and returns selected guardian', (
    tester,
  ) async {
    final api = GuardianApi()..fail = true;
    GuardianModel? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showDialog<GuardianModel>(
                  context: context,
                  builder: (_) => GuardianListDialog(
                    repository: GuardianRepository(api: api),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to load guardians. Please try again.'),
      findsOneWidget,
    );
    api.fail = false;
    api.response = [
      {'id': 7, 'name': 'Asha', 'relation': 'MOTHER', 'phone': '9876543210'},
    ];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asha'));
    await tester.pumpAndSettle();
    expect(selected?.id, '7');
    await tester.pumpWidget(
      MaterialApp(home: GuardianDetailsScreen(guardian: selected!)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Not provided'), findsWidgets);
  });

  testWidgets('Empty guardians shows honest empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianListDialog(
            repository: GuardianRepository(api: GuardianApi()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No guardians have been added for this student.'),
      findsOneWidget,
    );
  });
}
