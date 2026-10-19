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
import '../../../widgets/glass_card.dart';

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
  int _currentStopIndex = 0;

  // Incident modal states
  final _incidentDescController = TextEditingController();
  String _selectedIncidentType = 'TRAFFIC_DELAY';

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
    _incidentDescController.dispose();
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

  void _handleStopAction(int index, String newStatus) async {
    final stop = _stops[index];
    final stopId = stop['id'] is int ? stop['id'] as int : (index + 1);

    setState(() {
      _stops[index]['status'] = newStatus;
      if (newStatus == 'DEPARTED' && index < _stops.length - 1) {
        _currentStopIndex = index + 1;
      }
      _updateMapPins();
    });

    await TransportService.recordStopEvent(
      tripId: _tripId,
      stopId: stopId,
      eventType: newStatus,
      studentsBoarded: stop['students'] is int ? stop['students'] as int : 5,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${stop['stopName']} marked as $newStatus'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showReportIncidentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'Report Safety Incident',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incident Type',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIncidentType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'TRAFFIC_DELAY',
                      child: Text('Traffic Congestion'),
                    ),
                    DropdownMenuItem(
                      value: 'ROUTE_DEVIATION',
                      child: Text('Route Diversion / Block'),
                    ),
                    DropdownMenuItem(
                      value: 'BUS_BREAKDOWN',
                      child: Text('Mechanical Breakdown'),
                    ),
                    DropdownMenuItem(
                      value: 'ACCIDENT',
                      child: Text('Vehicle Collision / Scratch'),
                    ),
                    DropdownMenuItem(
                      value: 'MEDICAL_EMERGENCY',
                      child: Text('Student Medical Help'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDlgState(() => _selectedIncidentType = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Description & Action Taken',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _incidentDescController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Enter incident details, location landmark, delay estimate...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(this.context);
                Navigator.pop(ctx);
                final sent = await TransportService.reportIncident(
                  tripId: _tripId,
                  incidentType: _selectedIncidentType,
                  description: _incidentDescController.text.trim().isNotEmpty
                      ? _incidentDescController.text.trim()
                      : 'Incident reported by driver via companion app',
                  lat: _hasBusPosition ? _busPosition.latitude : null,
                  lon: _hasBusPosition ? _busPosition.longitude : null,
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      sent
                          ? 'Incident alerted to School Desk transport manager.'
                          : 'Incident was not sent. Please retry.',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(
                'Dispatch Alert',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEndTrip() async {
    if (_ending || !_authorized) return;
    setState(() => _ending = true);
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
            ),
            onPressed: _showReportIncidentDialog,
          ),
          8.w.horizontalSpace,
        ],
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

          // Lower Stops & Actions Sheet
          Expanded(
            flex: 6,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Route Stops Sequence (${_stops.length})',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _ending ? null : _handleEndTrip,
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          _ending ? 'Saving Trip…' : 'End Trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                  10.h.verticalSpace,

                  // Scrollable Stops List
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _stops.length,
                      separatorBuilder: (c, i) => 8.h.verticalSpace,
                      itemBuilder: (context, idx) {
                        final stop = _stops[idx];
                        final isCurrent = idx == _currentStopIndex;
                        final isDeparted = stop['status'] == 'DEPARTED';
                        final isArrived = stop['status'] == 'ARRIVED';

                        return GlassCard(
                          padding: EdgeInsets.all(12.r),
                          child: Row(
                            children: [
                              Container(
                                width: 28.r,
                                height: 28.r,
                                decoration: BoxDecoration(
                                  color: isDeparted
                                      ? const Color(0xFF10B981)
                                      : (isArrived
                                            ? const Color(0xFF0D9488)
                                            : AppColors.border),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isDeparted
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                            color: isArrived
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                ),
                              ),
                              12.w.horizontalSpace,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop['stopName'] ?? 'Stop ${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: isCurrent
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    2.h.verticalSpace,
                                    Text(
                                      'Pickup: ${stop['plannedMorningPickupTime'] ?? 'N/A'} • ${stop['students'] ?? 0} Students',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isDeparted) ...[
                                if (!isArrived)
                                  OutlinedButton(
                                    onPressed: () =>
                                        _handleStopAction(idx, 'ARRIVED'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                    child: const Text(
                                      'Arrived',
                                      style: TextStyle(
                                        color: Color(0xFF0D9488),
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () =>
                                        _handleStopAction(idx, 'DEPARTED'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                    ),
                                    child: const Text(
                                      'Depart',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ] else
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
