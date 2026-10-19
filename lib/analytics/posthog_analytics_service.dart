import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:school_desk_app/data/exception/app_exceptions.dart';
import 'package:school_desk_app/data/models/user_model.dart';
import 'posthog_feature.dart';

/// Shared instance updated with login/session context.
final posthogAnalytics = PosthogAnalyticsService();

/// Central PostHog wrapper for error tracking, exception steps, and identity
/// tailored for SchoolDesk BLoC project.
class PosthogAnalyticsService {
  PosthogAnalyticsService();

  UserModel? _currentUser;
  bool _sessionActive = false;
  String? _currentScreen;

  UserModel? get currentUser => _currentUser;
  bool get sessionActive => _sessionActive;
  String? get currentScreen => _currentScreen;

  void updateUser(UserModel? user) {
    _currentUser = user;
  }

  void updateSessionActive(bool active) {
    _sessionActive = active;
  }

  void updateCurrentScreen(String? screen) {
    _currentScreen = screen;
  }

  /// Identifies the logged in [UserModel] in PostHog.
  Future<void> identifyUser(UserModel user) async {
    _currentUser = user;
    await Posthog().identify(
      userId: user.id,
      userProperties: {
        'name': user.name,
        'email': user.email,
        'role': user.role.name,
        'user_type': user.userType ?? user.role.name,
        if (user.className != null) 'class_name': user.className!,
        if (user.department != null) 'department': user.department!,
        if (user.admissionNo != null) 'admission_no': user.admissionNo!,
        if (user.rollNo != null) 'roll_no': user.rollNo!,
        if (user.phone != null) 'phone': user.phone!,
      },
    );
  }

  /// Compatibility alias for user/employee identification.
  Future<void> identifyFromEmployee(dynamic employee) async {
    if (employee is UserModel) {
      await identifyUser(employee);
    } else if (employee != null) {
      await Posthog().identify(userId: employee.toString());
    }
  }

  /// Compatibility alias for context-based identification.
  Future<void> identifyFromContext(dynamic context) async {
    if (context is UserModel) {
      await identifyUser(context);
    }
  }

  Future<void> resetIdentity() async {
    _currentUser = null;
    await Posthog().reset();
  }

  Future<void> addStep(
    String name, {
    PosthogFeature? feature,
    Map<String, Object>? properties,
  }) async {
    try {
      await Posthog().addExceptionStep(
        name,
        properties: {
          if (feature != null) 'feature': feature.value,
          ...?properties,
        },
      );
    } catch (_) {}
  }

  Future<void> captureSessionExpired({String? screen}) async {
    try {
      final props = await _baseProperties(
        feature: PosthogFeature.auth,
        screen: screen,
        action: 'session_expired',
      );
      await Posthog().captureLog(
        body: 'Session expired',
        level: PostHogLogSeverity.warn,
        attributes: {
          ...props,
          'log_type': 'session_expired',
        },
      );
    } catch (_) {}
  }

  /// Returns `true` when the error was captured, `false` when filtered out.
  Future<bool> captureException(
    Object error, {
    StackTrace? stackTrace,
    PosthogFeature feature = PosthogFeature.core,
    String? screen,
    String? action,
    Map<String, Object>? properties,
  }) async {
    if (_shouldFilter(error)) {
      if (error is AppException) {
        await addStep(
          'network_error_suppressed',
          feature: feature,
          properties: {'message': error.message},
        );
      }
      return false;
    }

    try {
      final base = await _baseProperties(
        feature: feature,
        screen: screen ?? _currentScreen,
        action: action,
      );
      await Posthog().captureException(
        error: error,
        stackTrace: stackTrace,
        properties: {
          ...base,
          ...?properties,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _shouldFilter(Object error) {
    if (error is UnauthorisedException) return true;
    if (error is NoInternetException) return true;
    final message = error.toString().toLowerCase();
    if (message.contains('cancelled') || message.contains('canceled')) {
      return true;
    }
    if (message.contains('user denied') ||
        message.contains('permission denied')) {
      return true;
    }
    return false;
  }

  Future<Map<String, Object>> buildBaseProperties({
    required PosthogFeature feature,
    String? screen,
    String? action,
  }) =>
      _baseProperties(feature: feature, screen: screen, action: action);

  Future<Map<String, Object>> _baseProperties({
    required PosthogFeature feature,
    String? screen,
    String? action,
  }) async {
    String platform;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        platform = 'android';
      case TargetPlatform.iOS:
        platform = 'ios';
      default:
        platform = 'other';
    }

    return {
      'feature': feature.value,
      if (screen != null && screen.isNotEmpty) 'screen': screen,
      if (action != null && action.isNotEmpty) 'action': action,
      'platform': platform,
      if (_currentUser != null) ...{
        'user_id': _currentUser!.id,
        'user_name': _currentUser!.name,
        'user_role': _currentUser!.role.name,
        if (_currentUser!.className != null) 'class_name': _currentUser!.className!,
        if (_currentUser!.department != null) 'department': _currentUser!.department!,
      },
      'session_active': _sessionActive,
    };
  }
}

/// Initializes PostHog Logs + Error tracking for School Desk app.
Future<void> initPostHog({
  String? apiKey,
  String? host,
  bool debug = kDebugMode,
}) async {
  final token = apiKey ?? const String.fromEnvironment('POSTHOG_API_KEY', defaultValue: '');
  if (token.isEmpty) {
    return;
  }

  final config = PostHogConfig(token);
  config.host = host ?? const String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://us.i.posthog.com');
  config.debug = debug;
  config.captureApplicationLifecycleEvents = true;

  // Structured logs
  config.logsConfig.serviceName = 'school_desk_app';
  config.logsConfig.serviceVersion = '1.0.0+1';
  config.logsConfig.environment = kDebugMode ? 'development' : 'production';
  config.logsConfig.rateCapMaxLogs = kDebugMode ? 5000 : 2000;
  config.logsConfig.rateCapWindow = const Duration(seconds: 60);
  config.logsConfig.beforeSend = [
    (record) {
      final attrs = record.attributes;
      if (attrs == null) return record;
      for (final key in attrs.keys.toList()) {
        final lower = key.toLowerCase();
        if (lower.contains('password') ||
            lower.contains('token') ||
            lower.contains('pin') ||
            lower == 'authorization') {
          attrs[key] = '[redacted]';
        }
      }
      return record;
    },
  ];

  // Error tracking
  config.errorTrackingConfig.captureFlutterErrors = true;
  config.errorTrackingConfig.capturePlatformDispatcherErrors = true;
  config.errorTrackingConfig.captureIsolateErrors = true;
  config.errorTrackingConfig.captureNativeExceptions = true;
  config.errorTrackingConfig.captureNativeCrashes = true;
  config.errorTrackingConfig.exceptionSteps.enabled = true;
  config.errorTrackingConfig.inAppIncludes.add('package:school_desk_app');

  await Posthog().setup(config);
}
