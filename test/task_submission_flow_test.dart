import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/user_model.dart';
import 'package:school_desk_app/data/models/school_models.dart';
import 'package:school_desk_app/data/repositories/api_school_repository.dart';
import 'package:school_desk_app/view/screens/modules/homework_screen.dart';
import 'package:school_desk_app/view/screens/modules/assignment_submission_screen.dart';

class TaskRepository extends ApiSchoolRepository {
  String status = 'overdue';
  String? answer, attachment, assignmentId;
  int submissions = 0;
  bool fail = false;
  HomeworkItem task() => HomeworkItem.fromJson({
    'id': 'hw_42',
    'title': 'Fractions exercise',
    'subject': 'Math',
    'className': '7',
    'description': 'Solve the exercise.',
    'dueDate': '2026-01-01',
    'submissionStatus': status,
    'submissionText': answer,
    'submissionFileUrl': attachment,
  });
  @override
  Future<List<HomeworkItem>> getStudentAssignments({
    String? admissionNo,
  }) async => [task()];
  @override
  Future<bool> submitStudentAssignmentWork({
    required String assignmentId,
    String? submissionText,
    String? fileUrl,
  }) async {
    submissions++;
    if (fail) throw StateError('Offline');
    this.assignmentId = assignmentId;
    answer = submissionText;
    attachment = fileUrl;
    status = 'submitted';
    return true;
  }
}

const student = UserModel(
  id: '1',
  name: 'Student',
  email: 's@test.local',
  role: UserRole.student,
  avatarUrl: '',
  details: '',
  admissionNo: 'ADM1',
);

void main() {
  testWidgets(
    'Overdue task has visible submit action and updates to submitted',
    (tester) async {
      final repo = TaskRepository();
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: HomeworkScreen(user: student, repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Submit Work'), findsOneWidget);
      await tester.tap(find.text('Submit Work'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'One half plus one half equals one.',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'https://example.test/work.pdf',
      );
      await tester.tap(find.text('Submit Work'));
      await tester.pumpAndSettle();
      expect(repo.assignmentId, 'hw_42');
      expect(repo.answer, 'One half plus one half equals one.');
      expect(repo.attachment, 'https://example.test/work.pdf');
      expect(find.text('View submission'), findsOneWidget);
      await tester.tap(find.text('View submission'));
      await tester.pumpAndSettle();
      expect(find.text('Your Submission'), findsOneWidget);
      expect(find.text('One half plus one half equals one.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Validation prevents empty work, failure preserves draft and retry succeeds',
    (tester) async {
      final repo = TaskRepository()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: AssignmentSubmissionScreen(
            assignment: repo.task(),
            repository: repo,
          ),
        ),
      );
      await tester.tap(find.text('Submit Work'));
      await tester.pumpAndSettle();
      expect(
        find.text('Write your answer or add an attachment link.'),
        findsOneWidget,
      );
      expect(repo.submissions, 0);
      await tester.enterText(
        find.byType(TextFormField).first,
        'My completed answer',
      );
      await tester.tap(find.text('Submit Work'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Unable to submit work.'), findsOneWidget);
      expect(find.text('My completed answer'), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('Submit Work'));
      await tester.pumpAndSettle();
      expect(repo.submissions, 2);
      expect(repo.status, 'submitted');
    },
  );

  testWidgets('Parent sees tasks without student submit action', (
    tester,
  ) async {
    const parent = UserModel(
      id: '2',
      name: 'Parent',
      email: 'p@test.local',
      role: UserRole.parent,
      avatarUrl: '',
      details: '',
    );
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          home: HomeworkScreen(user: parent, repository: TaskRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fractions exercise'), findsOneWidget);
    expect(find.text('Submit Work'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
