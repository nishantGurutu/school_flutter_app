import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_event.dart';
import '../../widgets/smooth_skeleton.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/attendance_check_in_banner.dart';
import '../../widgets/student_more_bottom_sheet.dart';
import '../modules/subject_curriculum_screen.dart';
import '../modules/topics_screen.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel? user;
  final VoidCallback? onOpenDrawer;
  final bool isParentViewing;
  final String? studentAdmissionNo;
  final String? overrideStudentName;
  final String? overrideClassName;
  final String? overrideAvatarUrl;

  const StudentDashboard({
    super.key,
    this.user,
    this.onOpenDrawer,
    this.isParentViewing = false,
    this.studentAdmissionNo,
    this.overrideStudentName,
    this.overrideClassName,
    this.overrideAvatarUrl,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  HomeDashboardResponse? _dashboardData;
  bool _isLoading = true;
  int _activeBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final u = widget.user;
        context.read<SchoolBloc>().add(
          FetchAttendanceRequested(
            userId: u?.id ?? '1',
            className: u?.className,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _fetchHomeData() async {
    setState(() => _isLoading = true);
    final u = widget.user;
    if (mounted) {
      context.read<SchoolBloc>().add(
        FetchAttendanceRequested(userId: u?.id ?? '1', className: u?.className),
      );
    }
    final data = await _repository.getHomeDashboard(
      admissionNo: widget.studentAdmissionNo,
    );
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
      _startBannerAutoScroll();
    }
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    final count = _dashboardData?.banners.length ?? 0;
    if (count > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_bannerController.hasClients) {
          final nextIndex = (_activeBannerIndex + 1) % count;
          _bannerController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dashboardData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: widget.isParentViewing
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: widget.onOpenDrawer,
                ),
          title: Text(
            'Student Companion',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Column(
              children: [
                SmoothShimmer(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 84.h,
                    borderRadius: 16,
                  ),
                ),
                16.h.height,
                SmoothShimmer(
                  child: SkeletonBox(
                    width: double.infinity,
                    height: 160.h,
                    borderRadius: 20,
                  ),
                ),
                20.h.height,
                const SmoothSkeletonCardList(
                  count: 3,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _dashboardData;
    final profile = data?.profile;
    final config = data?.sectionsConfig ?? SectionsConfig();

    final displayName =
        widget.overrideStudentName ??
        (profile != null && profile.name.isNotEmpty
            ? profile.name
            : (widget.user?.name ?? 'Kauan Sousa'));
    final displayClass =
        widget.overrideClassName ??
        (profile != null && profile.className.isNotEmpty
            ? profile.className
            : (widget.user?.className ?? 'Class : 10 - A English'));
    final displayRoll = profile != null && profile.rollNo.isNotEmpty
        ? profile.rollNo
        : '31';
    final displayAvatar =
        widget.overrideAvatarUrl ??
        (profile != null && profile.avatarUrl.isNotEmpty
            ? profile.avatarUrl
            : (widget.user?.avatarUrl ??
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.isParentViewing
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: widget.onOpenDrawer,
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Companion',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$displayClass • $displayName',
              style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
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
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchHomeData,
          ),
          12.w.horizontalSpace,
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchHomeData,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.only(
                top: 8.h,
                bottom: widget.isParentViewing ? 100.h : 24.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Student Profile GlassCard
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: _buildStudentProfileCard(
                      name: displayName,
                      className: displayClass,
                      rollNo: displayRoll,
                      avatarUrl: displayAvatar,
                    ),
                  ),
                  18.h.height,

                  // 2. Daily Student Attendance Check-In Banner
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: AttendanceCheckInBanner(
                      user:
                          widget.user ??
                          UserModel(
                            id: '1',
                            name: displayName,
                            email: 'student@school.com',
                            role: UserRole.student,
                            className: displayClass,
                            avatarUrl: displayAvatar,
                            details: '$displayClass | Roll: $displayRoll',
                          ),
                    ),
                  ),
                  20.h.height,

                  // 3. Promotional Banners Slider
                  if (config.showBanners &&
                      (data?.banners.isNotEmpty ?? false)) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _buildBannerCarousel(data!.banners),
                    ),
                    24.h.height,
                  ],

                  // 3. My Subjects Section
                  if (config.showSubjects &&
                      (data?.subjects.isNotEmpty ?? false)) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        'My Subjects',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    8.h.height,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _buildSubjectsGrid(data!.subjects),
                    ),
                    6.h.height,
                  ],

                  // 4. Latest Notices Section
                  if (config.showLatestNotices &&
                      (data?.latestNotices.isNotEmpty ?? false)) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Latest notices',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, RoutesName.notice),
                            child: Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    12.h.height,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: data!.latestNotices
                            .map((n) => _buildNoticeCard(n))
                            .toList(),
                      ),
                    ),
                    26.h.height,
                  ],

                  if (config.showGallery &&
                      (data?.gallery.isNotEmpty ?? false)) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gallery',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              RoutesName.gallery,
                              arguments: data!.gallery,
                            ),
                            child: Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    14.h.height,
                    _buildGalleryHorizontalList(data!.gallery),
                    120.h.height,
                  ],
                ],
              ),
            ),
          ),

          // Floating 3-Tab Bottom Navigation Bar (Only when parent views student standalone)
          if (widget.isParentViewing)
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 20.h,
              child: _buildFloatingBottomNavBar(),
            ),
        ],
      ),
    );
  }

  // 1. Student Profile GlassCard matching Driver UI design
  Widget _buildStudentProfileCard({
    required String name,
    required String className,
    required String rollNo,
    required String avatarUrl,
  }) {
    String classText = className;
    if (!classText.toLowerCase().contains('class')) {
      classText = 'Class : $classText';
    }
    final subtitle = '$classText | Roll No : $rollNo';

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
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 28.sp,
                  ),
                ),
              ),
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
                  subtitle,
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
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'STUDENT',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Promotional Banners Slider
  Widget _buildBannerCarousel(List<DashboardBanner> banners) {
    return Column(
      children: [
        SizedBox(
          height: 165.h,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (idx) => setState(() => _activeBannerIndex = idx),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final b = banners[index];
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFBBF24,
                  ), // Vibrant warm mustard yellow matching screenshot 1
                  borderRadius: BorderRadius.circular(22.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
                  child: Stack(
                    children: [
                      // Background graphics / doodles
                      Positioned(
                        right: -20.w,
                        bottom: -30.h,
                        child: Container(
                          width: 170.w,
                          height: 170.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 14.h,
                        ),
                        child: Row(
                          children: [
                            // Left Text & Badges
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Logo row
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.school_rounded,
                                        color: const Color(0xFF1E293B),
                                        size: 16.sp,
                                      ),
                                      6.w.width,
                                      Text(
                                        'eSchool',
                                        style: TextStyle(
                                          color: const Color(0xFF1E293B),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  6.h.height,

                                  // Heading
                                  Text(
                                    b.title,
                                    style: TextStyle(
                                      color: const Color(0xFF1E293B),
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w900,
                                      height: 1.15,
                                    ),
                                  ),
                                  8.h.height,

                                  // Badges
                                  Wrap(
                                    spacing: 6.w,
                                    runSpacing: 4.h,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                        ),
                                        child: Text(
                                          'Online Registration',
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 3.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                        ),
                                        child: Text(
                                          b.buttonText,
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Right Image
                            Expanded(
                              flex: 4,
                              child: Image.network(
                                b.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.menu_book_rounded,
                                  size: 60.sp,
                                  color: const Color(
                                    0xFF1E293B,
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        10.h.height,

        // Page Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (idx) {
            final isActive = _activeBannerIndex == idx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isActive ? 14.w : 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 3. My Subjects 3-Column Vibrant Grid (Screenshot 1)
  Widget _buildSubjectsGrid(List<DashboardSubject> subjects) {
    final List<List<DashboardSubject>> rows = [];
    for (int i = 0; i < subjects.length; i += 3) {
      final end = (i + 3 > subjects.length) ? subjects.length : i + 3;
      rows.add(subjects.sublist(i, end));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r < rows.length; r++) ...[
          if (r > 0) 10.h.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final sub in rows[r])
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: _buildSubjectItem(sub),
                  ),
                ),
              for (int s = 0; s < 3 - rows[r].length; s++)
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubjectItem(DashboardSubject sub) {
    final gradient = _resolveSubjectGradient(
      sub.name,
      sub.colorHex,
      sub.secondaryColorHex,
    );
    final iconWidget = _resolveSubjectIcon(sub.name, sub.code);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectCurriculumScreen(
              subjectId: sub.id.toString(),
              subjectName: sub.name,
              subjectCode: sub.code,
              colorHex: sub.colorHex,
              secondaryColorHex: sub.secondaryColorHex,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Equal Square Vibrant Rounded Tile (Compact & Uniform)
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: iconWidget),
          ),

          6.h.height,

          // Subject Label with uniform height (equal alignment for 1 or 2 lines)
          SizedBox(
            height: 30.h,
            child: Text(
              '(${sub.name})',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _resolveSubjectGradient(
    String name,
    String hex1,
    String hex2,
  ) {
    final lower = name.toLowerCase();
    if (lower.contains('english')) {
      return const LinearGradient(
        colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (lower.contains('math')) {
      return const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (lower.contains('science')) {
      return const LinearGradient(
        colors: [Color(0xFF84CC16), Color(0xFF65A30D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (lower.contains('physical')) {
      return const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (lower.contains('hindi')) {
      return const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (lower.contains('music')) {
      return const LinearGradient(
        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    try {
      final c1 = Color(int.parse(hex1.replaceFirst('#', '0xFF')));
      final c2 = Color(int.parse(hex2.replaceFirst('#', '0xFF')));
      return LinearGradient(
        colors: [c1, c2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } catch (_) {
      return const LinearGradient(
        colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
      );
    }
  }

  Widget _resolveSubjectIcon(String name, String code) {
    final lower = name.toLowerCase();
    if (lower.contains('english')) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          'EN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14.sp,
          ),
        ),
      );
    } else if (lower.contains('math')) {
      return Text(
        '√',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 26.sp,
        ),
      );
    } else if (lower.contains('science')) {
      return Icon(Icons.science_rounded, color: Colors.white, size: 28.sp);
    } else if (lower.contains('physical')) {
      return Icon(
        Icons.sports_cricket_rounded,
        color: Colors.white,
        size: 26.sp,
      );
    } else if (lower.contains('hindi')) {
      return Text(
        'क',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24.sp,
        ),
      );
    } else if (lower.contains('music')) {
      return Icon(Icons.music_note_rounded, color: Colors.white, size: 26.sp);
    }
    return Icon(Icons.menu_book_rounded, color: Colors.white, size: 26.sp);
  }

  // 4. Latest Notices Card (Screenshot 2)
  Widget _buildNoticeCard(DashboardNotice notice) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notice.title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          4.h.height,
          Text(
            notice.description,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
          ),

          // Attachment Chip if present (matching screenshot 2)
          if (notice.attachmentName != null &&
              notice.attachmentName!.isNotEmpty) ...[
            12.h.height,
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      notice.attachmentName!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  8.w.width,
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],

          8.h.height,
          Text(
            notice.date,
            style: TextStyle(
              fontSize: 10.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 5. School Gallery Horizontal List (Screenshot 2)
  Widget _buildGalleryHorizontalList(List<DashboardGalleryAlbum> albums) {
    return SizedBox(
      height: 175.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: albums.length,
        separatorBuilder: (_, _) => 14.w.width,
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              RoutesName.gallery,
              arguments: albums,
            ),
            child: SizedBox(
              width: 140.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rounded photo thumbnail
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18.r),
                        child: Image.network(
                          album.coverImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFFE2E8F0),
                            child: Icon(
                              Icons.image_outlined,
                              color: const Color(0xFF94A3B8),
                              size: 32.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  8.h.height,

                  // Album Title
                  Text(
                    album.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  2.h.height,

                  // Photo Count
                  Text(
                    '${album.photoCount} Photos',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 6. Floating 3-Tab Bottom Navigation Bar (Screenshots matching user spec)
  Widget _buildFloatingBottomNavBar() {
    return Container(
      height: 62.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Tab (Active)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_rounded, color: AppColors.primary, size: 24.sp),
              2.h.height,
              Text(
                'Home',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // Subjects Tab
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TopicsScreen()),
            ),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: const Color(0xFF64748B),
                  size: 22.sp,
                ),
                2.h.height,
                Text(
                  'Subjects',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Menu / More Tab (Opens More BottomSheet)
          GestureDetector(
            onTap: () {
              final data = _dashboardData;
              final profile = data?.profile;
              final displayName =
                  widget.overrideStudentName ??
                  (profile != null && profile.name.isNotEmpty
                      ? profile.name
                      : (widget.user?.name ?? 'Kauan Sousa'));
              final displayClass =
                  widget.overrideClassName ??
                  (profile != null && profile.className.isNotEmpty
                      ? profile.className
                      : (widget.user?.className ?? 'Class : 10 - A English'));
              final displayRoll = profile != null && profile.rollNo.isNotEmpty
                  ? profile.rollNo
                  : '31';
              final displayAvatar =
                  widget.overrideAvatarUrl ??
                  (profile != null && profile.avatarUrl.isNotEmpty
                      ? profile.avatarUrl
                      : (widget.user?.avatarUrl ??
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80'));

              StudentMoreBottomSheet.show(
                context,
                user: widget.user,
                studentAdmissionNo: widget.studentAdmissionNo,
                overrideName: displayName,
                overrideClass: displayClass,
                overrideRollNo: displayRoll,
                overrideAvatar: displayAvatar,
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  color: const Color(0xFF64748B),
                  size: 22.sp,
                ),
                2.h.height,
                Text(
                  'Menu',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
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
