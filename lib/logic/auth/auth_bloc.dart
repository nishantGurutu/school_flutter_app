import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/di/locator.dart';
import '../../data/exception/app_exceptions.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository = getIt<AuthRepository>();

  AuthBloc() : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.authenticating, errorMessage: null));

    try {
      final user = await _authRepository.login(
        event.email,
        event.password,
        loginUser: event.loginUser,
      );

      if (user == null) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Invalid mobile/email or password.',
        ));
        // Reset state back to unauthenticated
        await Future.delayed(const Duration(seconds: 2));
        emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null));
        return;
      }

      // Progress through visual Role Verification stages (SOLID visual feedback)
      emit(state.copyWith(status: AuthStatus.verifyingCredentials));
      await Future.delayed(const Duration(milliseconds: 700));

      emit(state.copyWith(status: AuthStatus.loadingPermissions));
      await Future.delayed(const Duration(milliseconds: 700));

      emit(state.copyWith(status: AuthStatus.loadingModules));
      await Future.delayed(const Duration(milliseconds: 700));

      // Finally authenticate
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      final message = e is AppException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: message.isNotEmpty ? message : 'An error occurred. Please try again.',
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.authenticating));
    await _authRepository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    final storedUser = await _authRepository.getStoredUser();
    if (storedUser != null) {
      emit(state.copyWith(status: AuthStatus.authenticated, user: storedUser));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }
}
