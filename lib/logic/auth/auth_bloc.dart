import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_desk_app/services/push_notifications.dart';

import '../../analytics/posthog_analytics_service.dart';
import '../../analytics/posthog_feature.dart';
import '../../analytics/posthog_login_sync.dart';
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

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, errorMessage: null));

    try {
      final user = await _authRepository.login(
        event.email,
        event.password,
        loginUser: event.loginUser,
      );

      if (user == null) {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            errorMessage: 'Invalid credentials',
          ),
        );
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

      // Sync identity to PostHog
      unawaited(syncPosthogIdentity(user));
    } catch (e, stackTrace) {
      unawaited(
        posthogAnalytics.captureException(
          e,
          stackTrace: stackTrace,
          feature: PosthogFeature.auth,
          action: 'login_requested',
        ),
      );

      String message = 'Invalid credentials';
      if (e is AppException && e.message.isNotEmpty) {
        message = e.message;
      } else {
        final errStr = e.toString().replaceFirst('Exception: ', '').trim();
        if (errStr.isNotEmpty && !errStr.startsWith('Instance of')) {
          message = errStr;
        }
      }
      emit(state.copyWith(status: AuthStatus.error, errorMessage: message));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating));
    await PushNotifications.instance.signedOut();
    await _authRepository.logout();
    unawaited(resetPosthogIdentity());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final storedUser = await _authRepository.getStoredUser();
    if (storedUser != null) {
      unawaited(syncPosthogIdentity(storedUser));
      emit(state.copyWith(status: AuthStatus.authenticated, user: storedUser));
      unawaited(PushNotifications.instance.signedIn());
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }
}
