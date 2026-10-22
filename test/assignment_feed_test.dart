import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/school_models.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/data/repositories/api_school_repository.dart';

class AssignmentApi extends NetworkApiService {
  dynamic response;
  Object? error;
  String? requestedUrl;
  @override
  Future<dynamic> getApi(String url) async {
    requestedUrl = url;
    if (error != null) throw error!;
    return response;
  }
}

void main() {
  test('Published ACTIVE assignment remains in pending tasks', () {
    final task = HomeworkItem.fromJson({
      'id': 'hw_42',
      'title': 'Dashboard exercise',
      'status': 'ACTIVE',
      'dueDate': '2026-12-01',
    });
    expect(task.status, HomeworkStatus.pending);
    expect(task.submissionStatus, 'pending');
    expect(task.submissionCount, 0);
    expect(task.evaluatedCount, 0);
    expect(task.totalStudents, 0);
  });

  test('Submission state takes precedence over assignment lifecycle state', () {
    final task = HomeworkItem.fromJson({
      'id': 'hw_42',
      'status': 'ACTIVE',
      'submissionStatus': 'GRADED',
    });
    expect(task.status, HomeworkStatus.graded);
    expect(task.submissionStatus, 'graded');
  });

  test(
    'Student feed preserves dashboard assignment and selected admission',
    () async {
      final api = AssignmentApi()
        ..response = [
          {
            'id': 'hw_42',
            'title': 'Dashboard exercise',
            'status': 'pending',
            'isPersonalized': true,
          },
        ];
      final tasks = await ApiSchoolRepository(
        apiService: api,
      ).getStudentAssignments(admissionNo: 'ADM 42');
      expect(tasks.single.id, 'hw_42');
      expect(tasks.single.title, 'Dashboard exercise');
      expect(tasks.single.isPersonalized, isTrue);
      expect(
        api.requestedUrl,
        endsWith('/mobile/student/assignments?admissionNo=ADM%2042'),
      );
    },
  );

  test(
    'API failure reaches screen instead of returning an empty task list',
    () async {
      final api = AssignmentApi()
        ..error = StateError('Student profile not linked');
      await expectLater(
        ApiSchoolRepository(apiService: api).getStudentAssignments(),
        throwsStateError,
      );
    },
  );

  test('A successful empty response remains empty', () async {
    final api = AssignmentApi()..response = [];
    expect(
      await ApiSchoolRepository(apiService: api).getStudentAssignments(),
      isEmpty,
    );
  });
}
