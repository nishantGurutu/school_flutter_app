import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/datasources/location_tracker.dart';
import '../../data/repositories/location_tracking_repository_impl.dart';
import '../models/periodic_location_payload.dart';

/// Schedules periodic location uploads and manages background service lifecycle.
///
/// Single Responsibility: only coordinates the upload loop and service events.
class LocationUploadScheduler {
  LocationUploadScheduler({
    required LocationTracker tracker,
    required LocationTrackingRepositoryImpl repository,
    required ServiceInstance serviceInstance,
  }) : _tracker = tracker,
       _repository = repository,
       _service = serviceInstance;

  final LocationTracker _tracker;
  final LocationTrackingRepositoryImpl _repository;
  final ServiceInstance _service;

  Timer? _uploadTimer;
  bool _isForegroundState = true;
  bool _uploading = false;
  bool _disposed = false;
  StreamSubscription<Position>? _positions;
  StreamSubscription<Map<String, dynamic>?>? _foreground;
  StreamSubscription<Map<String, dynamic>?>? _stop;

  void start({
    required int empId,
    required String companyCode,
    required String token,
    required String deviceId,
    required Future<String> Function(double lat, double lng) getAddress,
    required Future<int> Function() getBatteryLevel,
  }) {
    // Listen to foreground/background state changes.
    _foreground = _service.on('set_foreground').listen((event) {
      if (event != null && event['foreground'] is bool) {
        _isForegroundState = event['foreground'] as bool;
      }
    });

    // Listen to stop service.
    _stop = _service.on('stopService').listen((_) async {
      await _dispose();
      _service.invoke('on_tracking_stopped');
      await _service.stopSelf();
    });

    _positions = _tracker.startTracking().listen(
      (position) {
        _service.invoke('on_location_update', {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': position.timestamp.toIso8601String(),
          'accuracy': position.accuracy,
          'heading': position.heading,
          'speed': position.speed,
        });
      },
      onError: (Object error) {
        _service.invoke('on_error', {'message': 'GPS error: $error'});
      },
    );

    _uploadTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_disposed || _uploading) return;
      final currentPos = _tracker.lastPosition;
      if (currentPos == null) return;

      _uploading = true;
      try {
        // Reverse-geocoding hits AddressByLatLon over the network. Offline it
        // cannot resolve, so fall back to an empty address — the point below
        // is still built and queued locally instead of being dropped.
        String address;
        try {
          address = await getAddress(currentPos.latitude, currentPos.longitude);
          if (address.trim().toLowerCase() == 'no address') address = '';
        } catch (_) {
          address = '';
        }
        final batteryLevel = await getBatteryLevel();

        if (_disposed) return;
        final payload = PeriodicLocationPayload.fromDetails(
          latitude: currentPos.latitude,
          longitude: currentPos.longitude,
          address: address,
          batteryLevel: batteryLevel.toDouble(),
          deviceId: deviceId,
          empId: empId,
          foreground: _isForegroundState,
          timestamp: currentPos.timestamp,
        );

        await _repository.uploadLocation(
          empId: empId,
          companyCode: companyCode,
          token: token,
          payload: payload,
        );
      } catch (error) {
        _service.invoke('on_error', {
          'message': 'Location upload failed; point retained for retry: $error',
        });
      } finally {
        _uploading = false;
      }
    });
  }

  Future<void> _dispose() async {
    _disposed = true;
    _uploadTimer?.cancel();
    await _positions?.cancel();
    await _foreground?.cancel();
    await _stop?.cancel();
    await _tracker.stopTracking();
  }
}
