import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/transport_service.dart';
import '../../../widgets/glass_card.dart';

class StudentTransportScreen extends StatefulWidget {
  const StudentTransportScreen({super.key});

  @override
  State<StudentTransportScreen> createState() => _StudentTransportScreenState();
}

class _StudentTransportScreenState extends State<StudentTransportScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _transportData;
  GoogleMapController? _mapController;
  Timer? _refreshTimer;

  // Map state
  LatLng _busLocation = const LatLng(25.6025, 85.1430);
  LatLng _stopLocation = const LatLng(25.6100, 85.1350);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 8 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) => _loadData(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final data = await TransportService.getParentChildTransport(1);
    if (!mounted) return;

    setState(() {
      _transportData = data;
      _isLoading = false;

      // Extract coordinates if present
      final busLat = (data?['currentLatitude'] as num?)?.toDouble() ?? 25.6025;
      final busLon = (data?['currentLongitude'] as num?)?.toDouble() ?? 85.1430;
      final stopLat = (data?['stopLatitude'] as num?)?.toDouble() ?? 25.6100;
      final stopLon = (data?['stopLongitude'] as num?)?.toDouble() ?? 85.1350;

      _busLocation = LatLng(busLat, busLon);
      _stopLocation = LatLng(stopLat, stopLon);
      _updateMapOverlays();
    });
  }

  void _updateMapOverlays() {
    _markers.clear();
    _polylines.clear();

    // Bus Marker
    _markers.add(
      Marker(
        markerId: const MarkerId('school_bus'),
        position: _busLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(
          title: _transportData?['busNumber'] ?? 'School Bus 04',
          snippet: 'Speed: ${(_transportData?['busSpeedKmh'] ?? 30).toInt()} km/h',
        ),
      ),
    );

    // Student Stop Marker
    _markers.add(
      Marker(
        markerId: const MarkerId('student_stop'),
        position: _stopLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: _transportData?['stopName'] ?? 'Your Stop: Metro Pillar 42',
          snippet: 'Scheduled: ${_transportData?['scheduledPickupTime'] ?? '07:25 AM'}',
        ),
      ),
    );

    // Route connecting bus and stop
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_trail'),
        points: [_busLocation, _stopLocation],
        color: const Color(0xFF0D9488),
        width: 4,
      ),
    );
  }

  void _centerMap() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_busLocation, 14.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final busNumber = _transportData?['busNumber'] ?? 'Bus 04';
    final routeName = _transportData?['routeName'] ?? 'Route 1 - North Campus Loop';
    final stopName = _transportData?['stopName'] ?? 'Metro Station Pillar 42';
    final pickupTime = _transportData?['scheduledPickupTime'] ?? '07:25 AM';
    final dropTime = _transportData?['scheduledDropTime'] ?? '03:20 PM';
    final etaMinutes = _transportData?['estimatedArrivalMinutes'] ?? 6;
    final speed = (_transportData?['busSpeedKmh'] as num?)?.toDouble() ?? 32.0;
    final tripStatus = _transportData?['tripStatus'] ?? 'IN_PROGRESS';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Transport & Bus Tracking',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => _loadData(),
          ),
          8.w.horizontalSpace,
        ],
      ),
      body: Column(
        children: [
          // Interactive Map Box
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _busLocation,
                    zoom: 14.2,
                  ),
                  onMapCreated: (ctrl) {
                    _mapController = ctrl;
                    _centerMap();
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // Live Floating Status Tag
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  right: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10.r,
                              height: 10.r,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            8.w.horizontalSpace,
                            Text(
                              tripStatus == 'IN_PROGRESS' ? 'BUS ON ROUTE' : 'AT DEPOT',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'ETA: ~$etaMinutes Mins',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recenter button
                Positioned(
                  bottom: 16.h,
                  right: 16.w,
                  child: FloatingActionButton.small(
                    heroTag: 'student_center_bus',
                    onPressed: _centerMap,
                    backgroundColor: const Color(0xFF0D9488),
                    child: const Icon(Icons.my_location_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Detail Cards
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Timing & Stop Card
                  GlassCard(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              busNumber,
                              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                '${speed.toInt()} km/h',
                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF0D9488)),
                              ),
                            ),
                          ],
                        ),
                        4.h.verticalSpace,
                        Text(
                          routeName,
                          style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
                        ),
                        12.h.verticalSpace,
                        const Divider(height: 1),
                        12.h.verticalSpace,
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF0D9488), size: 18),
                            8.w.horizontalSpace,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Your Assigned Stop', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                                  Text(stopName, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        10.h.verticalSpace,
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 16),
                                  6.w.horizontalSpace,
                                  Text('Pickup: $pickupTime', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.nights_stay_rounded, color: Colors.indigo, size: 16),
                                  6.w.horizontalSpace,
                                  Text('Drop: $dropTime', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
