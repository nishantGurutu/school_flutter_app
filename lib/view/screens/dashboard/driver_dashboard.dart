import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/routes_name.dart';
import '../../../services/transport_service.dart';
import '../../widgets/glass_card.dart';

class DriverDashboard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onOpenDrawer;
  final Map<String, dynamic>? initialDuty;

  const DriverDashboard({
    super.key,
    required this.user,
    required this.onOpenDrawer,
    this.initialDuty,
  });

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _dutyData;

  // Pre-Trip Vehicle Checklist
  bool _chkBrakes = true;
  bool _chkLights = true;
  bool _chkTires = true;
  bool _chkEmergencyKit = true;
  bool _chkGpsActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialDuty != null) {
      _dutyData = widget.initialDuty;
      _isLoading = false;
    } else {
      _loadDuty();
    }
  }

  Future<void> _loadDuty() async {
    setState(() => _isLoading = true);
    final data = await TransportService.getDriverDuty(email: widget.user.email);
    if (mounted) {
      setState(() {
        _dutyData = data;
        _isLoading = false;
      });
    }
  }

  bool get _isChecklistComplete =>
      _chkBrakes && _chkLights && _chkTires && _chkEmergencyKit && _chkGpsActive;

  void _handleStartTrip() async {
    if (!_isChecklistComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify all pre-trip checklist items before departure.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Transport Trip?'),
        content: Text(
          'Bus ${_dutyData?['busNumber'] ?? 'Bus 04'} will begin active GPS tracking for ${_dutyData?['routeName'] ?? 'Route 1'}. School Desk admin and parents will receive live updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm Departure', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final routeId = _dutyData?['routeId'] is int ? _dutyData!['routeId'] as int : 1;
    final busId = _dutyData?['busId'] is int ? _dutyData!['busId'] as int : 3;

    final res = await TransportService.startTrip(
      routeId: routeId,
      busId: busId,
      shift: _dutyData?['shift']?.toString() ?? 'MORNING',
      email: widget.user.email,
    );

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      RoutesName.activeTrip,
      arguments: {
        'duty': _dutyData,
        'trip': res,
      },
    ).then((_) => _loadDuty());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final busNumber = _dutyData?['busNumber']?.toString() ?? 'Bus 04';
    final regNo = _dutyData?['registrationNumber']?.toString() ?? 'MH-02-EF-4004';
    final routeName = _dutyData?['routeName']?.toString() ?? 'Route 1 - North Campus Loop';
    final plannedTime = _dutyData?['plannedDepartureTime']?.toString() ?? '07:15 AM';
    final shift = _dutyData?['shift']?.toString() ?? 'MORNING';
    final isTripInProgress = _dutyData?['tripStatus'] == 'IN_PROGRESS';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
          onPressed: widget.onOpenDrawer,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Companion',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Safe Route Navigator • ${widget.user.name}',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadDuty,
          ),
          12.w.horizontalSpace,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDuty,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            top: 12.h,
            bottom: 120.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Active Trip Banner if running
            if (isTripInProgress) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                    ),
                    14.w.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRIP CURRENTLY ACTIVE',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.8,
                            ),
                          ),
                          4.h.verticalSpace,
                          Text(
                            '$busNumber • $routeName',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RoutesName.activeTrip,
                          arguments: {
                            'duty': _dutyData,
                            'trip': {'tripId': _dutyData?['activeTripId'] ?? 1},
                          },
                        ).then((_) => _loadDuty());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0D9488),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                      child: const Text('Resume', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              20.h.verticalSpace,
            ],

            // Step 2: My Duty Card
            GlassCard(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 20),
                            ),
                            10.w.horizontalSpace,
                            Flexible(
                              child: Text(
                                'Today\'s Assigned Duty',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      8.w.horizontalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          shift,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  16.h.verticalSpace,
                  const Divider(height: 1),
                  14.h.verticalSpace,

                  // Duty Details Grid
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vehicle', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                            4.h.verticalSpace,
                            Text(busNumber, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            Text(regNo, style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Departure', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                            4.h.verticalSpace,
                            Text(plannedTime, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            Text('On Schedule', style: TextStyle(fontSize: 11.sp, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  14.h.verticalSpace,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned Route', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
                      4.h.verticalSpace,
                      Text(
                        routeName,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            20.h.verticalSpace,

            // Pre-Trip Vehicle Inspection Checklist
            Text(
              'Pre-Trip Vehicle Safety Checklist',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            8.h.verticalSpace,
            GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Brakes, Steering & Horn OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: _chkBrakes,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _chkBrakes = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Headlights, Indicators & Mirrors OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: _chkLights,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _chkLights = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Tire Pressure & Fuel / Fluids OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: _chkTires,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _chkTires = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('First Aid Kit & Fire Extinguisher Checked', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: _chkEmergencyKit,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _chkEmergencyKit = v ?? false),
                  ),
                  CheckboxListTile(
                    title: const Text('Driver Phone GPS Location Enabled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: _chkGpsActive,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _chkGpsActive = v ?? false),
                  ),
                ],
              ),
            ),
            24.h.verticalSpace,

            // Start Trip Button
            ElevatedButton(
              onPressed: isTripInProgress ? null : _handleStartTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade400,
                elevation: 4,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                  10.w.horizontalSpace,
                  Text(
                    isTripInProgress ? 'Trip Already In Progress' : 'Start Scheduled Trip',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            24.h.verticalSpace,

            // Quick Info Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                  12.w.horizontalSpace,
                  Expanded(
                    child: Text(
                      'Driver License verified: ${_dutyData?['licenseNumber'] ?? 'DL-0420110056789'}\nValid through ${_dutyData?['licenseExpiryDate'] ?? '2029-06-30'}',
                      style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            30.h.verticalSpace,
          ],
        ),
      ),
    ),
    );
  }
}
