import 'package:geolocator/geolocator.dart';

enum LocationTrackingStatus {
  initial,
  checking,
  starting,
  tracking,
  stopping,
  stopped,
}

class LocationTrackingState {
  const LocationTrackingState({
    this.status = LocationTrackingStatus.initial,
    this.lastLocation,
    this.tripId,
    this.distanceKm = 0,
    this.errorMessage,
  });

  final LocationTrackingStatus status;
  final Position? lastLocation;
  final int? tripId;
  final double distanceKm;
  final String? errorMessage;

  bool get isTracking => status == LocationTrackingStatus.tracking;
  bool get isBusy =>
      status == LocationTrackingStatus.checking ||
      status == LocationTrackingStatus.starting ||
      status == LocationTrackingStatus.stopping;

  LocationTrackingState copyWith({
    LocationTrackingStatus? status,
    Position? lastLocation,
    int? tripId,
    double? distanceKm,
    String? errorMessage,
    bool clearLocation = false,
  }) => LocationTrackingState(
    status: status ?? this.status,
    tripId: tripId ?? this.tripId,
    distanceKm: distanceKm ?? this.distanceKm,
    lastLocation: clearLocation ? null : lastLocation ?? this.lastLocation,
    errorMessage: errorMessage,
  );
}
