import 'package:get_it/get_it.dart';
import '../../analytics/posthog_analytics_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../data/repositories/school_repository.dart';
import '../../data/repositories/api_school_repository.dart';

final getIt = GetIt.instance;

void setupLocator() {
  // PostHog Analytics Service
  getIt.registerLazySingleton<PosthogAnalyticsService>(() => posthogAnalytics);

  // Repositories connected to Spring Boot Backend API
  getIt.registerLazySingleton<AuthRepository>(() => ApiAuthRepository());
  getIt.registerLazySingleton<SchoolRepository>(() => ApiSchoolRepository());
}
