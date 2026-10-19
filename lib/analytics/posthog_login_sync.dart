import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/user_model.dart';
import '../logic/auth/auth_bloc.dart';
import 'posthog_analytics_service.dart';

/// Identifies the logged-in user in PostHog after auth succeeds.
Future<void> syncPosthogIdentity(
  UserModel user, [
  PosthogAnalyticsService? analytics,
]) async {
  final service = analytics ?? posthogAnalytics;
  await service.identifyUser(user);
}

/// Identifies the logged-in user from the current [BuildContext] using [AuthBloc].
Future<void> syncPosthogIdentityFromContext(
  BuildContext context, [
  PosthogAnalyticsService? analytics,
]) async {
  final authState = context.read<AuthBloc>().state;
  final user = authState.user;
  if (user != null) {
    final service = analytics ?? posthogAnalytics;
    await service.identifyUser(user);
  }
}

/// Identifies from a fresh [UserModel] right after login.
Future<void> syncPosthogIdentityFromLogin(
  PosthogAnalyticsService analytics,
  UserModel user,
) async {
  await analytics.identifyUser(user);
}

/// Resets PostHog identity on logout.
Future<void> resetPosthogIdentity([
  PosthogAnalyticsService? analytics,
]) async {
  final service = analytics ?? posthogAnalytics;
  await service.resetIdentity();
}
