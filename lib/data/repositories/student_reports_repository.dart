import '../models/student_report_model.dart';
import '../network/network_api_services.dart';
import '../../utils/app_url.dart';

class StudentReportsRepository {
  final NetworkApiService api;
  StudentReportsRepository({NetworkApiService? api})
    : api = api ?? NetworkApiService();
  Future<List<StudentReportModel>> getReports({String? admissionNo}) async {
    final admission = admissionNo?.trim() ?? '';
    final response = await api.getApi(
      '${AppUrl.baseUrl}/student-reports'
      '${admission.isEmpty ? '' : '?admissionNo=${Uri.encodeComponent(admission)}'}',
    );
    if (response is! List) {
      throw const FormatException('Invalid reports response');
    }
    return response
        .map(
          (item) => StudentReportModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}
