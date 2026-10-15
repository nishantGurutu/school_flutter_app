import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/transport_service.dart';
import '../../../widgets/glass_card.dart';

class ParentTransportScreen extends StatefulWidget {
  final int? studentId;

  const ParentTransportScreen({super.key, this.studentId});

  @override
  State<ParentTransportScreen> createState() => _ParentTransportScreenState();
}

class _ParentTransportScreenState extends State<ParentTransportScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  GoogleMapController? _mapController;
  Timer? _pollingTimer;

  // Map state
  LatLng _busLocation = const LatLng(25.6025, 85.1430);
  LatLng _stopLocation = const LatLng(25.6100, 85.1350);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadTransport();
    // Auto refresh bus position every 6 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _loadTransport(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadTransport({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    final res = await TransportService.getParentChildTransport(widget.studentId ?? 1);
    if (!mounted) return;

    setState(() {
      _data = res;
      _isLoading = false;

      final busLat = (res?['currentLatitude'] as num?)?.toDouble() ?? 25.6025;
      final busLon = (res?['currentLongitude'] as num?)?.toDouble() ?? 85.1430;
      final stopLat = (res?['stopLatitude'] as num?)?.toDouble() ?? 25.6100;
      final stopLon = (res?['stopLongitude'] as num?)?.toDouble() ?? 85.1350;

      _busLocation = LatLng(busLat, busLon);
      _stopLocation = LatLng(stopLat, stopLon);
      _updateMapLayers();
    });
  }

  void _updateMapLayers() {
    _markers.clear();
    _polylines.clear();

    final busNumber = _data?['busNumber'] ?? 'Bus 04';
    final speed = (_data?['busSpeedKmh'] as num?)?.toDouble() ?? 32.0;
    final stopName = _data?['stopName'] ?? 'Metro Station Pillar 42';

    // Bus Marker
    _markers.add(
      Marker(
        markerId: const MarkerId('parent_bus_marker'),
        position: _busLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(
          title: '$busNumber • En Route',
          snippet: 'Speed: ${speed.toInt()} km/h | ETA: ${_data?['estimatedArrivalMinutes'] ?? 6} mins',
        ),
      ),
    );

    // Designated Child Stop Marker
    _markers.add(
      Marker(
        markerId: const MarkerId('child_stop_marker'),
        position: _stopLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Designated Stop: $stopName',
          snippet: 'Pickup: ${_data?['scheduledPickupTime'] ?? '07:25 AM'}',
        ),
      ),
    );

    // Connecting Route Polyline
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_path'),
        points: [_busLocation, _stopLocation],
        color: const Color(0xFF0D9488),
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    final south = _busLocation.latitude < _stopLocation.latitude ? _busLocation.latitude : _stopLocation.latitude;
    final north = _busLocation.latitude > _stopLocation.latitude ? _busLocation.latitude : _stopLocation.latitude;
    final west = _busLocation.longitude < _stopLocation.longitude ? _busLocation.longitude : _stopLocation.longitude;
    final east = _busLocation.longitude > _stopLocation.longitude ? _busLocation.longitude : _stopLocation.longitude;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south - 0.005, west - 0.005),
          northeast: LatLng(north + 0.005, east + 0.005),
        ),
        60,
      ),
    );
  }

  void _callDriver(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final studentName = _data?['studentName'] ?? 'Child';
    final busNumber = _data?['busNumber'] ?? 'Bus 04';
    final routeName = _data?['routeName'] ?? 'Route 1 - North Campus Loop';
    final stopName = _data?['stopName'] ?? 'Metro Station Pillar 42';
    final pickupTime = _data?['scheduledPickupTime'] ?? '07:25 AM';
    final pickupStatus = _data?['pickupStatus'] ?? 'PICKED_UP';
    final driverName = _data?['driverName'] ?? 'Ramesh Kumar';
    final driverPhone = _data?['driverPhone'] ?? '+91 98765 43210';
    final speed = (_data?['busSpeedKmh'] as num?)?.toDouble() ?? 32.0;
    final eta = _data?['estimatedArrivalMinutes'] ?? 6;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Live Bus Tracking',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => _loadTransport(),
          ),
          8.w.horizontalSpace,
        ],
      ),
      body: Column(
        children: [
          // Live Google Map View
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _busLocation,
                    zoom: 14.5,
                  ),
                  onMapCreated: (ctrl) {
                    _mapController = ctrl;
                    _fitMapBounds();
                  },
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),

                // Live Floating Status Chip
                Positioned(
                  top: 14.h,
                  left: 14.w,
                  right: 14.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
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
                              'EN ROUTE • $studentName',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '$busNumber',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recenter & Fit Camera FAB
                Positioned(
                  bottom: 14.h,
                  right: 14.w,
                  child: FloatingActionButton.small(
                    heroTag: 'parent_recenter',
                    onPressed: _fitMapBounds,
                    backgroundColor: const Color(0xFF0D9488),
                    child: const Icon(Icons.crop_free_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Lower ETA & Driver Info Panel
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ETA Gradient Card
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Arrival at Your Stop',
                              style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Status: $pickupStatus',
                                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        4.h.verticalSpace,
                        Text(
                          '~ $eta Minutes',
                          style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        10.h.verticalSpace,
                        const Divider(color: Colors.white24, height: 1),
                        10.h.verticalSpace,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Live GPS Speed: ${speed.toInt()} km/h',
                              style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                            ),
                            Text(
                              'Pickup: $pickupTime',
                              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  14.h.verticalSpace,

                  // Designated Stop Card
                  GlassCard(
                    padding: EdgeInsets.all(14.r),
                    child: Row(
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Color(0xFF0D9488), size: 22),
                        ),
                        12.w.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Child Stop: $stopName', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              2.h.verticalSpace,
                              Text(routeName, style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  14.h.verticalSpace,

                  // Driver Quick Call Card
                  GlassCard(
                    padding: EdgeInsets.all(14.r),
                    child: Row(
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF0D9488), size: 22),
                        ),
                        12.w.horizontalSpace,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(driverName, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              2.h.verticalSpace,
                              Text('Assigned Bus Driver • $driverPhone', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0D9488)),
                          onPressed: () => _callDriver(driverPhone),
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
