import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

class SmoothShimmer extends StatefulWidget {
  final Widget child;

  const SmoothShimmer({super.key, required this.child});

  @override
  State<SmoothShimmer> createState() => _SmoothShimmerState();
}

class _SmoothShimmerState extends State<SmoothShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.06),
                Colors.white.withOpacity(0.24),
                Colors.white.withOpacity(0.06),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(borderRadius.r),
      ),
    );
  }
}

class SmoothSkeletonCardList extends StatelessWidget {
  final int count;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const SmoothSkeletonCardList({
    super.key,
    this.count = 4,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final listPadding = padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h);

    if (shrinkWrap) {
      return SmoothShimmer(
        child: Padding(
          padding: listPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              count,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 14.h),
                child: _buildItem(context, index),
              ),
            ),
          ),
        ),
      );
    }

    return SmoothShimmer(
      child: ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: listPadding,
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(height: 14.h),
        itemBuilder: _buildItem,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 80.w, height: 22.h, borderRadius: 12),
              SkeletonBox(width: 60.w, height: 16.h, borderRadius: 6),
            ],
          ),
          SizedBox(height: 12.h),
          SkeletonBox(width: double.infinity, height: 18.h, borderRadius: 6),
          SizedBox(height: 8.h),
          SkeletonBox(width: 220.w, height: 14.h, borderRadius: 6),
          SizedBox(height: 14.h),
          Row(
            children: [
              SkeletonBox(width: 14.w, height: 14.h, borderRadius: 4),
              SizedBox(width: 8.w),
              SkeletonBox(width: 100.w, height: 12.h, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}
