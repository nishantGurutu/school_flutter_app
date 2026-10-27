import '../models/guardian_model.dart';
import '../network/network_api_services.dart';
import '../../utils/app_url.dart';

class GuardianRepository {
  final NetworkApiService api;
  GuardianRepository({NetworkApiService? api})
    : api = api ?? NetworkApiService();

  Future<List<GuardianModel>> getGuardians({String? admissionNo}) async {
    final admission = admissionNo?.trim() ?? '';
    final url =
        '${AppUrl.baseUrl}/mobile/student/guardians'
        '${admission.isEmpty ? '' : '?admissionNo=${Uri.encodeComponent(admission)}'}';
    final response = await api.getApi(url);
    if (response is! List) {
      throw const FormatException('Invalid guardian response');
    }
    return response
        .map(
          (item) =>
              GuardianModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
