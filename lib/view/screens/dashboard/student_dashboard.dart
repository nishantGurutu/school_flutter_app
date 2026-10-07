import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../widgets/smooth_skeleton.dart';

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
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _fetchHomeData() async {
    setState(() => _isLoading = true);
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeaderSkeleton(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    children: [
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
            ],
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildCurvedHeader(
            name: displayName,
            className: displayClass,
            rollNo: displayRoll,
            avatarUrl: displayAvatar,
          ),

          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _fetchHomeData,
                  color: const Color(0xFF1E3A5F),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.only(
                      bottom: widget.isParentViewing ? 100.h : 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Curved Deep Blue Top Header (Screenshots 1 & 2)
                        20.h.height,

                        // 2. Promotional Banners Slider
                        if (config.showBanners &&
                            (data?.banners.isNotEmpty ?? false)) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: _buildBannerCarousel(data!.banners),
                          ),
                          24.h.height,
                        ],

                        // 3. My Subjects Section (Screenshot 1: 3-column vibrant grid)
                        if (config.showSubjects &&
                            (data?.subjects.isNotEmpty ?? false)) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Text(
                              'My Subjects',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
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

                        // 4. Latest Notices Section (Screenshot 2)
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
                                    color: const Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    RoutesName.notice,
                                  ),
                                  child: Text(
                                    'View all',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
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

                        // 5. School Gallery Section (Screenshot 2)
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
                                    color: const Color(0xFF1E293B),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.showAppSnackBar(
                                    'Opening School Photo Gallery...',
                                  ),
                                  child: Text(
                                    'View all',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          14.h.height,
                          _buildGalleryHorizontalList(data!.gallery),
                          150.h.height,
                        ],
                      ],
                    ),
                  ),
                ),

                // Floating 3-Tab Bottom Navigation Bar (Screenshots 1 & 2 - Only when parent views student standalone)
                if (widget.isParentViewing)
                  Positioned(
                    left: 20.w,
                    right: 20.w,
                    bottom: 20.h,
                    child: _buildFloatingBottomNavBar(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Curved Blue Top Header
  Widget _buildCurvedHeader({
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(
          0xFF1E3A5F,
        ), // Deep curved petrol/navy blue matching screenshots
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative background concentric circles
            Positioned(
              top: -60.h,
              right: -50.w,
              child: Container(
                width: 200.w,
                height: 200.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -20.h,
              left: 30.w,
              child: Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // Header Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
              child: Row(
                children: [
                  // If viewed by parent -> Back button
                  if (widget.isParentViewing) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        margin: EdgeInsets.only(right: 12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ],

                  // Avatar with thin white circular border
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.9),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF2563EB),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28.sp,
                          ),
                        ),
                      ),
                    ),
                  ),

                  14.w.width,

                  // Student Name & Class Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        4.h.height,
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Chat Message Icon Button on the Right
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, RoutesName.chat),
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 22.sp,
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
                      color: const Color(0xFFFBBF24).withOpacity(0.35),
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
                            color: Colors.white.withOpacity(0.2),
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
                                          color: Colors.white.withOpacity(0.8),
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
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.menu_book_rounded,
                                  size: 60.sp,
                                  color: const Color(
                                    0xFF1E293B,
                                  ).withOpacity(0.4),
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
                color: isActive
                    ? const Color(0xFF1E3A5F)
                    : const Color(0xFFCBD5E1),
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
      onTap: () => context.showAppSnackBar('Opening ${sub.name} curriculum...'),
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
                  color: gradient.colors.first.withOpacity(0.28),
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
            color: Colors.black.withOpacity(0.02),
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
                      color: Color(0xFF1E3A5F),
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
        separatorBuilder: (_, __) => 14.w.width,
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () => context.showAppSnackBar(
              'Opening ${album.title} album (${album.photoCount} photos)...',
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
                            color: Colors.black.withOpacity(0.06),
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
                          errorBuilder: (_, __, ___) => Container(
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

  // 6. Floating 3-Tab Bottom Navigation Bar (Screenshots 1 & 2)
  Widget _buildFloatingBottomNavBar() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              Icon(
                Icons.home_rounded,
                color: const Color(0xFF10B981),
                size: 24.sp,
              ),
              2.h.height,
              Text(
                'Home',
                style: TextStyle(
                  color: const Color(0xFF1E293B),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          // Subjects Tab
          GestureDetector(
            onTap: () =>
                context.showAppSnackBar('Opening all subjects syllabus...'),
            child: Icon(
              Icons.menu_book_rounded,
              color: const Color(0xFF64748B),
              size: 24.sp,
            ),
          ),

          // Menu / Grid Tab
          GestureDetector(
            onTap: () {
              if (widget.onOpenDrawer != null) {
                widget.onOpenDrawer!();
              }
            },
            child: Icon(
              Icons.grid_view_rounded,
              color: const Color(0xFF64748B),
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return SmoothShimmer(
      child: Container(
        width: double.infinity,
        height: 100.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32.r),
            bottomRight: Radius.circular(32.r),
          ),
        ),
      ),
    );
  }
}
