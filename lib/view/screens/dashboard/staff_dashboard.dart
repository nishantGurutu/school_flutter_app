import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/school_models.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_state.dart';
import '../../widgets/glass_card.dart';

class StaffDashboard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onOpenDrawer;

  const StaffDashboard({
    super.key,
    required this.user,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 5.h),
            Padding(
              padding: EdgeInsets.only(left: 10.w, right: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 26.sp),
                    onPressed: onOpenDrawer,
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Hello, ${user.name} 👋',
                            style: context.h2.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            user.roleDisplayName,
                            style: context.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      12.w.width,
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.warning, width: 1.5),
                          image: DecorationImage(
                            image: NetworkImage(user.avatarUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            10.h.height,
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin Task Overview Header Card
                    GlassCard(
                      padding: EdgeInsets.all(18.w),
                      borderColor: AppColors.warning.withOpacity(0.3),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.task_alt_outlined, color: AppColors.warning, size: 24.sp),
                          ),
                          16.w.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Admin Tasks",
                                  style: context.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                4.h.height,
                                Text(
                                  "5 Action Items Pending",
                                  style: context.h2.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    24.h.height,

                    // School Attendance Tracking Card (Admin / Staff Feature)
                    Text(
                      'School Attendance Tracking',
                      style: context.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                    12.h.height,
                    BlocBuilder<SchoolBloc, SchoolState>(
                      builder: (context, state) {
                        final stats = state.attendanceStats ??
                            const AttendanceStats(
                              totalStudents: 450,
                              presentStudents: 418,
                              absentStudents: 32,
                              studentPercentage: 92.8,
                              totalStaff: 45,
                              presentStaff: 42,
                              absentStaff: 3,
                              staffPercentage: 93.3,
                              overallPercentage: 93.0,
                              classBreakdown: [
                                ClassAttendanceStat(className: 'Class 10-A', total: 40, present: 38, absent: 2, percentage: 95.0),
                                ClassAttendanceStat(className: 'Class 10-B', total: 42, present: 39, absent: 3, percentage: 92.8),
                                ClassAttendanceStat(className: 'Class 9-A', total: 38, present: 36, absent: 2, percentage: 94.7),
                                ClassAttendanceStat(className: 'Class 9-B', total: 45, present: 41, absent: 4, percentage: 91.1),
                              ],
                              date: 'Today',
                            );

                        return Container(
                          padding: EdgeInsets.all(18.w),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: AppColors.border, width: 1.2),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 60.w,
                                    height: 60.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.success, width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${stats.overallPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  16.w.width,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Overall School Attendance Rate',
                                          style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp, fontWeight: FontWeight.w600),
                                        ),
                                        4.h.height,
                                        Text(
                                          '${stats.presentStudents + stats.presentStaff} Present / ${(stats.absentStudents + stats.absentStaff)} Absent',
                                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              16.h.height,
                              const Divider(color: AppColors.border, height: 1),
                              16.h.height,
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatSubBox(
                                      label: 'Student Present Rate',
                                      value: '${stats.studentPercentage}%',
                                      subText: '${stats.presentStudents}/${stats.totalStudents} Present',
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  12.w.width,
                                  Expanded(
                                    child: _StatSubBox(
                                      label: 'Staff Present Rate',
                                      value: '${stats.staffPercentage}%',
                                      subText: '${stats.presentStaff}/${stats.totalStaff} Present',
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                              16.h.height,
                              // Class breakdown preview
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: stats.classBreakdown.take(3).map((item) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 80.w,
                                          child: Text(
                                            item.className,
                                            style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4.r),
                                            child: LinearProgressIndicator(
                                              value: item.percentage / 100.0,
                                              backgroundColor: AppColors.border,
                                              color: item.percentage >= 95 ? AppColors.success : (item.percentage >= 90 ? AppColors.primary : AppColors.warning),
                                              minHeight: 6.h,
                                            ),
                                          ),
                                        ),
                                        12.w.width,
                                        Text(
                                          '${item.percentage}%',
                                          style: TextStyle(fontSize: 11.sp, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              12.h.height,
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                      ),
                                      icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.primary),
                                      label: Text('Mark Attendance', style: TextStyle(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      onPressed: () => Navigator.pushNamed(context, RoutesName.attendance),
                                    ),
                                  ),
                                  12.w.width,
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                      ),
                                      icon: const Icon(Icons.insights_rounded, size: 16, color: Colors.white),
                                      label: Text('View Analytics', style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                                      onPressed: () => Navigator.pushNamed(context, RoutesName.attendance),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    24.h.height,

                    Text(
                      'Quick Access',
                      style: context.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                    14.h.height,
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 14.w,
                      mainAxisSpacing: 14.h,
                      childAspectRatio: 0.95,
                      children: [
                        _QuickAccessTile(
                          label: 'Attendance',
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.success,
                          onTap: () => Navigator.pushNamed(context, RoutesName.attendance),
                        ),
                        _QuickAccessTile(
                          label: 'Leave Approv.',
                          icon: Icons.assignment_turned_in_outlined,
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, RoutesName.leave),
                        ),
                        _QuickAccessTile(
                          label: 'Expenses',
                          icon: Icons.payments_outlined,
                          color: AppColors.error,
                          onTap: () => Navigator.pushNamed(context, RoutesName.expense),
                        ),
                        _QuickAccessTile(
                          label: 'Payroll',
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.warning,
                          onTap: () => Navigator.pushNamed(context, RoutesName.payroll),
                        ),
                        _QuickAccessTile(
                          label: 'Documents',
                          icon: Icons.folder_shared_outlined,
                          color: AppColors.info,
                          onTap: () => context.showAppSnackBar('Document database loaded.'),
                        ),
                        _QuickAccessTile(
                          label: 'Notice',
                          icon: Icons.campaign_outlined,
                          color: AppColors.secondary,
                          onTap: () => Navigator.pushNamed(context, RoutesName.notice),
                        ),
                      ],
                    ),
                    24.h.height,
                    Text(
                      'Action Queue',
                      style: context.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                    12.h.height,
                    _ActionItemRow(
                      title: 'Verify Leave Requests',
                      subtitle: 'Ms. Priya applied for 10th June • 1 day',
                      status: 'Verify',
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(context, RoutesName.leave),
                    ),
                    10.h.height,
                    _ActionItemRow(
                      title: 'Library Expenses Approval',
                      subtitle: '₹5,400 bill for purchase of math books',
                      status: 'Approve',
                      color: AppColors.success,
                      onTap: () => Navigator.pushNamed(context, RoutesName.expense),
                    ),
                    10.h.height,
                    _ActionItemRow(
                      title: 'Verify Transport Logs',
                      subtitle: 'Daily fuel receipt audit Route 4',
                      status: 'Audit',
                      color: AppColors.info,
                      onTap: () => context.showAppSnackBar('Fuel logs marked audited. No discrepancies found.'),
                    ),
                    100.h.height, // Spacer for floating nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatSubBox extends StatelessWidget {
  final String label;
  final String value;
  final String subText;
  final Color color;

  const _StatSubBox({
    required this.label,
    required this.value,
    required this.subText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.sp, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          4.h.height,
          Text(value, style: TextStyle(fontSize: 16.sp, color: color, fontWeight: FontWeight.bold)),
          2.h.height,
          Text(subText, style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            10.h.height,
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItemRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final VoidCallback onTap;

  const _ActionItemRow({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                4.h.height,
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          10.w.width,
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
