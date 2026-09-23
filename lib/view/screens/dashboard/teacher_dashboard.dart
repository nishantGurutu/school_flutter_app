import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/attendance_check_in_banner.dart';
import '../../widgets/glass_card.dart';

class TeacherDashboard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onOpenDrawer;

  const TeacherDashboard({
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
        child: Column(children: [SizedBox(height: 5.h,), Padding(padding: EdgeInsets.only(left: 10.w, right: 20.w), child: Row(
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
                            user.className ?? 'Faculty Member',
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
                          border: Border.all(color: AppColors.info, width: 1.5),
                          image: DecorationImage(
                            image: NetworkImage(user.avatarUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),),
              10.h.height,
          Expanded(child:  SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [ 
              // Top Check-In & Attendance Banner
              AttendanceCheckInBanner(user: user),
              24.h.height,

              // Quick Access Title
              Text(
                'Quick Access',
                style: context.h3.copyWith(fontWeight: FontWeight.w800),
              ),
              14.h.height,

              // Quick Access Grid
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
                    label: 'Homework',
                    icon: Icons.add_task_rounded,
                    color: AppColors.primary,
                    onTap: () => Navigator.pushNamed(context, RoutesName.homework),
                  ),
                  _QuickAccessTile(
                    label: 'Add Marks',
                    icon: Icons.post_add_rounded,
                    color: AppColors.warning,
                    onTap: () => context.showAppSnackBar('Grades entry: Math algebra marks ready to push.'),
                  ),
                  _QuickAccessTile(
                    label: 'Notice',
                    icon: Icons.campaign_outlined,
                    color: AppColors.secondary,
                    onTap: () => Navigator.pushNamed(context, RoutesName.notice),
                  ),
                  _QuickAccessTile(
                    label: 'Leave Apply',
                    icon: Icons.leave_bags_at_home_outlined,
                    color: AppColors.error,
                    onTap: () => context.showAppSnackBar('Leave Request: Submitted for approval (10 June).'),
                  ),
                  _QuickAccessTile(
                    label: 'My Classes',
                    icon: Icons.groups_outlined,
                    color: AppColors.info,
                    onTap: () => context.showAppSnackBar('Assigned classes: Class 10-A, Class 9-B, Class 9-A.'),
                  ),
                ],
              ),
              24.h.height,

              // Schedule Timeline Title
              Text(
                "Today's Schedule",
                style: context.h3.copyWith(fontWeight: FontWeight.w800),
              ),
              12.h.height,

              // Timeline List
              _TimelineCard(
                subject: 'Class 9-B (Algebra)',
                time: '09:00 AM - 09:45 AM',
                room: 'Room 8',
                color: AppColors.primary,
              ),
              10.h.height,
              _TimelineCard(
                subject: 'Class 9-A (Geometry)',
                time: '10:00 AM - 10:45 AM',
                room: 'Room 5',
                color: AppColors.info,
              ),
              10.h.height,
              _TimelineCard(
                subject: 'Class 10-B (Trigonometry)',
                time: '11:00 AM - 11:45 AM',
                room: 'Room 12',
                color: AppColors.warning,
              ),
              
              100.h.height, // Spacer for floating nav bar
            ],
          ),
        ),
        ),
        ],),
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

class _TimelineCard extends StatelessWidget {
  final String subject;
  final String time;
  final String room;
  final Color color;

  const _TimelineCard({
    required this.subject,
    required this.time,
    required this.room,
    required this.color,
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
          Container(
            width: 4.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          16.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                4.h.height,
                Text(
                  time,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              room,
              style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
