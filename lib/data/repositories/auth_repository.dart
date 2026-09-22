import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String email, String password, {String? loginUser});
  Future<UserModel?> getStoredUser();
  Future<void> logout();
}
