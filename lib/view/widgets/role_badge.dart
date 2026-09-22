import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (role) {
      case UserRole.student:
        color = AppColors.primary;
        bgColor = AppColors.primary.withOpacity(0.12);
        label = 'Student';
        break;
      case UserRole.parent:
        color = AppColors.success;
        bgColor = AppColors.success.withOpacity(0.12);
        label = 'Parent';
        break;
      case UserRole.teacher:
        color = AppColors.info;
        bgColor = AppColors.info.withOpacity(0.12);
        label = 'Teacher';
        break;
      case UserRole.staff:
      case UserRole.admin:
      case UserRole.masterAdmin:
        color = AppColors.warning;
        bgColor = AppColors.warning.withOpacity(0.12);
        label = role == UserRole.masterAdmin
            ? 'Master Admin'
            : (role == UserRole.admin ? 'Admin' : 'Staff');
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
