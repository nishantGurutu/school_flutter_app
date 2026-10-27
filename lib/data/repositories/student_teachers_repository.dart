import '../models/student_teacher_model.dart';
import '../network/network_api_services.dart';
import '../../utils/app_url.dart';

class StudentTeachersRepository {
  final NetworkApiService api;
  StudentTeachersRepository({NetworkApiService? api})
    : api = api ?? NetworkApiService();
  Future<List<StudentTeacherModel>> getTeachers({String? admissionNo}) async {
    final admission = admissionNo?.trim() ?? '';
    final response = await api.getApi(
      '${AppUrl.baseUrl}/mobile/student/teachers'
      '${admission.isEmpty ? '' : '?admissionNo=${Uri.encodeComponent(admission)}'}',
    );
    if (response is! List) {
      throw const FormatException('Invalid teachers response');
    }
    return response
        .map(
          (item) => StudentTeacherModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
