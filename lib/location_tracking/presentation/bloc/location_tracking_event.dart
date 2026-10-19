abstract class LocationTrackingEvent {
  const LocationTrackingEvent();
}

final class LocationTrackingStatusRequested extends LocationTrackingEvent {
  const LocationTrackingStatusRequested();
}

final class LocationTrackingStarted extends LocationTrackingEvent {
  const LocationTrackingStarted({
    required this.empId,
    required this.companyCode,
    required this.token,
    required this.deviceId,
    required this.baseUrl,
    required this.uploadUrl,
  });

  final int empId;
  final String companyCode;
  final String token;
  final String deviceId;
  final String baseUrl;
  final String uploadUrl;
}

final class LocationTrackingStopped extends LocationTrackingEvent {
  const LocationTrackingStopped();
}
