import '../../../../services/driver_location_gate.dart';
import '../../../../location_tracking/presentation/trip_navigation_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../location_tracking/presentation/bloc/location_tracking_bloc.dart';
import '../../../../location_tracking/data/datasources/location_service.dart';
import '../../../../services/storage/local_storage.dart';
import '../../../../data/models/user_model.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/transport_service.dart';

class ActiveTripScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ActiveTripScreen({super.key, this.initialData});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late int _tripId;
  bool _ending = false;
  bool _authorized = false;
  bool _loading = false;
  String? _loadError;
  DateTime _startedAt = DateTime.now();
  bool _hasBusPosition = false;
  String _busNumber = '';
  String _routeName = 'Assigned route';

  // Live Telemetry states
  double _speedKmh = 0.0;
  double _distanceKm = 0.0;
  int _elapsedSeconds = 0;
  Timer? _tripClockTimer;
  StreamSubscription<LocationTrackingState>? _locationSub;
  DateTime? _lastLocationTime;

  // Map state
  GoogleMapController? _mapController;
  LatLng _busPosition = const LatLng(20.6, 78.9);
  final List<LatLng> _traveledTrail = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Stops state
  List<Map<String, dynamic>> _stops = [];

  @override
  void initState() {
    super.initState();
    final navigation = TripNavigationData(widget.initialData);
    _tripId = navigation.tripId;
    _busNumber = navigation.busNumber;
    _routeName = navigation.routeName;
    _stops = navigation.stops;
    _startedAt = navigation.startedAt ?? DateTime.now();
    if (navigation.position != null) {
      _busPosition = navigation.position!;
      _hasBusPosition = true;
    } else if (_stops.isNotEmpty) {
      _busPosition =
          TripNavigationData.coordinate(
            _stops.first['latitude'],
            _stops.first['longitude'],
          ) ??
          _busPosition;
    }
    _initTracking();
    _startClockTimer();
  }

  Future<void> _initTracking({bool restart = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _restoreTracking(restart: restart);
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = 'Could not open the trip: $error');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restoreTracking({required bool restart}) async {
    final user = await StorageHelper.getUserSession();
    if (!mounted) return;
    if (user?.role != UserRole.driver || _tripId <= 0) {
      throw StateError(
        'A signed-in driver and a valid active trip are required.',
      );
    }
    await _locationSub?.cancel();
    _locationSub = null;
    // Restore local trail without restarting or clearing the trip journal.
    final points = await LocationService.store.points(_tripId);
    if (!mounted) return;
    final saved = await LocationService.store.session(_tripId);
    if (!mounted) return;
    setState(() {
      _authorized = true;
      _traveledTrail.clear();
      _traveledTrail.addAll(
        points
            .map(
              (point) => TripNavigationData.coordinate(
                point['latitude'],
                point['longitude'],
              ),
            )
            .whereType<LatLng>(),
      );
      if (_traveledTrail.isNotEmpty) {
        _busPosition = _traveledTrail.last;
        _hasBusPosition = true;
      }
      _distanceKm = (saved?['distance_km'] as num?)?.toDouble() ?? 0;
      _updateMapPins();
    });
    final bloc = context.read<LocationTrackingBloc>();
    _locationSub = bloc.stream.listen((state) {
      final position = state.lastLocation;
      if (!mounted ||
          state.tripId != _tripId ||
          position == null ||
          position.timestamp == _lastLocationTime) {
        return;
      }
      final point = TripNavigationData.coordinate(
        position.latitude,
        position.longitude,
      );
      if (point == null) return;
      _lastLocationTime = position.timestamp;
      setState(() {
        _busPosition = point;
        _hasBusPosition = true;
        _speedKmh = position.speed > 0 ? position.speed * 3.6 : 0;
        _distanceKm = state.distanceKm;
        if (_traveledTrail.isEmpty || _traveledTrail.last != point) {
          _traveledTrail.add(point);
        }
        _updateMapPins();
      });
      unawaited(_moveCamera(CameraUpdate.newLatLng(_busPosition)));
    });
    // A pending completion stays stopped; End Trip retries the frozen batch.
    if (saved == null || saved['state'] == 'active') {
      bloc.add(const LocationTrackingStatusRequested());
      bloc.add(
        LocationTrackingStarted(
          tripId: _tripId,
          driverEmail: user!.email,
          restart: restart,
        ),
      );
    }
  }

  void _startClockTimer() {
    _tripClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = DateTime.now()
              .difference(_startedAt)
              .inSeconds
              .clamp(0, 999999);
        });
      }
    });
  }

  void _updateMapPins() {
    _markers.clear();
    _polylines.clear();

    // 1. Bus Marker
    if (_hasBusPosition) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver_active_bus'),
          position: _busPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(
            title: '$_busNumber (You)',
            snippet:
                'Speed: ${_speedKmh.toInt()} km/h | Dist: ${_distanceKm.toStringAsFixed(1)} km',
          ),
        ),
      );
    }

    // 2. Stops Markers
    final List<LatLng> plannedPoints = [];
    for (int i = 0; i < _stops.length; i++) {
      final s = _stops[i];
      final stopPos = TripNavigationData.coordinate(
        s['latitude'],
        s['longitude'],
      );
      if (stopPos != null) {
        plannedPoints.add(stopPos);

        final isVisited = s['status'] == 'DEPARTED';
        final isCurrent = s['status'] == 'ARRIVED';

        _markers.add(
          Marker(
            markerId: MarkerId('stop_${s['id'] ?? i}'),
            position: stopPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isVisited
                  ? BitmapDescriptor.hueGreen
                  : (isCurrent
                        ? BitmapDescriptor.hueAzure
                        : BitmapDescriptor.hueOrange),
            ),
            infoWindow: InfoWindow(
              title: '${s['stopOrder']}. ${s['stopName']}',
              snippet:
                  'Scheduled: ${s['plannedMorningPickupTime'] ?? 'N/A'} | Status: ${s['status']}',
            ),
          ),
        );
      }
    }

    // 3. Planned Route Polyline (Dashed Blue)
    if (plannedPoints.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('planned_route_path'),
          points: plannedPoints,
          color: const Color(0xFF0284C7),
          width: 4,
          patterns: [PatternItem.dash(15), PatternItem.gap(10)],
        ),
      );
    }

    // 4. Actual Traveled GPS Trail (Solid Teal)
    if (_traveledTrail.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('actual_gps_trail'),
          points: _traveledTrail,
          color: const Color(0xFF0D9488),
          width: 5,
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _tripClockTimer?.cancel();
    // GoogleMap owns its controller and disposes it with the platform view.
    _mapController = null;
    super.dispose();
  }

  Future<void> _moveCamera(CameraUpdate update) async {
    final controller = _mapController;
    if (!mounted || controller == null) return;
    try {
      await controller.animateCamera(update);
    } catch (_) {
      /* The platform map may be closing during navigation. */
    }
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _handleEndTrip() async {
    if (_ending || !_authorized) return;
    setState(() => _ending = true);
    if (!await DriverLocationGate.ensureReady(context) || !mounted) {
      if (mounted) setState(() => _ending = false);
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Transport Trip?'),
        content: Text(
          'Total distance covered: ${_distanceKm.toStringAsFixed(1)} km.\nElapsed Time: ${_formatDuration(_elapsedSeconds)}.\n\nBackground GPS tracking will automatically cease.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Resume Trip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Complete Trip',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) {
      setState(() => _ending = false);
      return;
    }
    try {
      if (!await DriverLocationGate.ensureReady(context) || !mounted) {
        if (mounted) setState(() => _ending = false);
        return;
      }
      await TransportService.endTrip(
        tripId: _tripId,
        totalDistanceKm: _distanceKm,
      );
      if (!mounted) return;
      context.read<LocationTrackingBloc>().add(
        const LocationTrackingStatusRequested(),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _ending = false);
      context.read<LocationTrackingBloc>().add(
        const LocationTrackingStatusRequested(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trip could not be completed. Saved GPS points are retained. Retry End Trip: $error',
          ),
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trip completed successfully. GPS telemetry saved to school records.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Trip')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initTracking,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_loading || !_authorized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Trip Tracking',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$_busNumber • $_routeName',
              style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          BlocBuilder<LocationTrackingBloc, LocationTrackingState>(
            builder: (context, state) {
              if (state.errorMessage == null) return const SizedBox.shrink();
              return MaterialBanner(
                content: Text(state.errorMessage!),
                actions: [
                  TextButton(
                    onPressed: _ending
                        ? null
                        : () => _initTracking(restart: true),
                    child: const Text('Retry GPS'),
                  ),
                ],
              );
            },
          ),
          // Live Google Map
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _busPosition,
                    zoom: 14.8,
                  ),
                  onMapCreated: (ctrl) {
                    _mapController = ctrl;
                    _updateMapPins();
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // Telemetry HUD Bar
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  right: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _hudMetric(
                          'Speed',
                          '${_speedKmh.toInt()} km/h',
                          const Color(0xFF0D9488),
                        ),
                        _hudMetric(
                          'Distance',
                          '${_distanceKm.toStringAsFixed(1)} km',
                          const Color(0xFF2563EB),
                        ),
                        _hudMetric(
                          'Time',
                          _formatDuration(_elapsedSeconds),
                          const Color(0xFF10B981),
                        ),
                        BlocBuilder<
                          LocationTrackingBloc,
                          LocationTrackingState
                        >(
                          builder: (context, state) => _hudMetric(
                            'GPS',
                            state.isTracking ? 'ACTIVE' : 'STOPPED',
                            state.isTracking
                                ? const Color(0xFF10B981)
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recenter map button
                Positioned(
                  bottom: 12.h,
                  right: 12.w,
                  child: FloatingActionButton.small(
                    heroTag: 'driver_center_bus',
                    onPressed: () {
                      unawaited(
                        _moveCamera(
                          CameraUpdate.newLatLngZoom(_busPosition, 15.5),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFF0D9488),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _ending ? null : _handleEndTrip,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(_ending ? 'Saving Trip…' : 'End Trip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          2.h.verticalSpace,
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
