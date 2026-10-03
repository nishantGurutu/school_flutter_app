import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';

import '../../../core/config/role_navigation_config.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) return const SizedBox.shrink();

          final drawerItems = RoleNavigationConfig.getDrawerItems(user.role);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Profile Header
              Container(
                padding: EdgeInsets.only(
                  top: context.topPadding + 20.h,
                  left: 20.w,
                  right: 20.w,
                  bottom: 24.h,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        image: DecorationImage(
                          image: NetworkImage(user.avatarUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    14.h.height,
                    // User name
                    Text(
                      user.name,
                      style: context.h2.copyWith(color: AppColors.textPrimary),
                    ),
                    4.h.height,
                    // Subtitle details
                    Text(
                      user.details,
                      style: context.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer Navigation Items (Dynamic by Role)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Column(
                    children: [
                      _DrawerTile(
                        icon: Icons.home_rounded,
                        label: 'Home Dashboard',
                        onTap: () => Navigator.pop(context),
                      ),
                      ...drawerItems.map(
                        (item) => _DrawerTile(
                          icon: item.icon,
                          label: item.label,
                          onTap: () {
                            Navigator.pop(context);
                            if (item.route.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                item.route,
                                arguments: item.arguments,
                              );
                            }
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Divider(color: AppColors.border, height: 1),
                      ),
                      _DrawerTile(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () {
                          Navigator.pop(context);
                          context.showAppSnackBar(
                            'Support Desk: support@schooldesk.com',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Drawer Footer (Logout)
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Close drawer
                      Navigator.pop(context);
                      // Confirm Dialog
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text('Log Out'),
                          content: const Text(
                            'Are you sure you want to log out of your session?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                context.read<AuthBloc>().add(
                                  const LogoutRequested(),
                                );
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  RoutesName.login,
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                'Log Out',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: const BorderSide(
                        color: AppColors.error,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22.sp),
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 12.w,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 2.h),
      hoverColor: AppColors.primary.withOpacity(0.08),
    );
  }
}
