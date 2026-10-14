import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTransport();
  }

  Future<void> _loadTransport() async {
    setState(() => _isLoading = true);
    final res = await TransportService.getParentChildTransport(widget.studentId ?? 1);
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
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
    final speed = _data?['busSpeedKmh'] ?? 32.0;
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
            onPressed: _loadTransport,
          ),
          12.w.horizontalSpace,
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live Status Card
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    blurRadius: 14,
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
                      Row(
                        children: [
                          Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Color(0xFF10B981), blurRadius: 6)],
                            ),
                          ),
                          8.w.horizontalSpace,
                          Text(
                            'BUS EN ROUTE • $studentName',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$busNumber',
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  14.h.verticalSpace,
                  Text(
                    'Estimated Arrival at Your Stop',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                  4.h.verticalSpace,
                  Text(
                    '~ $eta Minutes',
                    style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  14.h.verticalSpace,
                  const Divider(color: Colors.white24, height: 1),
                  12.h.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Speed: ${speed.toInt()} km/h',
                        style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                      ),
                      Text(
                        'Child Status: $pickupStatus',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            20.h.verticalSpace,

            // Stop and Timing Card
            GlassCard(
              padding: EdgeInsets.all(18.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Child Transport Details', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  12.h.verticalSpace,
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      10.w.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Designated Stop', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                            Text(stopName, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  12.h.verticalSpace,
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                      10.w.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scheduled Pickup Time', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                            Text(pickupTime, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  12.h.verticalSpace,
                  Row(
                    children: [
                      const Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 20),
                      10.w.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Route', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                            Text(routeName, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            20.h.verticalSpace,

            // Driver Contact Card
            GlassCard(
              padding: EdgeInsets.all(18.r),
              child: Row(
                children: [
                  Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                  ),
                  14.w.horizontalSpace,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        2.h.verticalSpace,
                        Text('Assigned Bus Driver', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                    onPressed: () => _callDriver(driverPhone),
                  ),
                ],
              ),
            ),
            30.h.verticalSpace,
          ],
        ),
      ),
    );
  }
}
