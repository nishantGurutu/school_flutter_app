import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/school_models.dart';
import 'package:school_desk_app/data/repositories/api_school_repository.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/view/widgets/create_assignment_sheet.dart';

class PickerRepository extends ApiSchoolRepository {
  bool fail = false;
  String? requestedClass, requestedSection;
  dynamic assignedStudent;
  @override
  Future<List<TeacherClassModel>> getTeacherClasses({
    bool throwOnError = false,
  }) async => [
    TeacherClassModel.fromJson({
      'id': '1',
      'className': 'Play',
      'section': 'Blue',
      'subject': 'Math',
    }),
    TeacherClassModel.fromJson({
      'id': '2',
      'className': 'KG',
      'section': 'Green',
      'subject': 'English',
    }),
  ];
  @override
  Future<List<StudentInClassModel>> getClassStudents(
    String className, {
    String? section,
    bool throwOnError = false,
  }) async {
    requestedClass = className;
    requestedSection = section;
    if (fail) throw StateError('Offline');
    return [
      StudentInClassModel(
        id: 42,
        admissionNo: 'ADM42',
        name: 'Asha',
        className: className,
        section: section,
        rollNo: '12',
      ),
    ];
  }

  @override
  Future<HomeworkItem?> createTeacherAssignment({
    required String title,
    required String description,
    required String subject,
    required String className,
    String? section,
    required String dueDate,
    int points = 100,
    dynamic targetStudentId,
    String? fileAttachmentUrl,
  }) async {
    assignedStudent = targetStudentId;
    requestedClass = className;
    requestedSection = section;
    return HomeworkItem.fromJson({
      'id': 'hw_1',
      'title': title,
      'subject': subject,
      'className': className,
      'dueDate': dueDate,
    });
  }
}

class FailingPickerApi extends NetworkApiService {
  @override
  Future<dynamic> getApi(String url) async =>
      throw StateError('Permission denied');
}

void main() {
  test('API class and student errors propagate', () async {
    final repo = ApiSchoolRepository(apiService: FailingPickerApi());
    await expectLater(
      repo.getTeacherClasses(throwOnError: true),
      throwsStateError,
    );
    await expectLater(
      repo.getClassStudents('Play', section: 'Blue', throwOnError: true),
      throwsStateError,
    );
  });
  testWidgets('Specific Student loads actual assigned class and students', (
    tester,
  ) async {
    final repo = PickerRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CreateAssignmentSheet(repository: repo)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Class 10'), findsNothing);
    await tester.tap(find.text('Specific Student'));
    await tester.pumpAndSettle();
    expect(repo.requestedClass, 'Play');
    expect(repo.requestedSection, 'Blue');
    await tester.ensureVisible(find.text('Select Student by ID / Name'));
    await tester.tap(find.text('Select Student by ID / Name'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Asha'), findsWidgets);
  });
  testWidgets('Student load failure is visible and retry recovers', (
    tester,
  ) async {
    final repo = PickerRepository()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CreateAssignmentSheet(repository: repo)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Specific Student'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('assignment-student-error')), findsOneWidget);
    repo.fail = false;
    await tester.ensureVisible(find.text('Retry students'));
    await tester.tap(find.text('Retry students'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('assignment-student-error')), findsNothing);
  });
  testWidgets(
    'Targeted publish sends selected student ID and actual class section',
    (tester) async {
      final repo = PickerRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CreateAssignmentSheet(repository: repo),
                ),
                child: const Text('Open assignment'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open assignment'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Assignment Title'),
        'Personal exercise',
      );
      await tester.tap(find.text('Specific Student'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Select Student by ID / Name'));
      await tester.tap(find.text('Select Student by ID / Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Asha').last);
      await tester.pumpAndSettle();
      final publish = find.text('Assign to Student ID: #42');
      await tester.ensureVisible(publish);
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expect(repo.assignedStudent, 42);
      expect(repo.requestedClass, 'Play');
      expect(repo.requestedSection, 'Blue');
      expect(find.text('Create New Assignment'), findsNothing);
    },
  );
}
