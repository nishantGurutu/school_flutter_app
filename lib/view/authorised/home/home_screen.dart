import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:school_desk_app/config/color/app_color.dart';
import 'package:school_desk_app/utils/extensions/general_ectensions.dart';
import 'package:school_desk_app/utils/extensions/text_extension.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 110.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              10.h.height,
              const _HomeTopBar(),
              14.h.height,
              const _HomeSearchBar(),
              16.h.height,
              const _QuickActionsGrid(),
              20.h.height,
              Text(
                'Discover Services',
                style: context.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              14.h.height,
              const _DiscoverGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LogoMark(),
        10.w.width,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Location',
                style: context.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              2.h.height,
              Row(
                children: [
                  Text(
                    'Select Location',
                    style: context.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  4.w.width,
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 18.sp,
                  ),
                ],
              ),
            ],
          ),
        ),
        _PillButton(text: 'Login', onTap: () {}),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        color: AppColors.surface2,
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: context.h2.copyWith(
          color: AppColors.accentPurple,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _PillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: context.bodySmall.copyWith(
            color: AppColors.accentPurple,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52.h,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          14.w.width,
          Icon(Icons.search_rounded, color: AppColors.textMuted, size: 22.sp),
          10.w.width,
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: context.body.copyWith(color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: 'Search for '),
                  TextSpan(
                    text: 'Salons',
                    style: context.body.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.mic_none_rounded,
            color: AppColors.accentPurple,
            size: 22.sp,
          ),
          12.w.width,
          Container(width: 1, height: 24.h, color: AppColors.border),
          12.w.width,
          Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 22.sp),
          14.w.width,
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _actions = <_QuickAction>[
    _QuickAction('City Explore', Icons.location_on_outlined),
    _QuickAction('Intercity Cab', Icons.directions_car_rounded),
    _QuickAction('Food Order', Icons.restaurant_rounded),
    _QuickAction('Graapes Services', Icons.bolt_rounded),
    _QuickAction('Hotel', Icons.apartment_rounded),
    _QuickAction('City Shopping', Icons.shopping_bag_outlined),
    _QuickAction('Health', Icons.local_hospital_outlined),
    _QuickAction('More', Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 12.w,
        // Need more height for icon + 2-line label (prevents overflow)
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, i) {
        final a = _actions[i];
        return _QuickActionTile(title: a.title, icon: a.icon, onTap: () {});
      },
    );
  }
}

class _QuickAction {
  final String title;
  final IconData icon;
  const _QuickAction(this.title, this.icon);
}

class _QuickActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.accentPurple, size: 22.sp),
          ),
          6.h.height,
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text(
              size: 11,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DiscoverGrid extends StatelessWidget {
  const _DiscoverGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14.w,
      mainAxisSpacing: 14.h,
      childAspectRatio: 1.12,
      children: const [
        _DiscoverCard(
          title: 'Beauty & Salon',
          subtitle: 'Hair, Skin & Grooming',
          icon: Icons.content_cut_rounded,
        ),
        _DiscoverCard(
          title: 'Gym & Fitness',
          subtitle: 'Workout, Training & Fitness',
          icon: Icons.fitness_center_rounded,
        ),
        _DiscoverCard(
          title: 'Education',
          subtitle: 'Academics & Job Portal',
          icon: Icons.school_rounded,
        ),
        _DiscoverCard(
          title: 'Real Estate',
          subtitle: 'Buy, Sell & Rent',
          icon: Icons.house_rounded,
        ),
      ],
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DiscoverCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10.w,
              top: 10.h,
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: AppColors.surface2,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.accentPurple, size: 18.sp),
              ),
            ),
            Positioned(
              left: 12.w,
              right: 12.w,
              bottom: 12.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  4.h.height,
                  Text(
                    subtitle,
                    style: context.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
