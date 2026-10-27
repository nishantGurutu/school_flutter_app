import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/data/repositories/student_teachers_repository.dart';
import 'package:school_desk_app/view/widgets/student_teachers_dialog.dart';

class TeachersApi extends NetworkApiService {
  String? url;
  bool fail = false;
  List<Map<String, dynamic>> teachers = [
    {
      'id': 1,
      'name': 'Asha Teacher',
      'subject': 'Mathematics',
      'email': 'asha@school.test',
      'phone': '1234567890',
    },
    {'id': 2, 'name': 'Ravi Teacher', 'subject': 'Science'},
  ];
  @override
  Future<dynamic> getApi(String url) async {
    this.url = url;
    if (fail) throw StateError('Offline');
    return teachers;
  }
}

void main() {
  test(
    'Uses authenticated student endpoint and preserves linked-child context',
    () async {
      final api = TeachersApi();
      final repo = StudentTeachersRepository(api: api);
      expect((await repo.getTeachers()).length, 2);
      expect(api.url, endsWith('/mobile/student/teachers'));
      await repo.getTeachers(admissionNo: 'ADM/42');
      expect(api.url, endsWith('?admissionNo=ADM%2F42'));
    },
  );
  testWidgets(
    'Shows real teachers, retries errors, and refresh removes unassigned teachers',
    (tester) async {
      final api = TeachersApi()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentTeachersDialog(
              repository: StudentTeachersRepository(api: api),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to load teachers. Please try again.'),
        findsOneWidget,
      );
      api.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Asha Teacher'), findsOneWidget);
      expect(find.text('Ravi Teacher'), findsOneWidget);
      expect(find.textContaining('Mathematics'), findsOneWidget);
      api.teachers = [];
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(
        find.text('No teachers are assigned to your class yet.'),
        findsOneWidget,
      );
      expect(find.text('Asha Teacher'), findsNothing);
    },
  );
}
