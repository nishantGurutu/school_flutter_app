import '../../../services/driver_location_gate.dart';
import '../../../location_tracking/data/datasources/location_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../location_tracking/presentation/bloc/location_tracking_bloc.dart';
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
  bool _syncing = false;
  List<Map<String, Object?>> _pendingTrips = [];
  Map<String, dynamic>? _dutyData;

  // Pre-Trip Vehicle Checklist (loaded dynamically from Transport API / Admin Config)
  List<Map<String, dynamic>> _safetyChecklist = [];
  final Map<int, bool> _checkedItems = {};

  List<Map<String, dynamic>> get _requiredItems => _safetyChecklist
      .where((item) => (item['required'] == true || item['isRequired'] == true))
      .toList();

  int get _totalRequiredCount => _requiredItems.length;

  int get _checkedRequiredCount => _requiredItems
      .where(
        (item) => _checkedItems[(item['id'] ?? item.hashCode) as int] == true,
      )
      .length;

  int get _totalCheckedCount => _safetyChecklist
      .where(
        (item) => _checkedItems[(item['id'] ?? item.hashCode) as int] == true,
      )
      .length;

  bool get _isChecklistComplete {
    if (_requiredItems.isEmpty) {
      return _totalCheckedCount == _safetyChecklist.length;
    }
    return _requiredItems.every(
      (item) => _checkedItems[(item['id'] ?? item.hashCode) as int] == true,
    );
  }

  bool get _isLicenseVerified {
    if (_dutyData?['licenseVerified'] != null) {
      return _dutyData!['licenseVerified'] == true;
    }
    if (_dutyData?['driverLicense'] is Map) {
      final lic = _dutyData!['driverLicense'] as Map;
      return lic['isVerified'] == true ||
          lic['verificationStatus'] == 'VERIFIED';
    }
    return _dutyData?['verificationStatus'] == 'VERIFIED';
  }

  String get _licenseNumber {
    if (_dutyData?['driverLicense'] is Map &&
        _dutyData!['driverLicense']['licenseNumber'] != null) {
      return _dutyData!['driverLicense']['licenseNumber'].toString();
    }
    return _dutyData?['licenseNumber']?.toString() ?? 'DL-DRI-7398';
  }

  String get _licenseExpiryDate {
    if (_dutyData?['driverLicense'] is Map &&
        _dutyData!['driverLicense']['licenseExpiryDate'] != null) {
      return _dutyData!['driverLicense']['licenseExpiryDate'].toString();
    }
    return _dutyData?['licenseExpiryDate']?.toString() ?? '2031-10-21';
  }

  @override
  void initState() {
    super.initState();
    _loadPendingTrips();
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

    final rawList = data['safetyChecklist'] ?? data['safetyList'];
    if (rawList is List) {
      _safetyChecklist = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final activeIds = _safetyChecklist
          .map((item) => (item['id'] ?? item.hashCode) as int)
          .toSet();
      _checkedItems.removeWhere((id, _) => !activeIds.contains(id));
    }

    final isTripInProgress = data['tripStatus'] == 'IN_PROGRESS';
    final isChecklistDone =
        data['todayChecklistCompleted'] == true || isTripInProgress;
    if (isChecklistDone) {
      for (final item in _safetyChecklist) {
        final key = (item['id'] ?? item.hashCode) as int;
        _checkedItems[key] = true;
      }
    }
  }

  Future<void> _loadDuty() async {
    setState(() => _isLoading = true);
    final data = await TransportService.getDriverDuty(email: widget.user.email);
    await _loadPendingTrips();
    if (mounted) {
      setState(() {
        _dutyData = data;
        _applyDutyChecklistState(data);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingTrips() async {
    if (widget.user.role != UserRole.driver) return;
    try {
      final pending = await LocationService.store.pending(widget.user.email);
      if (mounted) setState(() => _pendingTrips = pending);
    } catch (_) {
      /* Storage is unavailable on unsupported platforms. */
    }
  }

  Future<void> _retryPendingTrips() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      if (!await DriverLocationGate.ensureReady(context) || !mounted) return;
      for (final trip in _pendingTrips) {
        await TransportService.endTrip(tripId: trip['trip_id'] as int);
      }
      await _loadPendingTrips();
      await _loadDuty();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Trip data remains on this phone. Retry when online: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _toggleVerifyAll() {
    final target = !_isChecklistComplete;
    setState(() {
      for (final item in _safetyChecklist) {
        final key = (item['id'] ?? item.hashCode) as int;
        _checkedItems[key] = target;
      }
    });
  }

  Future<void> _handleEndTrip() async {
    if (_isStarting || widget.user.role != UserRole.driver) return;
    final tripId = (_dutyData?['activeTripId'] as num?)?.toInt();
    if (tripId == null) return;
    setState(() => _isStarting = true);
    try {
      if (!await DriverLocationGate.ensureReady(context) || !mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Complete Transport Trip?'),
          content: const Text(
            'Stop background GPS and save this trip route to school records?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Resume Trip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Complete Trip'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      if (!mounted ||
          !await DriverLocationGate.ensureReady(context) ||
          !mounted) {
        return;
      }
      await TransportService.endTrip(tripId: tripId);
      if (!mounted) return;
      context.read<LocationTrackingBloc>().add(
        const LocationTrackingStatusRequested(),
      );
      await _loadDuty();
    } catch (error) {
      if (!mounted) return;
      context.read<LocationTrackingBloc>().add(
        const LocationTrackingStatusRequested(),
      );
      await _loadPendingTrips();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trip save failed. GPS data stays on this phone. Retry End Trip: $error',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _handleStartTrip() async {
    if (_isStarting || widget.user.role != UserRole.driver) return;
    if (_dutyData?['tripStatus'] == 'IN_PROGRESS') return;

    if (_dutyData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Duty data is loading or offline. Pull down to refresh.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_dutyData?['busId'] == null || _dutyData?['routeId'] == null) {
      final missing =
          (_dutyData?['busId'] == null && _dutyData?['routeId'] == null)
          ? 'Bus and Route'
          : (_dutyData?['busId'] == null ? 'Bus' : 'Route');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
              8.w.horizontalSpace,
              const Text('Duty Not Assigned'),
            ],
          ),
          content: Text(
            'Cannot start trip because no $missing has been assigned to your driver account.\n\n'
            'Please ask your school transport administrator to assign a Bus and Route to your profile from the Transport Management dashboard.',
            style: TextStyle(fontSize: 13.sp, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_pendingTrips.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_pendingTrips.length} offline trip(s) pending save. Tap "Retry save" above before starting a new trip.',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!_isChecklistComplete) {
      final missingRequired = _requiredItems
          .where(
            (item) =>
                _checkedItems[(item['id'] ?? item.hashCode) as int] != true,
          )
          .map((item) => item['title'] ?? 'Required Check')
          .toList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle Safety Checklist Incomplete ($_checkedRequiredCount/$_totalRequiredCount mandatory checks verified).\n'
            'Please complete: ${missingRequired.join(', ')}',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isStarting = true);

    if (!await DriverLocationGate.ensureReady(context) || !mounted) {
      if (mounted) setState(() => _isStarting = false);
      return;
    }

    // Capture real-time GPS location
    double? startLat;
    double? startLon;
    String startLocName = 'Depot Campus Gate';
    try {
      final pos = await LocationTrackingService().getCurrentPosition();
      if (pos != null) {
        startLat = pos.latitude;
        startLon = pos.longitude;
        startLocName =
            'GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      }
    } catch (_) {}

    if (!mounted) return;
    if (startLat == null || startLon == null) {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enable location permission and GPS before starting your trip.',
          ),
        ),
      );
      return;
    }

    final routeName = _dutyData?['routeName'] ?? 'No route assigned';
    final busNumber = _dutyData?['busNumber'] ?? 'No bus assigned';
    final plannedTime = _dutyData?['plannedDepartureTime'] ?? '07:15 AM';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
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
              'All $_checkedRequiredCount mandatory pre-trip safety checklist items are verified OK.',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
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
                  Text(
                    '• Bus: $busNumber',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.h.verticalSpace,
                  Text(
                    '• Route: $routeName',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.h.verticalSpace,
                  Text(
                    '• Planned Departure: $plannedTime',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  4.h.verticalSpace,
                  Text(
                    '• Start Location: $startLocName',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                  ),
                  4.h.verticalSpace,
                  Text(
                    '• Start Time: ${TimeOfDay.now().format(context)}',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            12.h.verticalSpace,
            Text(
              'GPS tracking starts after departure is confirmed. Trip history is saved locally until you complete the trip.',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: const Text(
              'Start Trip Now',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) {
      setState(() => _isStarting = false);
      return;
    }

    final routeId = (_dutyData?['routeId'] as num?)?.toInt();
    final busId = (_dutyData?['busId'] as num?)?.toInt();
    if (routeId == null || busId == null) {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No valid bus and route assignment. Refresh your duty.',
          ),
        ),
      );
      return;
    }

    if (!await DriverLocationGate.ensureReady(context) || !mounted) {
      if (mounted) setState(() => _isStarting = false);
      return;
    }
    final res = await TransportService.startTrip(
      routeId: routeId,
      busId: busId,
      driverEmail: widget.user.email,
      shift: _dutyData?['shift']?.toString() ?? 'MORNING',
      startLat: startLat,
      startLon: startLon,
      startLocationName: startLocName,
      chkBrakes: true,
      chkLights: true,
      chkTires: true,
      chkEmergencyKit: true,
      chkGpsActive: true,
      preTripCheckPassed: true,
      preTripNotes:
          'Safety checklist verified ($_checkedRequiredCount/$_totalRequiredCount required checks) by ${widget.user.name}. Departure recorded at $startLocName.',
    );

    if (!mounted) return;
    final tripId = (res?['tripId'] as num?)?.toInt();
    if (tripId == null || res?['status'] != 'IN_PROGRESS') {
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Trip could not be started. Tracking has not started. Please retry.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _dutyData?['tripStatus'] = 'IN_PROGRESS';
      _dutyData?['activeTripId'] = tripId;
    });
    try {
      await LocationService.store.begin(tripId, widget.user.email);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isStarting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trip started, but local recording could not start: $error',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isStarting = false);

    Navigator.pushNamed(
      context,
      RoutesName.activeTrip,
      arguments: {
        'duty': _dutyData,
        'trip': res,
        'driverEmail': widget.user.email,
      },
    ).then((_) => _loadDuty());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final busNumber = _dutyData?['busNumber']?.toString() ?? 'No bus assigned';
    final regNo = _dutyData?['registrationNumber']?.toString() ?? '—';
    final routeName =
        _dutyData?['routeName']?.toString() ?? 'No route assigned';
    final plannedTime =
        _dutyData?['plannedDepartureTime']?.toString() ?? '07:15 AM';
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
              style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
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
              if (_pendingTrips.isNotEmpty) ...[
                Card(
                  child: ListTile(
                    title: Text('${_pendingTrips.length} trip save pending'),
                    subtitle: const Text(
                      'GPS history is safely stored on this phone. Retry to finish syncing.',
                    ),
                    trailing: TextButton(
                      onPressed: _syncing ? null : _retryPendingTrips,
                      child: Text(_syncing ? 'Saving…' : 'Retry save'),
                    ),
                  ),
                ),
                12.h.verticalSpace,
              ],
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
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
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
                              'trip': {'tripId': _dutyData?['activeTripId']},
                              'driverEmail': widget.user.email,
                            },
                          ).then((_) => _loadDuty());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0D9488),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: const Text(
                          'Resume',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
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
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: const Icon(
                                  Icons.directions_bus_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
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
                              Text(
                                'Vehicle',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              4.h.verticalSpace,
                              Text(
                                busNumber,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                regNo,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Departure',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              4.h.verticalSpace,
                              Text(
                                plannedTime,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'On Schedule',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    14.h.verticalSpace,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned Route',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textMuted,
                          ),
                        ),
                        4.h.verticalSpace,
                        Text(
                          routeName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (_dutyData?['busId'] == null ||
                        _dutyData?['routeId'] == null) ...[
                      14.h.verticalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            8.w.horizontalSpace,
                            Expanded(
                              child: Text(
                                _dutyData?['busId'] == null &&
                                        _dutyData?['routeId'] == null
                                    ? 'No Bus or Route assigned by admin. Please contact school transport manager.'
                                    : (_dutyData?['busId'] == null
                                          ? 'No Bus assigned yet. Contact transport manager.'
                                          : 'No Route assigned yet. Contact transport manager.'),
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFB91C1C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              20.h.verticalSpace,

              // Pre-Trip Vehicle Inspection Checklist Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _isChecklistComplete
                              ? AppColors.success.withValues(alpha: 0.15)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _isChecklistComplete
                              ? '$_totalCheckedCount / ${_safetyChecklist.length} Verified'
                              : '$_checkedRequiredCount / $_totalRequiredCount Required',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: _isChecklistComplete
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: isTripInProgress ? null : _toggleVerifyAll,
                    icon: Icon(
                      _isChecklistComplete
                          ? Icons.restart_alt_rounded
                          : Icons.checklist_rounded,
                      size: 14.sp,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      _isChecklistComplete ? 'Reset' : 'Check All',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
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
                    if (_safetyChecklist.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        child: Center(
                          child: Text(
                            'No vehicle safety checklist items configured.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      for (int i = 0; i < _safetyChecklist.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 40),
                        _buildChecklistTile(
                          _safetyChecklist[i],
                          isTripInProgress,
                        ),
                      ],
                  ],
                ),
              ),
              22.h.verticalSpace,

              // Start or complete the assigned trip.
              ElevatedButton(
                key: const Key('driver-trip-action'),
                onPressed: _isStarting || _syncing
                    ? null
                    : isTripInProgress
                    ? _handleEndTrip
                    : _handleStartTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTripInProgress
                      ? const Color(0xFF0D9488)
                      : (_dutyData?['busId'] == null ||
                            _dutyData?['routeId'] == null)
                      ? const Color(0xFF64748B)
                      : (_isChecklistComplete
                            ? AppColors.primary
                            : const Color(0xFFF59E0B)),
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
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          ),
                          12.w.horizontalSpace,
                          Flexible(
                            child: Text(
                              isTripInProgress
                                  ? 'Saving Trip…'
                                  : 'Acquiring Location & Starting Trip...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isTripInProgress
                                ? Icons.stop_circle_outlined
                                : (_dutyData?['busId'] == null ||
                                      _dutyData?['routeId'] == null)
                                ? Icons.info_outline_rounded
                                : (_isChecklistComplete
                                      ? Icons.play_circle_fill_rounded
                                      : Icons.pending_actions_rounded),
                            color: Colors.white,
                            size: 24,
                          ),
                          10.w.horizontalSpace,
                          Flexible(
                            child: Text(
                              isTripInProgress
                                  ? 'End Trip'
                                  : (_dutyData?['busId'] == null ||
                                        _dutyData?['routeId'] == null)
                                  ? 'No Bus/Route Assigned (Tap Info)'
                                  : (_isChecklistComplete
                                        ? 'Start Scheduled Trip'
                                        : 'Verify Required Checks ($_checkedRequiredCount/$_totalRequiredCount)'),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              24.h.verticalSpace,

              // Quick Info Card: Driver License Verification
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isLicenseVerified
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _isLicenseVerified
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isLicenseVerified
                          ? Icons.verified_user_rounded
                          : Icons.warning_amber_rounded,
                      color: _isLicenseVerified
                          ? AppColors.primary
                          : const Color(0xFFD97706),
                      size: 22,
                    ),
                    12.w.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _isLicenseVerified
                                    ? 'Driver License Verified'
                                    : 'Driver License: Verification Pending',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _isLicenseVerified
                                      ? AppColors.textPrimary
                                      : const Color(0xFFB45309),
                                ),
                              ),
                              6.w.horizontalSpace,
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 1.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _isLicenseVerified
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  _isLicenseVerified ? 'VERIFIED' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    color: _isLicenseVerified
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          4.h.verticalSpace,
                          Text(
                            'License: $_licenseNumber  •  Valid through $_licenseExpiryDate',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
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

  IconData _getChecklistIcon(String? iconKey) {
    switch (iconKey?.toLowerCase()) {
      case 'speed':
      case 'brakes':
        return Icons.speed_rounded;
      case 'light':
      case 'lights':
        return Icons.light_mode_rounded;
      case 'tire':
      case 'tires':
        return Icons.tire_repair_rounded;
      case 'medical':
      case 'firstaid':
        return Icons.medical_services_rounded;
      case 'gps':
      case 'location':
        return Icons.gps_fixed_rounded;
      case 'camera':
        return Icons.videocam_rounded;
      default:
        return Icons.verified_user_rounded;
    }
  }

  Widget _buildChecklistTile(Map<String, dynamic> item, bool isTripInProgress) {
    final itemId = (item['id'] ?? item.hashCode) as int;
    final isChecked = _checkedItems[itemId] ?? false;
    final isReq = (item['required'] == true || item['isRequired'] == true);
    final title = item['title']?.toString() ?? 'Safety Check';
    final description = item['description']?.toString() ?? '';
    final iconKey = item['iconKey']?.toString();

    return CheckboxListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (isReq) ...[
            4.w.horizontalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                'Required',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ] else ...[
            4.w.horizontalSpace,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: description.isNotEmpty
          ? Text(
              description,
              style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted),
            )
          : null,
      value: isChecked,
      activeColor: isReq ? AppColors.primary : const Color(0xFF0D9488),
      dense: true,
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        padding: EdgeInsets.all(6.r),
        decoration: BoxDecoration(
          color: (isReq ? AppColors.primary : const Color(0xFF0D9488))
              .withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getChecklistIcon(iconKey),
          size: 16.sp,
          color: isReq ? AppColors.primary : const Color(0xFF0D9488),
        ),
      ),
      onChanged: isTripInProgress
          ? null
          : (v) => setState(() => _checkedItems[itemId] = v ?? false),
    );
  }
}
