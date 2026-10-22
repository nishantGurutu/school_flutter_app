import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../widgets/smooth_skeleton.dart';
import '../../widgets/glass_card.dart';
import 'student_dashboard.dart';

class ParentDashboard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onOpenDrawer;

  const ParentDashboard({
    super.key,
    required this.user,
    required this.onOpenDrawer,
  });

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  HomeDashboardResponse? _homeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchParentHomeData();
  }

  Future<void> _fetchParentHomeData() async {
    setState(() => _isLoading = true);
    final data = await _repository.getHomeDashboard();
    if (mounted) {
      setState(() {
        _homeData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _homeData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
            onPressed: widget.onOpenDrawer,
          ),
          title: Text(
            'Parent Companion',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmoothShimmer(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 84.h,
                    borderRadius: 16,
                  ),
                ),
                20.h.height,
                SmoothShimmer(
                  child: SkeletonBox(width: 140.w, height: 24.h),
                ),
                20.h.height,
                Row(
                  children: [
                    Expanded(
                      child: SmoothShimmer(
                        child: SkeletonBox(
                          width: double.infinity,
                          height: 180.h,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                    16.w.width,
                    Expanded(
                      child: SmoothShimmer(
                        child: SkeletonBox(
                          width: double.infinity,
                          height: 180.h,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _homeData;
    final profile = data?.profile;
    final parentName = (profile != null && profile.name.isNotEmpty) ? profile.name : widget.user.name;
    final parentEmail = (profile != null && profile.email.isNotEmpty) ? profile.email : widget.user.email;
    final parentAvatar = (profile != null && profile.avatarUrl.isNotEmpty) ? profile.avatarUrl : widget.user.avatarUrl;

    final children = data?.children ?? <DashboardChild>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
          onPressed: widget.onOpenDrawer,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parent Companion',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Family Care • $parentName',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pushNamed(context, RoutesName.chat),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () => context.showAppSnackBar('Opening Parent Account Settings...'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchParentHomeData,
          ),
          12.w.horizontalSpace,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchParentHomeData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.only(top: 8.h, bottom: 40.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Parent Profile GlassCard
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildParentProfileCard(
                  name: parentName,
                  email: parentEmail,
                  avatarUrl: parentAvatar,
                ),
              ),

              24.h.height,

              // 2. "My Children" Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'My Children',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              16.h.height,

              if (children.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Text(
                    'No children linked to this account. Contact your school administrator.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Wrap(
                    spacing: 16.w,
                    runSpacing: 22.h,
                    children: children.map((child) => _buildChildCard(child)).toList(),
                  ),
                ),

              40.h.height,
            ],
          ),
        ),
      ),
    );
  }

  // 1. Parent Profile GlassCard matching Driver UI design
  Widget _buildParentProfileCard({
    required String name,
    required String email,
    required String avatarUrl,
  }) {
    return GlassCard(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
          ),
          14.w.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.h.verticalSpace,
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'PARENT',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      child: Center(
        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 28.sp),
      ),
    );
  }

  // 2. Child Card matching Driver UI design
  Widget _buildChildCard(DashboardChild child) {
    return GestureDetector(
      onTap: () => _openChildStudentHome(child),
      child: Container(
        width: 156.w,
        height: 180.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Child Photo
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        child.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 28.sp,
                          ),
                        ),
                      ),
                    ),
                  ),

                  12.h.height,

                  // Child Name
                  Text(
                    child.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  4.h.height,

                  // Class Name
                  Text(
                    child.className,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Forward Arrow Button at Bottom Center of Card
            Positioned(
              bottom: -14.h,
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 13.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Opens the selected child's full Student Home Screen!
  void _openChildStudentHome(DashboardChild child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboard(
          isParentViewing: true,
          studentAdmissionNo: child.admissionNo,
          overrideStudentName: child.name,
          overrideClassName: child.className,
          overrideAvatarUrl: child.avatarUrl,
          onOpenDrawer: widget.onOpenDrawer,
        ),
      ),
    );
  }

}

