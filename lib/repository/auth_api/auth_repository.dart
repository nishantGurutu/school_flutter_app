abstract class AuthRepository {
  Future<bool> login(String email, String password);
  Future<void> logout();
}

class AuthHttpApiRepository implements AuthRepository {
  @override
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // Mock success
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
