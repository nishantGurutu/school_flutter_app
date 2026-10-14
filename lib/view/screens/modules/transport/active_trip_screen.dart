import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  String _busNumber = 'Bus 04';
  String _routeName = 'Route 1 - North Campus Loop';

  // Live Telemetry states
  double _speedKmh = 32.0;
  double _distanceKm = 4.2;
  int _elapsedSeconds = 720; // 12 mins
  Timer? _telemetryTimer;
  Timer? _gpsSyncTimer;

  // Stops state
  List<Map<String, dynamic>> _stops = [];
  int _currentStopIndex = 1;

  // Incident modal states
  final _incidentDescController = TextEditingController();
  String _selectedIncidentType = 'TRAFFIC_DELAY';

  @override
  void initState() {
    super.initState();
    final trip = widget.initialData?['trip'] as Map<String, dynamic>?;
    final duty = widget.initialData?['duty'] as Map<String, dynamic>?;

    _tripId = trip?['tripId'] is int ? trip!['tripId'] as int : (duty?['activeTripId'] is int ? duty!['activeTripId'] as int : 1);
    _busNumber = duty?['busNumber']?.toString() ?? 'Bus 04';
    _routeName = duty?['routeName']?.toString() ?? 'Route 1 - North Campus Loop';

    final stopsRaw = duty?['route']?['stops'] as List<dynamic>?;
    if (stopsRaw != null) {
      _stops = stopsRaw.map((s) => Map<String, dynamic>.from(s as Map)).toList();
    } else {
      _stops = [
        {'id': 1, 'stopName': 'North City Square', 'stopOrder': 1, 'plannedMorningPickupTime': '07:15 AM', 'status': 'DEPARTED', 'students': 8},
        {'id': 2, 'stopName': 'Metro Station Pillar 42', 'stopOrder': 2, 'plannedMorningPickupTime': '07:25 AM', 'status': 'ARRIVED', 'students': 12},
        {'id': 3, 'stopName': 'Central Mall Junction', 'stopOrder': 3, 'plannedMorningPickupTime': '07:35 AM', 'status': 'PENDING', 'students': 10},
        {'id': 4, 'stopName': 'Kankarbagh Park', 'stopOrder': 4, 'plannedMorningPickupTime': '07:45 AM', 'status': 'PENDING', 'students': 9},
        {'id': 5, 'stopName': 'School Main Gate', 'stopOrder': 5, 'plannedMorningPickupTime': '08:00 AM', 'status': 'PENDING', 'students': 39},
      ];
    }

    _startTelemetryLoop();
  }

  void _startTelemetryLoop() {
    // 1-second telemetry clock & speed fluctuation
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        // Natural speed variation around 28-38 km/h
        _speedKmh = 28.0 + (timer.tick % 10);
        _distanceKm += 0.008; // increment distance smoothly
      });
    });

    // 8-second GPS telemetry sync to backend
    _gpsSyncTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      TransportService.sendGpsLocation(
        tripId: _tripId,
        lat: 25.6025 + (_distanceKm * 0.001),
        lon: 85.1430 + (_distanceKm * 0.001),
        speedKmh: _speedKmh,
      );
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _gpsSyncTimer?.cancel();
    _incidentDescController.dispose();
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'TRAFFIC_DELAY', child: Text('Traffic Congestion / Delay')),
                    DropdownMenuItem(value: 'ROUTE_DEVIATION', child: Text('Unplanned Route Diversion')),
                    DropdownMenuItem(value: 'BUS_BREAKDOWN', child: Text('Vehicle Breakdown / Puncture')),
                    DropdownMenuItem(value: 'EMERGENCY', child: Text('Medical / Emergency SOS')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other Safety Concern')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDlgState(() => _selectedIncidentType = v);
                  },
                ),
                SizedBox(height: 12.h),
                const Text('Description / Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                SizedBox(height: 6.h),
                TextField(
                  controller: _incidentDescController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter details for admin dispatch...',
                    hintStyle: const TextStyle(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
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
                final ok = await TransportService.reportIncident(
                  tripId: _tripId,
                  incidentType: _selectedIncidentType,
                  description: _incidentDescController.text.trim().isNotEmpty
                      ? _incidentDescController.text.trim()
                      : 'Reported by driver via companion app.',
                );
                if (ok && mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Incident reported to School Desk transport control!'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Send Alert', style: TextStyle(color: Colors.white)),
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
        title: const Text('End Transport Trip?'),
        content: Text(
          'Total distance: ${_distanceKm.toStringAsFixed(1)} km\nElapsed Time: ${_formatDuration(_elapsedSeconds)}\nStops completed: $_currentStopIndex of ${_stops.length}\n\nThis will stop background tracking and record final journey history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Trip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm End Trip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await TransportService.endTrip(
      tripId: _tripId,
      totalDistanceKm: _distanceKm,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip completed successfully. Final summary saved.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final nextStop = _currentStopIndex < _stops.length ? _stops[_currentStopIndex] : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488),
        elevation: 0,
        title: Text(
          'Live Route Navigator',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_rounded, color: Colors.amberAccent),
            tooltip: 'Report Incident',
            onPressed: _showReportIncidentDialog,
          ),
          10.w.horizontalSpace,
        ],
      ),
      body: Column(
        children: [
          // GPS Live Pulse Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            color: const Color(0xFF0F172A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Color(0xFF10B981), blurRadius: 6)],
                      ),
                    ),
                    8.w.horizontalSpace,
                    Text(
                      'GPS TRACKING ACTIVE',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Queued: ${TransportService.queuedPointsCount} pts',
                  style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Speedometer & Distance HUD Card
          Container(
            padding: EdgeInsets.all(18.r),
            color: AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('CURRENT SPEED', style: TextStyle(fontSize: 10.sp, color: Colors.white70, fontWeight: FontWeight.w700)),
                    4.h.verticalSpace,
                    Text(
                      '${_speedKmh.toInt()}',
                      style: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1),
                    ),
                    Text('km/h', style: TextStyle(fontSize: 11.sp, color: Colors.white70)),
                  ],
                ),
                Container(width: 1, height: 50.h, color: Colors.white24),
                Column(
                  children: [
                    Text('DISTANCE', style: TextStyle(fontSize: 10.sp, color: Colors.white70, fontWeight: FontWeight.w700)),
                    4.h.verticalSpace,
                    Text(
                      _distanceKm.toStringAsFixed(1),
                      style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                    ),
                    Text('km traveled', style: TextStyle(fontSize: 11.sp, color: Colors.white70)),
                  ],
                ),
                Container(width: 1, height: 50.h, color: Colors.white24),
                Column(
                  children: [
                    Text('TIME ELAPSED', style: TextStyle(fontSize: 10.sp, color: Colors.white70, fontWeight: FontWeight.w700)),
                    4.h.verticalSpace,
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                    ),
                    Text('duration', style: TextStyle(fontSize: 11.sp, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),

          // Next Stop ETA Banner
          if (nextStop != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border(bottom: BorderSide(color: Colors.amber.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me_rounded, color: Colors.amber, size: 20),
                  10.w.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UPCOMING GEOFENCE STOP', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.amber.shade900)),
                        Text(
                          nextStop['stopName']?.toString() ?? 'Next Stop',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text('ETA ~5 min', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.amber.shade900)),
                  ),
                ],
              ),
            ),

          // Stops List Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Route Stops (${_stops.length})',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  '$_busNumber • $_routeName',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // Stops List View
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
              physics: const BouncingScrollPhysics(),
              itemCount: _stops.length,
              separatorBuilder: (_, _) => 10.h.verticalSpace,
              itemBuilder: (context, index) {
                final stop = _stops[index];
                final status = stop['status']?.toString() ?? 'PENDING';
                final isCurrent = index == _currentStopIndex;

                Color statusColor = Colors.grey;
                if (status == 'ARRIVED') statusColor = Colors.blue;
                if (status == 'DEPARTED') statusColor = Colors.green;

                return GlassCard(
                  padding: EdgeInsets.all(14.r),
                  child: Row(
                    children: [
                      Container(
                        width: 28.r,
                        height: 28.r,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w800, color: statusColor),
                          ),
                        ),
                      ),
                      12.w.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop['stopName']?.toString() ?? 'Stop',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            2.h.verticalSpace,
                            Text(
                              'Planned: ${stop['plannedMorningPickupTime'] ?? 'N/A'} • ${stop['students'] ?? 0} students',
                              style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (status == 'PENDING')
                        ElevatedButton(
                          onPressed: () => _handleStopAction(index, 'ARRIVED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: const Text('Arrived', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                        )
                      else if (status == 'ARRIVED')
                        ElevatedButton(
                          onPressed: () => _handleStopAction(index, 'DEPARTED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: const Text('Depart', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                        )
                      else
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Action Bar: End Trip
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showReportIncidentDialog,
                    icon: const Icon(Icons.report_problem_rounded, color: AppColors.error, size: 18),
                    label: const Text('Report Issue', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                12.w.horizontalSpace,
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleEndTrip,
                    icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 20),
                    label: const Text('Complete Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
