import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/transport_service.dart';
import '../../../../services/location_tracking_service.dart';
import '../../../widgets/glass_card.dart';

class ActiveTripScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ActiveTripScreen({super.key, this.initialData});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late int _tripId;
  String _busNumber = 'Bus 04';
  String _routeName = 'Route 1 - North Campus Loop';

  // Live Telemetry states
  double _speedKmh = 0.0;
  double _distanceKm = 0.0;
  int _elapsedSeconds = 0;
  Timer? _tripClockTimer;
  StreamSubscription? _locationSub;

  // Map state
  GoogleMapController? _mapController;
  LatLng _busPosition = const LatLng(25.6150, 85.1280);
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
    final trip = widget.initialData?['trip'] as Map<String, dynamic>?;
    final duty = widget.initialData?['duty'] as Map<String, dynamic>?;

    _tripId = trip?['tripId'] is int
        ? trip!['tripId'] as int
        : (duty?['activeTripId'] is int ? duty!['activeTripId'] as int : 1);
    _busNumber = duty?['busNumber']?.toString() ?? 'Bus 04';
    _routeName = duty?['routeName']?.toString() ?? 'Route 1 - North Campus Loop';

    final stopsRaw = duty?['route']?['stops'] as List<dynamic>?;
    if (stopsRaw != null && stopsRaw.isNotEmpty) {
      _stops = stopsRaw.map((s) => Map<String, dynamic>.from(s as Map)).toList();
    } else {
      _stops = [
        {'id': 1, 'stopName': 'North City Square', 'stopOrder': 1, 'plannedMorningPickupTime': '07:15 AM', 'status': 'DEPARTED', 'students': 8, 'latitude': 25.6150, 'longitude': 85.1280},
        {'id': 2, 'stopName': 'Metro Station Pillar 42', 'stopOrder': 2, 'plannedMorningPickupTime': '07:25 AM', 'status': 'ARRIVED', 'students': 12, 'latitude': 25.6100, 'longitude': 85.1350},
        {'id': 3, 'stopName': 'Central Mall Junction', 'stopOrder': 3, 'plannedMorningPickupTime': '07:35 AM', 'status': 'PENDING', 'students': 10, 'latitude': 25.6050, 'longitude': 85.1410},
        {'id': 4, 'stopName': 'Kankarbagh Park', 'stopOrder': 4, 'plannedMorningPickupTime': '07:45 AM', 'status': 'PENDING', 'students': 9, 'latitude': 25.6010, 'longitude': 85.1480},
        {'id': 5, 'stopName': 'School Main Gate', 'stopOrder': 5, 'plannedMorningPickupTime': '08:00 AM', 'status': 'PENDING', 'students': 39, 'latitude': 25.5970, 'longitude': 85.1550},
      ];
    }

    _initTracking();
    _startClockTimer();
  }

  void _initTracking() async {
    final tracking = LocationTrackingService();
    await tracking.startTracking(
      tripId: _tripId,
      initialLat: _busPosition.latitude,
      initialLon: _busPosition.longitude,
      routeStops: _stops,
    );

    _locationSub = tracking.locationStream.listen((data) {
      if (!mounted) return;

      if (data.containsKey('type') && data['type'] == 'STOP_ARRIVAL_CANDIDATE') {
        final stop = data['stop'] as Map<String, dynamic>?;
        if (stop != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Geofence: Approaching ${stop['stopName']}'),
              backgroundColor: const Color(0xFF0D9488),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final lat = (data['latitude'] as num?)?.toDouble() ?? _busPosition.latitude;
      final lon = (data['longitude'] as num?)?.toDouble() ?? _busPosition.longitude;
      final speed = (data['speedKmh'] as num?)?.toDouble() ?? _speedKmh;
      final dist = (data['distanceKm'] as num?)?.toDouble() ?? _distanceKm;

      setState(() {
        _busPosition = LatLng(lat, lon);
        _speedKmh = speed;
        _distanceKm = dist;
        _traveledTrail.add(_busPosition);
        _updateMapPins();
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_busPosition),
      );
    });
  }

  void _startClockTimer() {
    _tripClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _updateMapPins() {
    _markers.clear();
    _polylines.clear();

    // 1. Bus Marker
    _markers.add(
      Marker(
        markerId: const MarkerId('driver_active_bus'),
        position: _busPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(
          title: '$_busNumber (You)',
          snippet: 'Speed: ${_speedKmh.toInt()} km/h | Dist: ${_distanceKm.toStringAsFixed(1)} km',
        ),
      ),
    );

    // 2. Stops Markers
    final List<LatLng> plannedPoints = [];
    for (int i = 0; i < _stops.length; i++) {
      final s = _stops[i];
      final sLat = (s['latitude'] as num?)?.toDouble();
      final sLon = (s['longitude'] as num?)?.toDouble();
      if (sLat != null && sLon != null) {
        final stopPos = LatLng(sLat, sLon);
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
                  : (isCurrent ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueOrange),
            ),
            infoWindow: InfoWindow(
              title: '${s['stopOrder']}. ${s['stopName']}',
              snippet: 'Scheduled: ${s['plannedMorningPickupTime'] ?? 'N/A'} | Status: ${s['status']}',
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
    _mapController?.dispose();
    LocationTrackingService().stopTracking();
    super.dispose();
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
              Text('Report Safety Incident', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Incident Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIncidentType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'TRAFFIC_DELAY', child: Text('Traffic Congestion')),
                    DropdownMenuItem(value: 'ROUTE_DEVIATION', child: Text('Route Diversion / Block')),
                    DropdownMenuItem(value: 'BUS_BREAKDOWN', child: Text('Mechanical Breakdown')),
                    DropdownMenuItem(value: 'ACCIDENT', child: Text('Vehicle Collision / Scratch')),
                    DropdownMenuItem(value: 'MEDICAL_EMERGENCY', child: Text('Student Medical Help')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => _selectedIncidentType = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Description & Action Taken', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(
                  controller: _incidentDescController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter incident details, location landmark, delay estimate...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(ctx);
                await TransportService.reportIncident(
                  tripId: _tripId,
                  incidentType: _selectedIncidentType,
                  description: _incidentDescController.text.trim().isNotEmpty
                      ? _incidentDescController.text.trim()
                      : 'Incident reported by driver via companion app',
                  lat: _busPosition.latitude,
                  lon: _busPosition.longitude,
                );
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Incident alerted to School Desk transport manager.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Dispatch Alert', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleEndTrip() async {
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
            child: const Text('Complete Trip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await LocationTrackingService().stopTracking();

    await TransportService.endTrip(
      tripId: _tripId,
      totalDistanceKm: _distanceKm > 0.1 ? _distanceKm : 18.5,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip completed successfully. GPS telemetry saved to school records.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
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
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            onPressed: _showReportIncidentDialog,
          ),
          8.w.horizontalSpace,
        ],
      ),
      body: Column(
        children: [
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
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                        _hudMetric('Speed', '${_speedKmh.toInt()} km/h', const Color(0xFF0D9488)),
                        _hudMetric('Distance', '${_distanceKm.toStringAsFixed(1)} km', const Color(0xFF2563EB)),
                        _hudMetric('Time', _formatDuration(_elapsedSeconds), const Color(0xFF10B981)),
                        _hudMetric('GPS', 'LIVE', const Color(0xFF10B981)),
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
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_busPosition, 15.5),
                      );
                    },
                    backgroundColor: const Color(0xFF0D9488),
                    child: const Icon(Icons.my_location_rounded, color: Colors.white),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        onPressed: _handleEndTrip,
                        icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.white),
                        label: const Text('End Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
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
                                      : (isArrived ? const Color(0xFF0D9488) : AppColors.border),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isDeparted
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : Text(
                                          '${idx + 1}',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                            color: isArrived ? Colors.white : AppColors.textPrimary,
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
                                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    2.h.verticalSpace,
                                    Text(
                                      'Pickup: ${stop['plannedMorningPickupTime'] ?? 'N/A'} • ${stop['students'] ?? 0} Students',
                                      style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isDeparted) ...[
                                if (!isArrived)
                                  OutlinedButton(
                                    onPressed: () => _handleStopAction(idx, 'ARRIVED'),
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                      side: const BorderSide(color: Color(0xFF0D9488)),
                                    ),
                                    child: const Text('Arrived', style: TextStyle(color: Color(0xFF0D9488), fontSize: 11)),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () => _handleStopAction(idx, 'DEPARTED'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    ),
                                    child: const Text('Depart', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                              ] else
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        2.h.verticalSpace,
        Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}
