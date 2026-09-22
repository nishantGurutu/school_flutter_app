import 'api_auth_repository.dart';

class AuthRepositoryImpl extends ApiAuthRepository {
  AuthRepositoryImpl({super.apiService});
}

typedef MockAuthRepository = AuthRepositoryImpl;

