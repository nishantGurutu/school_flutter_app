/// Canonical feature identifiers attached to every PostHog error event.
enum PosthogFeature {
  core('core'),
  auth('auth'),
  splash('splash'),
  dashboard('dashboard'),
  students('students'),
  teachers('teachers'),
  attendance('attendance'),
  homework('homework'),
  timetable('timetable'),
  exams('exams'),
  fees('fees'),
  transport('transport'),
  holidays('holidays'),
  notices('notices'),
  leaves('leaves'),
  curriculum('curriculum'),
  chat('chat'),
  notifications('notifications'),
  profile('profile'),
  settings('settings'),
  // Legacy / extra features
  dcr('dcr'),
  tourPlan('tour_plan'),
  tpDeviation('tp_deviation'),
  visuals('visuals'),
  nearbyCustomers('nearby_customers'),
  master('master'),
  reports('reports'),
  helpCenter('help_center'),
  locationTracking('location_tracking'),
  fakeGps('fake_gps'),
  serverDateTime('server_date_time'),
  otp('otp'),
  rollout('rollout');

  const PosthogFeature(this.value);

  final String value;

  /// Infers a feature from an API path segment.
  static PosthogFeature? fromEndpoint(String path) {
    final normalized = path.toLowerCase();
    if (normalized.contains('login') || normalized.contains('auth')) {
      return PosthogFeature.auth;
    }
    if (normalized.contains('attendance')) return PosthogFeature.attendance;
    if (normalized.contains('homework') || normalized.contains('assignment')) {
      return PosthogFeature.homework;
    }
    if (normalized.contains('fee')) return PosthogFeature.fees;
    if (normalized.contains('timetable')) return PosthogFeature.timetable;
    if (normalized.contains('exam')) return PosthogFeature.exams;
    if (normalized.contains('transport') || normalized.contains('bus')) {
      return PosthogFeature.transport;
    }
    if (normalized.contains('notice')) return PosthogFeature.notices;
    if (normalized.contains('holiday')) return PosthogFeature.holidays;
    if (normalized.contains('leave')) return PosthogFeature.leaves;
    if (normalized.contains('curriculum') || normalized.contains('subject') || normalized.contains('lesson')) {
      return PosthogFeature.curriculum;
    }
    if (normalized.contains('student')) return PosthogFeature.students;
    if (normalized.contains('teacher') || normalized.contains('staff')) {
      return PosthogFeature.teachers;
    }
    if (normalized.contains('chat') || normalized.contains('message')) {
      return PosthogFeature.chat;
    }
    if (normalized.contains('notification')) return PosthogFeature.notifications;
    if (normalized.contains('profile')) return PosthogFeature.profile;
    if (normalized.contains('dashboard')) return PosthogFeature.dashboard;
    if (normalized.contains('settings')) return PosthogFeature.settings;
    if (normalized.contains('dcr') || normalized.contains('visit')) {
      return PosthogFeature.dcr;
    }
    if (normalized.contains('tour') || normalized.contains('tp')) {
      return PosthogFeature.tourPlan;
    }
    if (normalized.contains('report')) return PosthogFeature.reports;
    if (normalized.contains('help') || normalized.contains('support')) {
      return PosthogFeature.helpCenter;
    }
    return null;
  }
}
