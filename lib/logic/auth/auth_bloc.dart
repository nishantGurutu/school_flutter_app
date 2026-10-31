import 'dart:async';
import '../../services/school_chat_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  SchoolChatService? _chat;
  String? _chatUserId;
  SchoolChatService get chat =>
      _chat ??= (SchoolChatService()..visible = false);

  void _startChat(String id, String name) {
    if (_chatUserId != null && _chatUserId != id) {
      _chat?.dispose();
      _chat = null;
    }
    _chatUserId = id;
    chat.setIdentity(id, name);
    unawaited(chat.start());
  }

  @override
  Future<void> close() {
    _chat?.dispose();
    return super.close();
  }

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

      _startChat(user.id, user.name);

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
    _chat?.dispose();
    _chat = null;
    _chatUserId = null;
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
      _startChat(storedUser.id, storedUser.name);
      unawaited(syncPosthogIdentity(storedUser));
      emit(state.copyWith(status: AuthStatus.authenticated, user: storedUser));
    } else {
      _chat?.dispose();
      _chat = null;
      _chatUserId = null;
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }
}
