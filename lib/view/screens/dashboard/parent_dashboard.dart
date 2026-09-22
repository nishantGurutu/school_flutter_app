import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/glass_card.dart';

class ParentDashboard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onOpenDrawer;

  const ParentDashboard({
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
           Padding(padding:  EdgeInsets.only(left: 10.w, right: 20.w), child: Row(
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
                                user.className ?? 'Parent Account',
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
                              border: Border.all(color: AppColors.success, width: 1.5),
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
            Expanded(
              child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [  
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, RoutesName.attendance),
                    child: GlassCard(
                      padding: EdgeInsets.all(18.w),
                      borderColor: AppColors.success.withOpacity(0.3),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 26.sp),
                          ),
                          16.w.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Attendance Status",
                                  style: context.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                                4.h.height,
                                Text(
                                  "Present (100% Rate)",
                                  style: context.h2.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14.sp),
                        ],
                      ),
                    ),
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
                        label: 'Fees',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.error,
                        onTap: () => Navigator.pushNamed(context, RoutesName.fees),
                      ),
                      _QuickAccessTile(
                        label: 'Homework',
                        icon: Icons.assignment_outlined,
                        color: AppColors.primary,
                        onTap: () => Navigator.pushNamed(context, RoutesName.homework),
                      ),
                      _QuickAccessTile(
                        label: 'Results',
                        icon: Icons.grade_outlined,
                        color: AppColors.warning,
                        onTap: () => Navigator.pushNamed(context, RoutesName.exam, arguments: 1),
                      ),
                      _QuickAccessTile(
                        label: 'Bus Tracking',
                        icon: Icons.directions_bus_outlined,
                        color: AppColors.info,
                        onTap: () => context.showAppSnackBar('Live Track: Bus 4 is on its way, currently near Main Square.'),
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
                    'Recent Activity',
                    style: context.h3.copyWith(fontWeight: FontWeight.w800),
                  ),
                  12.h.height, 
                  _ActivityCard(
                    title: 'School Fees Paid Successfully',
                    time: '₹12,450 paid • 20 May 2026',
                    icon: Icons.payment_rounded,
                    color: AppColors.success,
                  ),
                  10.h.height,
                  _ActivityCard(
                    title: 'Maths Homework Completed',
                    time: 'Submitted by Rohan • 19 May 2026',
                    icon: Icons.task_alt_rounded,
                    color: AppColors.primary,
                  ),
                  100.h.height, 
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
                fontSize: 12.sp,
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

class _ActivityCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityCard({
    required this.title,
    required this.time,
    required this.icon,
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
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          16.w.width,
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
                  time,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
