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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. Signature Curved Navy/Petrol Blue Header (matching Student & Parent)
          _buildTeacherCurvedHeader(
            name: displayName,
            subtitle: displaySubtitle,
            avatarUrl: displayAvatar,
          ),

          // Scrollable Body Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchHomeData,
              color: const Color(0xFF1E3A5F),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    20.h.height,

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
                      _buildGalleryHorizontalList(gallery),
                      24.h.height,
                    ],

                    110.h.height, // Spacer for floating bottom navigation bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Signature Curved Deep Blue Header
  Widget _buildTeacherCurvedHeader({
    required String name,
    required String subtitle,
    required String avatarUrl,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F), // Deep curved petrol/navy blue matching Student & Parent
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative background concentric circular lines
            Positioned(
              top: -60.h,
              right: -50.w,
              child: Container(
                width: 220.w,
                height: 220.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -20.h,
              left: 20.w,
              child: Container(
                width: 150.w,
                height: 150.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
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
                  // Profile Avatar with circular white border & shadow
                  Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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

                  14.w.width,

                  // Teacher Name & Designation Details
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
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Drawer Menu Glass Button
                  GestureDetector(
                    onTap: widget.onOpenDrawer,
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),

                  10.w.width,

                  // Chat Message Glass Button
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, RoutesName.chat),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 20.sp,
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

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF2563EB),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 28.sp,
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

  // 3. Quick Access Grid
  Widget _buildQuickAccessGrid(BuildContext context) {
    final actions = RoleNavigationConfig.getQuickAccessActions(widget.user.role);
    return GridView.builder(
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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeaderSkeleton(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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

  Widget _buildHeaderSkeleton() {
    return SmoothShimmer(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A5F),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32.r),
            bottomRight: Radius.circular(32.r),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
            child: Row(
              children: [
                const SkeletonBox(width: 52, height: 52, borderRadius: 26),
                14.w.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140.w, height: 18.h, borderRadius: 6),
                      6.h.height,
                      SkeletonBox(width: 100.w, height: 12.h, borderRadius: 4),
                    ],
                  ),
                ),
                const SkeletonBox(width: 40, height: 40, borderRadius: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
