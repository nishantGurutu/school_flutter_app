import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_desk_app/config/color/app_color.dart';
import 'package:school_desk_app/utils/extensions/general_ectensions.dart';
import 'package:school_desk_app/utils/extensions/text_extension.dart';

class HomeBottomNavBarItem {
  final String label;
  final IconData icon;
  final bool isCenter;

  const HomeBottomNavBarItem({
    required this.label,
    required this.icon,
    this.isCenter = false,
  });
}

class HomeBottomNavBar extends StatelessWidget {
  final List<HomeBottomNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 10.h + safe),
      child: Container(
        height: 66.h,
        decoration: BoxDecoration(
          color: AppColors.navSurface,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.navBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final item = items[i];
            if (item.isCenter) {
              final selected = currentIndex == i;
              return _CenterNavButton(
                selected: selected,
                icon: item.icon,
                onPressed: () => onTap(i),
              );
            }

            final selected = currentIndex == i;
            return _NavItemButton(
              selected: selected,
              icon: item.icon,
              label: item.label,
              onPressed: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _NavItemButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentPurple : AppColors.navIconMuted;
    return InkResponse(
      onTap: onPressed,
      radius: 28.r,
      child: SizedBox(
        width: 62.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22.sp),
            4.h.height,
            Text(
              label,
              style: context.text(
                size: 10,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final VoidCallback onPressed;

  const _CenterNavButton({
    required this.selected,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: AppColors.purpleGlowGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withOpacity(0.45),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 26.sp),
        ),
      ),
    );
  }
}
