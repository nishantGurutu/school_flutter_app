import 'package:school_desk_app/data/exception/app_exceptions.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/services/storage/local_storage.dart';
import 'package:school_desk_app/utils/app_url.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final NetworkApiService _apiService;

  ApiAuthRepository({NetworkApiService? apiService})
    : _apiService = apiService ?? NetworkApiService();

  static String? authToken;
  static UserModel? currentUser;

  @override
  Future<UserModel?> login(
    String email,
    String password, {
    String? loginUser,
  }) async {
    final Map<String, dynamic> payload = {
      'email': email.trim(),
      'password': password,
    };

    // Reset previous session
    await StorageHelper.clear();
    authToken = null;
    currentUser = null;

    final data = await _apiService.postApi(AppUrl.login, payload);

    if (data != null && data is Map<String, dynamic>) {
      final token = data['accessToken'] ?? data['token'];
      if (token == null || token.toString().isEmpty) {
        throw UnauthorisedException('Invalid credentials');
      }
      await StorageHelper.saveLoginResponse(data);
      authToken = token.toString();
      final user = UserModel.fromJson(
        data,
        token: authToken,
        refreshToken: data['refreshToken'],
      );
      currentUser = user;
      return user;
    } else {
      throw UnauthorisedException('Invalid credentials');
    }
  }

  @override
  Future<UserModel?> getStoredUser() async {
    final user = await StorageHelper.getUserSession();
    if (user != null) {
      authToken = user.token;
      currentUser = user;
    }
    return user;
  }

  @override
  Future<void> logout() async {
    await StorageHelper.clear();
    authToken = null;
    currentUser = null;
  }
}
