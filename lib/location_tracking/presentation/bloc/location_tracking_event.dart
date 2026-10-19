abstract class LocationTrackingEvent {
  const LocationTrackingEvent();
}

final class LocationTrackingStatusRequested extends LocationTrackingEvent {
  const LocationTrackingStatusRequested();
}

final class LocationTrackingStarted extends LocationTrackingEvent {
  const LocationTrackingStarted({
    required this.tripId,
    required this.driverEmail,
    this.restart = false,
  });
  final int tripId;
  final String driverEmail;
  final bool restart;
}

final class LocationTrackingStopped extends LocationTrackingEvent {
  const LocationTrackingStopped();
}
