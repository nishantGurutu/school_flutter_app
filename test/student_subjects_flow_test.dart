import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/home_dashboard_model.dart';
import 'package:school_desk_app/data/models/curriculum_model.dart';
import 'package:school_desk_app/data/repositories/api_school_repository.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/view/screens/modules/student_subjects_screen.dart';

class SubjectsApi extends NetworkApiService {
  String? url;
  @override
  Future<dynamic> getApi(String url) async {
    this.url = url;
    return [
      {'id': 42, 'name': 'Mathematics', 'code': 'MATH-7'},
    ];
  }
}

class SubjectsRepository extends ApiSchoolRepository {
  bool fail = false;
  List<DashboardSubject> subjects = [
    DashboardSubject(id: 42, name: 'Mathematics', code: 'MATH-7'),
  ];
  String? openedSubject;
  @override
  Future<List<DashboardSubject>> getStudentSubjects({
    String? admissionNo,
  }) async {
    if (fail) throw Exception('Offline');
    return subjects;
  }

  @override
  Future<SubjectCurriculumModel?> getSubjectCurriculum(String subjectId) async {
    openedSubject = subjectId;
    return SubjectCurriculumModel(
      subjectId: subjectId,
      subjectName: 'Mathematics',
      subjectCode: 'MATH-7',
    );
  }
}

void main() {
  test(
    'Subject feed uses authenticated class endpoint and encodes child context',
    () async {
      final api = SubjectsApi();
      final repo = ApiSchoolRepository(apiService: api);
      expect((await repo.getStudentSubjects()).single.id, 42);
      expect(api.url, endsWith('/mobile/student/subjects'));
      await repo.getStudentSubjects(admissionNo: 'ADM/42');
      expect(api.url, endsWith('?admissionNo=ADM%2F42'));
    },
  );

  testWidgets('Searches class subjects and opens real curriculum by ID', (
    tester,
  ) async {
    final repo = SubjectsRepository();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) =>
            MaterialApp(home: StudentSubjectsScreen(repository: repo)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mathematics'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'biology');
    await tester.pumpAndSettle();
    expect(find.text('No matching subjects.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'math');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mathematics'));
    await tester.pumpAndSettle();
    expect(repo.openedSubject, '42');
  });

  testWidgets(
    'Retry recovers from error and refresh removes deleted subjects',
    (tester) async {
      final repo = SubjectsRepository()..fail = true;
      await tester.pumpWidget(
        MaterialApp(home: StudentSubjectsScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to load subjects. Please try again.'),
        findsOneWidget,
      );
      repo.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Mathematics'), findsOneWidget);
      repo.subjects = [];
      await tester.tap(find.byTooltip('Refresh subjects'));
      await tester.pumpAndSettle();
      expect(
        find.text('No subjects have been added for your class.'),
        findsOneWidget,
      );
      expect(find.text('Mathematics'), findsNothing);
    },
  );
}
