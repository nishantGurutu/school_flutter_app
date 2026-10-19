import '../../core/di/locator.dart';
import 'posthog_analytics_service.dart';

/// Accessor for [PosthogAnalyticsService] using GetIt locator or singleton instance.
PosthogAnalyticsService get posthogAnalyticsService =>
    getIt.isRegistered<PosthogAnalyticsService>()
        ? getIt<PosthogAnalyticsService>()
        : posthogAnalytics;

/// Backward-compatible alias for the analytics service getter.
PosthogAnalyticsService get posthogAnalyticsServiceProvider => posthogAnalyticsService;
