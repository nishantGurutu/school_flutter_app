import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/routes_name.dart';
import '../../../services/transport_service.dart';
import '../../../services/location_tracking_service.dart';
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
  bool _isStarting = false;
  Map<String, dynamic>? _dutyData;

  // Pre-Trip Vehicle Checklist (daily driver inspection)
  bool _chkBrakes = false;
  bool _chkLights = false;
  bool _chkTires = false;
  bool _chkEmergencyKit = false;
  bool _chkGpsActive = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDuty != null) {
      _dutyData = widget.initialDuty;
      _applyDutyChecklistState(_dutyData);
      _isLoading = false;
    } else {
      _loadDuty();
    }
  }

  void _applyDutyChecklistState(Map<String, dynamic>? data) {
    if (data == null) return;
    final isTripInProgress = data['tripStatus'] == 'IN_PROGRESS';
    final isChecklistDone = data['todayChecklistCompleted'] == true || isTripInProgress;
    if (isChecklistDone) {
      _chkBrakes = data['todayChkBrakes'] ?? true;
      _chkLights = data['todayChkLights'] ?? true;
      _chkTires = data['todayChkTires'] ?? true;
      _chkEmergencyKit = data['todayChkEmergencyKit'] ?? true;
      _chkGpsActive = data['todayChkGpsActive'] ?? true;
    }
  }

  Future<void> _loadDuty() async {
    setState(() => _isLoading = true);
    final data = await TransportService.getDriverDuty(email: widget.user.email);
    if (mounted) {
      setState(() {
        _dutyData = data;
        _applyDutyChecklistState(data);
        _isLoading = false;
      });
    }
  }

  int get _checkedCount =>
      (_chkBrakes ? 1 : 0) +
      (_chkLights ? 1 : 0) +
      (_chkTires ? 1 : 0) +
      (_chkEmergencyKit ? 1 : 0) +
      (_chkGpsActive ? 1 : 0);

  bool get _isChecklistComplete => _checkedCount == 5;

  void _toggleVerifyAll() {
    final target = !_isChecklistComplete;
    setState(() {
      _chkBrakes = target;
      _chkLights = target;
      _chkTires = target;
      _chkEmergencyKit = target;
      _chkGpsActive = target;
    });
  }

  void _handleStartTrip() async {
    if (!_isChecklistComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Safety Checklist Incomplete ($_checkedCount/5 verified). Please check all 5 vehicle inspection items before departure.',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    // Capture real-time GPS location
    double? startLat;
    double? startLon;
    String startLocName = 'Depot Campus Gate';
    try {
      final pos = await LocationTrackingService().getCurrentPosition();
      if (pos != null) {
        startLat = pos.latitude;
        startLon = pos.longitude;
        startLocName = 'GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }
    } catch (_) {}

    if (!mounted) {
      setState(() => _isStarting = false);
      return;
    }

    final routeName = _dutyData?['routeName'] ?? 'Route 1 - North Campus Loop';
    final busNumber = _dutyData?['busNumber'] ?? 'Bus 04';
    final plannedTime = _dutyData?['plannedDepartureTime'] ?? '07:15 AM';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: AppColors.success),
            8.w.horizontalSpace,
            const Text('Confirm Departure'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All 5 pre-trip safety checklist items are verified OK.',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.success),
            ),
            12.h.verticalSpace,
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Bus: $busNumber', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                  4.h.verticalSpace,
                  Text('• Route: $routeName', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                  4.h.verticalSpace,
                  Text('• Planned Departure: $plannedTime', style: TextStyle(fontSize: 12.sp)),
                  4.h.verticalSpace,
                  Text('• Start Location: $startLocName', style: TextStyle(fontSize: 12.sp, color: AppColors.primary)),
                  4.h.verticalSpace,
                  Text('• Start Time: ${TimeOfDay.now().format(context)}', style: TextStyle(fontSize: 12.sp, color: AppColors.primary)),
                ],
              ),
            ),
            12.h.verticalSpace,
            Text(
              'Active GPS tracking will start immediately. School admin and parents will receive live departure telemetry.',
              style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Start Trip Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      setState(() => _isStarting = false);
      return;
    }

    final routeId = _dutyData?['routeId'] is int ? _dutyData!['routeId'] as int : 1;
    final busId = _dutyData?['busId'] is int ? _dutyData!['busId'] as int : 3;

    final res = await TransportService.startTrip(
      routeId: routeId,
      busId: busId,
      shift: _dutyData?['shift']?.toString() ?? 'MORNING',
      startLat: startLat,
      startLon: startLon,
      startLocationName: startLocName,
      chkBrakes: _chkBrakes,
      chkLights: _chkLights,
      chkTires: _chkTires,
      chkEmergencyKit: _chkEmergencyKit,
      chkGpsActive: _chkGpsActive,
      preTripCheckPassed: true,
      preTripNotes: 'All 5 safety checklist items verified by ${widget.user.name}. Departure recorded at $startLocName.',
      email: widget.user.email,
    );

    setState(() => _isStarting = false);

    if (!mounted) return;

    if (res != null) {
      setState(() {
        _dutyData?['tripStatus'] = 'IN_PROGRESS';
        _dutyData?['activeTripId'] = res['tripId'] ?? 1;
      });
    }

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

            // Pre-Trip Vehicle Inspection Checklist Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Vehicle Safety Checklist',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    8.w.horizontalSpace,
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _isChecklistComplete
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '$_checkedCount / 5 Verified',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: _isChecklistComplete ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: isTripInProgress ? null : _toggleVerifyAll,
                  icon: Icon(
                    _isChecklistComplete ? Icons.restart_alt_rounded : Icons.checklist_rounded,
                    size: 14.sp,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _isChecklistComplete ? 'Reset' : 'Check All',
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            6.h.verticalSpace,
            GlassCard(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Brakes, Steering & Horn OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Hydraulics, brake pedal firmness & horn functional', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    value: _chkBrakes,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.speed_rounded, size: 16, color: AppColors.primary),
                    ),
                    onChanged: isTripInProgress ? null : (v) => setState(() => _chkBrakes = v ?? false),
                  ),
                  const Divider(height: 1, indent: 40),
                  CheckboxListTile(
                    title: const Text('Headlights, Indicators & Mirrors OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('High/low beams, rear indicators and side mirrors clean', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    value: _chkLights,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.light_mode_rounded, size: 16, color: AppColors.primary),
                    ),
                    onChanged: isTripInProgress ? null : (v) => setState(() => _chkLights = v ?? false),
                  ),
                  const Divider(height: 1, indent: 40),
                  CheckboxListTile(
                    title: const Text('Tire Pressure & Fuel / Fluids OK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Tire tread condition, coolant, motor oil & fuel tank OK', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    value: _chkTires,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tire_repair_rounded, size: 16, color: AppColors.primary),
                    ),
                    onChanged: isTripInProgress ? null : (v) => setState(() => _chkTires = v ?? false),
                  ),
                  const Divider(height: 1, indent: 40),
                  CheckboxListTile(
                    title: const Text('First Aid Kit & Fire Extinguisher Checked', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Emergency kit stocked and fire cylinder gauge in green', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    value: _chkEmergencyKit,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medical_services_rounded, size: 16, color: AppColors.primary),
                    ),
                    onChanged: isTripInProgress ? null : (v) => setState(() => _chkEmergencyKit = v ?? false),
                  ),
                  const Divider(height: 1, indent: 40),
                  CheckboxListTile(
                    title: const Text('Driver Phone GPS Location Enabled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('High-accuracy GPS active for live parent & admin tracking', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    value: _chkGpsActive,
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gps_fixed_rounded, size: 16, color: AppColors.primary),
                    ),
                    onChanged: isTripInProgress ? null : (v) => setState(() => _chkGpsActive = v ?? false),
                  ),
                ],
              ),
            ),
            22.h.verticalSpace,

            // Start Trip Button
            ElevatedButton(
              onPressed: (isTripInProgress || _isStarting)
                  ? (isTripInProgress
                      ? () {
                          Navigator.pushNamed(
                            context,
                            RoutesName.activeTrip,
                            arguments: {
                              'duty': _dutyData,
                              'trip': {'tripId': _dutyData?['activeTripId'] ?? 1},
                            },
                          ).then((_) => _loadDuty());
                        }
                      : null)
                  : _handleStartTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: isTripInProgress
                    ? const Color(0xFF0D9488)
                    : (_isChecklistComplete ? AppColors.primary : const Color(0xFFF59E0B)),
                foregroundColor: Colors.white,
                elevation: 4,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: _isStarting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        ),
                        12.w.horizontalSpace,
                        Text(
                          'Acquiring Location & Starting Trip...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isTripInProgress
                              ? Icons.navigation_rounded
                              : (_isChecklistComplete ? Icons.play_circle_fill_rounded : Icons.pending_actions_rounded),
                          color: Colors.white,
                          size: 24,
                        ),
                        10.w.horizontalSpace,
                        Text(
                          isTripInProgress
                              ? 'Trip Active • Resume Navigation'
                              : (_isChecklistComplete
                                  ? 'Start Scheduled Trip'
                                  : 'Verify Checklist to Start ($_checkedCount/5)'),
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
