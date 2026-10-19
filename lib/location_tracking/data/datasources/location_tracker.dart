import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Manages GPS stream subscription and position updates.
///
/// Single Responsibility: only handles location tracking stream.
class LocationTracker {
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastPosition;

  Position? get lastPosition => _lastPosition;

  Stream<Position> startTracking() {
    final locationSettings = _buildLocationSettings();

    _positionSubscription?.cancel();
    final stream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).asBroadcastStream();

    _positionSubscription = stream.listen(
      (position) => _lastPosition = position,
      onError: (_) {},
    );

    return stream;
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPosition = null;
  }

  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 10),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }
}
