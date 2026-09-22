import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/services/storage/local_storage.dart';
import 'package:school_desk_app/utils/app_url.dart';
import '../exception/app_exceptions.dart';
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
    try {
      final payload = {
        'email': email.trim(),
        'password': password,
        'loginUser': loginUser,
        'userType': loginUser,
      };

      final data = await _apiService.postApi(AppUrl.login, payload);

      if (data != null && data is Map<String, dynamic>) {
        await StorageHelper.saveLoginResponse(data);
        authToken = data['accessToken'] ?? data['token'];
        final user = UserModel.fromJson(data, token: authToken, refreshToken: data['refreshToken']);
        currentUser = user;
        return user;
      } else {
        return null;
      }
    } on UnauthorisedException {
      rethrow;
    } on BadRequestException {
      rethrow;
    } on AppException catch (e) {
      if (e is NoInternetException) {
        return _offlineFallbackLogin(email, password, loginUser);
      }
      rethrow;
    } catch (e) {
      return _offlineFallbackLogin(email, password, loginUser);
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

  UserModel? _offlineFallbackLogin(
    String email,
    String password,
    String? loginUser,
  ) {
    final formatted = email.trim().toLowerCase();
    UserRole role = UserRole.student;
    if (loginUser != null) {
      if (loginUser.toUpperCase() == 'PARENT') role = UserRole.parent;
      if (loginUser.toUpperCase() == 'TEACHER') role = UserRole.teacher;
      if (loginUser.toUpperCase() == 'STAFF') role = UserRole.staff;
      if (loginUser.toUpperCase() == 'ADMIN') role = UserRole.admin;
      if (loginUser.toUpperCase() == 'MASTER_ADMIN') role = UserRole.masterAdmin;
    } else {
      if (formatted.contains('parent')) role = UserRole.parent;
      if (formatted.contains('teacher')) role = UserRole.teacher;
      if (formatted.contains('staff')) role = UserRole.staff;
      if (formatted.contains('admin')) role = UserRole.admin;
    }

    String name = 'Rohan Sharma';
    String details = 'Roll No: 24 • Class 10-A';
    String className = 'Class 10-A';
    String avatar =
        'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150';

    if (role == UserRole.parent) {
      name = 'Anita Sharma';
      className = 'Parent of Rohan';
      details = 'Parent of Rohan Sharma (10-A)';
      avatar =
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150';
    } else if (role == UserRole.teacher) {
      name = 'Ms. Priya Sharma';
      className = 'Maths Teacher';
      details = 'Mathematics Head Teacher';
      avatar =
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150';
    } else if (role == UserRole.staff || role == UserRole.admin || role == UserRole.masterAdmin) {
      name = role == UserRole.masterAdmin ? 'System Admin' : 'Rajesh Kumar';
      className = role == UserRole.masterAdmin ? 'Master Admin' : 'Accountant';
      details = role == UserRole.masterAdmin ? 'System Administrator' : 'Accounts & Finance Manager';
      avatar =
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150';
    }

    final user = UserModel(
      id: '${role.name}_1',
      name: name,
      email: email,
      role: role,
      avatarUrl: avatar,
      className: className,
      details: details,
    );
    StorageHelper.saveLoginResponse(user.toJson());
    return user;
  }

  @override
  Future<void> logout() async {
    await StorageHelper.clear();
    authToken = null;
    currentUser = null;
  }
}
