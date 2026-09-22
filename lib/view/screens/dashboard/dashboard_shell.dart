import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_desk_app/data/models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../drawer/custom_drawer.dart';
import 'student_dashboard.dart';
import 'parent_dashboard.dart';
import 'teacher_dashboard.dart';
import 'staff_dashboard.dart';
import '../modules/notice_screen.dart';
import '../modules/chat_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 1. Resolve role-based Home Dashboard layout (Polymorphism / OCP)
        Widget homeDashboard;
        switch (user.role) {
          case UserRole.student:
            homeDashboard = StudentDashboard(
              user: user,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            );
            break;
          case UserRole.parent:
            homeDashboard = ParentDashboard(
              user: user,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            );
            break;
          case UserRole.teacher:
            homeDashboard = TeacherDashboard(
              user: user,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            );
            break;
          case UserRole.staff:
          case UserRole.admin:
          case UserRole.masterAdmin:
            homeDashboard = StaffDashboard(
              user: user,
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
            );
            break;
        }

        // 2. Define pages for standard tabs
        final List<Widget> pages = [
          homeDashboard,
          const NoticeScreen(isInline: true),
          const ChatScreen(isInline: true),
          _ProfileTabScreen(
            user: user,
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ];

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: const CustomDrawer(),
          extendBody: true,
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: _FloatingBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}

// Floating Bottom Nav Bar Widget
class _FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
      height: 70.h,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _BottomNavItem(
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            label: 'Notices',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _BottomNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Chats',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 24.sp,
              ),
            ),
            4.h.height,
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Tab Inline Screen
class _ProfileTabScreen extends StatelessWidget {
  final UserModel user;
  final VoidCallback onOpenDrawer;

  const _ProfileTabScreen({required this.user, required this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: AppColors.textPrimary,
            size: 24.sp,
          ),
          onPressed: onOpenDrawer,
        ),
        title: Text(
          'My Profile',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            20.h.height,
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 110.w,
                    height: 110.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                      image: DecorationImage(
                        image: NetworkImage(user.avatarUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
            20.h.height,
            Text(user.name, style: context.h1),
            6.h.height,
            Text(user.details, style: context.caption),
            30.h.height,

            // Detail Fields
            _ProfileInfoCard(
              title: 'Email Address',
              value: user.email,
              icon: Icons.email_outlined,
            ),
            12.h.height,
            _ProfileInfoCard(
              title: 'System Access Role',
              value: user.roleDisplayName,
              icon: Icons.verified_user_outlined,
            ),
            12.h.height,
            _ProfileInfoCard(
              title: 'Mobile Phone Number',
              value: '+91 98765 43210',
              icon: Icons.phone_android_outlined,
            ),
            12.h.height,
            _ProfileInfoCard(
              title: 'Current Status',
              value: 'Active / Authorized',
              icon: Icons.check_circle_outline_rounded,
            ),

            120.h.height, // Spacer for floating nav bar
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ProfileInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22.sp),
          16.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                4.h.height,
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
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
