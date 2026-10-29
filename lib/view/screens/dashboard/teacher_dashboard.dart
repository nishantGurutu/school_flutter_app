import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../../core/config/role_navigation_config.dart';
import '../../widgets/smooth_skeleton.dart';
import '../../widgets/attendance_check_in_banner.dart';
import '../../widgets/glass_card.dart';

class TeacherDashboard extends StatefulWidget {
  final UserModel user;
  final VoidCallback onOpenDrawer;

  const TeacherDashboard({
    super.key,
    required this.user,
    required this.onOpenDrawer,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  HomeDashboardResponse? _dashboardData;
  bool _isLoading = true;
  int _activeBannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  // Fallback banners when offline or dashboard response is empty
  static final List<DashboardBanner> _defaultBanners = [
    DashboardBanner(
      id: 1,
      title: 'Faculty Excellence & Academic Portal',
      subtitle: 'Manage classes, attendance & homework seamlessly',
      badge: 'FACULTY',
      buttonText: 'View Guides',
      websiteUrl: 'https://example.com',
      imageUrl: 'https://cdn-icons-png.flaticon.com/512/3429/3429149.png',
    ),
    DashboardBanner(
      id: 2,
      title: 'Admissions & Annual Curriculum 2026',
      subtitle: 'Enrollment updates and syllabus milestones',
      badge: 'CURRICULUM',
      buttonText: 'Explore',
      websiteUrl: 'https://example.com',
      imageUrl: 'https://cdn-icons-png.flaticon.com/512/2997/2997322.png',
    ),
  ];

  // Fallback notices for teacher portal
  static final List<DashboardNotice> _defaultNotices = [
    DashboardNotice(
      id: '1',
      title: 'Term-1 Assessment & Marks Entry',
      description:
          'Please ensure all Class 9 and 10 internal marks and remarks are entered before Friday 5:00 PM.',
      attachmentName: 'exam_marks_guidelines.pdf',
      downloadUrl: 'https://example.com/guidelines.pdf',
      date: '15 Oct 2026',
    ),
    DashboardNotice(
      id: '2',
      title: 'Monthly Staff & Faculty Conference',
      description:
          'All department heads and teaching staff are requested to attend the seminar hall at 3:30 PM.',
      attachmentName: 'meeting_agenda.pdf',
      downloadUrl: 'https://example.com/agenda.pdf',
      date: '14 Oct 2026',
    ),
    DashboardNotice(
      id: '3',
      title: 'Upcoming Parent-Teacher Meeting (PTM)',
      description:
          'PTM for secondary sections scheduled for this Saturday from 9:00 AM to 1:00 PM.',
      attachmentName: '',
      downloadUrl: '',
      date: '12 Oct 2026',
    ),
  ];

  // Fallback gallery albums
  static final List<DashboardGalleryAlbum> _defaultGallery = [
    DashboardGalleryAlbum(
      id: 1,
      title: 'Annual Sports Meet',
      coverImage:
          'https://images.unsplash.com/photo-1577896851231-70ef18881754?w=500&auto=format&fit=crop&q=80',
      photoCount: 24,
    ),
    DashboardGalleryAlbum(
      id: 2,
      title: 'Science Fair 2026',
      coverImage:
          'https://images.unsplash.com/photo-1509062522246-3755977927d7?w=500&auto=format&fit=crop&q=80',
      photoCount: 18,
    ),
    DashboardGalleryAlbum(
      id: 3,
      title: 'Cultural Fest Celebrations',
      coverImage:
          'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=500&auto=format&fit=crop&q=80',
      photoCount: 32,
    ),
  ];

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
    final data = await _repository.getHomeDashboard();
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
    final banners = (_dashboardData?.banners.isNotEmpty ?? false)
        ? _dashboardData!.banners
        : _defaultBanners;
    final count = banners.length;
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
      return _buildLoadingSkeleton();
    }

    final data = _dashboardData;
    final profile = data?.profile;

    final displayName = (profile != null && profile.name.isNotEmpty)
        ? profile.name
        : widget.user.name;

    final displaySubtitle = (profile != null && profile.headerSubtitle.isNotEmpty)
        ? profile.headerSubtitle
        : (widget.user.className?.isNotEmpty == true
            ? widget.user.className!
            : 'Faculty Member • Teacher');

    final displayAvatar = (profile != null && profile.avatarUrl.isNotEmpty)
        ? profile.avatarUrl
        : widget.user.avatarUrl;

    final banners = (data?.banners.isNotEmpty ?? false)
        ? data!.banners
        : _defaultBanners;

    final notices = (data?.latestNotices.isNotEmpty ?? false)
        ? data!.latestNotices
        : _defaultNotices;

    final gallery = (data?.gallery.isNotEmpty ?? false)
        ? data!.gallery
        : _defaultGallery;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
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
              'Teacher Companion',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Faculty Portal • $displayName',
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
      body: RefreshIndicator(
        onRefresh: _fetchHomeData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.only(top: 8.h, bottom: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Teacher Profile GlassCard
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildTeacherProfileCard(
                  name: displayName,
                  subtitle: displaySubtitle,
                  avatarUrl: displayAvatar,
                ),
              ),

              18.h.height,

              // 2. Daily Teacher Attendance Check-In Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: AttendanceCheckInBanner(user: widget.user),
              ),

              24.h.height,

                    // 3. Promotional Banners Slider (Matching Student Dashboard)
                    if (banners.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: _buildBannerCarousel(banners),
                      ),
                      24.h.height,
                    ],

                    // 4. Quick Access Grid
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher Workspace',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          4.h.height,
                          Text(
                            'Manage Assignments (ID-Wise), Classes & Lessons',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    12.h.height,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: _buildQuickAccessGrid(context),
                    ),

                    24.h.height,

                    // 5. Today's Schedule Timeline
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    12.h.height,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          _buildTimelineCard(
                            subject: 'Class 9-B (Algebra)',
                            time: '09:00 AM - 09:45 AM',
                            room: 'Room 8',
                            color: AppColors.primary,
                          ),
                          10.h.height,
                          _buildTimelineCard(
                            subject: 'Class 9-A (Geometry)',
                            time: '10:00 AM - 10:45 AM',
                            room: 'Room 5',
                            color: AppColors.info,
                          ),
                          10.h.height,
                          _buildTimelineCard(
                            subject: 'Class 10-B (Trigonometry)',
                            time: '11:00 AM - 11:45 AM',
                            room: 'Room 12',
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ),

                    24.h.height,

                    // 6. Latest Notices Section (Matching Student & Parent)
                    if (notices.isNotEmpty) ...[
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
                          children: notices
                              .map((n) => _buildNoticeCard(n))
                              .toList(),
                        ),
                      ),
                      24.h.height,
                    ],

                    // 7. School Gallery Section
                    if (gallery.isNotEmpty) ...[
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
                              onTap: () => Navigator.pushNamed(
                                context,
                                RoutesName.gallery,
                                arguments: gallery,
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
                      _buildGalleryHorizontalList(gallery),
                      24.h.height,
                    ],

              110.h.height, // Spacer for floating bottom navigation bar
            ],
          ),
        ),
      ),
    );
  }

  // 1. Teacher Profile GlassCard matching Driver UI design
  Widget _buildTeacherProfileCard({
    required String name,
    required String subtitle,
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
                color: AppColors.teacherOrange.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.teacherOrange.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.teacherOrange,
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
              color: AppColors.teacherOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'TEACHER',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.teacherOrange,
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
                  color: const Color(0xFFFBBF24), // Vibrant warm mustard yellow
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
                      // Background graphics circle
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
                                  Text(
                                    b.title,
                                    style: TextStyle(
                                      color: const Color(0xFF1E293B),
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w900,
                                      height: 1.15,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  8.h.height,
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
                                          color: Colors.white.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          b.badge.isNotEmpty ? b.badge : 'Academic',
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
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Text(
                                          b.buttonText.isNotEmpty ? b.buttonText : 'Explore',
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

                            // Right Illustration / Icon
                            Expanded(
                              flex: 4,
                              child: Image.network(
                                b.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.menu_book_rounded,
                                  size: 60.sp,
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.4),
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
                    ? AppColors.primary
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 3. Quick Access Grid
  Widget _buildQuickAccessGrid(BuildContext context) {
    final actions = RoleNavigationConfig.getQuickAccessActions(widget.user.role);
    return GridView.builder(
      // The surrounding scroll view handles page and bottom navigation insets.
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final act = actions[index];
        return InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            act.route,
            arguments: act.arguments,
          ),
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: act.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Icon(act.icon, color: act.color, size: 23.sp),
                  ),
                ),
                8.h.height,
                Text(
                  act.label,
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 4. Schedule Timeline Card
  Widget _buildTimelineCard({
    required String subject,
    required String time,
    required String room,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          16.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.h.height,
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13.sp,
                      color: const Color(0xFF64748B),
                    ),
                    4.w.width,
                    Text(
                      time,
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              room,
              style: TextStyle(
                color: color,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Latest Notices Card (Matching Student Dashboard)
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

          // Attachment Chip if present
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

  // 6. School Gallery Horizontal List (Matching Student Dashboard)
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

  // Shimmer Skeletons
  Widget _buildLoadingSkeleton() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: widget.onOpenDrawer,
        ),
        title: Text(
          'Teacher Companion',
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
}
