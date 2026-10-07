import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../widgets/smooth_skeleton.dart';
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeaderSkeleton(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140.w, height: 24.h),
                      20.h.height,
                      Row(
                        children: [
                          SkeletonBox(width: 150.w, height: 180.h, borderRadius: 22),
                          16.w.width,
                          SkeletonBox(width: 150.w, height: 180.h, borderRadius: 22),
                        ],
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

    final data = _homeData;
    final profile = data?.profile;
    final parentName = (profile != null && profile.name.isNotEmpty) ? profile.name : widget.user.name;
    final parentEmail = (profile != null && profile.email.isNotEmpty) ? profile.email : widget.user.email;
    final parentAvatar = (profile != null && profile.avatarUrl.isNotEmpty) ? profile.avatarUrl : widget.user.avatarUrl;

    // Children list from backend or fallback to demo child matching screenshot 3
    final children = (data != null && data.children.isNotEmpty)
        ? data.children
        : [
            DashboardChild(
              id: '1',
              name: 'Kauan Sousa',
              className: 'Class - 10 - A English',
              rollNo: '31',
              admissionNo: 'ADM-1001',
              avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
            ),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _fetchParentHomeData,
        color: const Color(0xFF1E3A5F),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Curved Deep Blue Header (Screenshot 3)
              _buildParentCurvedHeader(
                name: parentName,
                email: parentEmail,
                avatarUrl: parentAvatar,
              ),

              24.h.height,

              // 2. "My Children" Section (Screenshot 3)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'My Children',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              16.h.height,

              // Horizontal / Grid children cards list
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Wrap(
                  spacing: 16.w,
                  runSpacing: 16.h,
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

  // 1. Curved Deep Blue Header matching Screenshot 3
  Widget _buildParentCurvedHeader({
    required String name,
    required String email,
    required String avatarUrl,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F), // Deep petrol blue matching screenshot 3
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
            // Decorative background concentric circular lines
            Positioned(
              top: -60.h,
              right: -50.w,
              child: Container(
                width: 220.w,
                height: 220.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
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
                  border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.5),
                ),
              ),
            ),

            // Header Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
              child: Row(
                children: [
                  // Parent Profile Avatar
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
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
                              errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
                            )
                          : _buildAvatarFallback(),
                    ),
                  ),

                  14.w.width,

                  // Parent Name & Email
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
                          email,
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

                  // Chat Icon
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, RoutesName.chat),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),

                  10.w.width,

                  // Settings Gear Icon
                  GestureDetector(
                    onTap: () => context.showAppSnackBar('Opening Parent Account Settings...'),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
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

  Widget _buildAvatarFallback() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: 30.sp),
      ),
    );
  }

  // 2. Child Card matching Screenshot 3
  Widget _buildChildCard(DashboardChild child) {
    return GestureDetector(
      onTap: () => _openChildStudentHome(child),
      child: Container(
        width: 152.w,
        height: 172.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1E5373), // Deep petrol blue card matching screenshot 3
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E5373).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        child.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF2563EB),
                          child: Icon(Icons.person_rounded, color: Colors.white, size: 28.sp),
                        ),
                      ),
                    ),
                  ),

                  12.h.height,

                  // Child Name
                  Text(
                    child.name,
                    style: TextStyle(
                      color: Colors.white,
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
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Forward Arrow Button at Bottom Center of Card (Screenshot 3)
            Positioned(
              bottom: -15.h,
              child: Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF1E5373),
                  size: 14.sp,
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

  Widget _buildHeaderSkeleton() {
    return Container(
      width: double.infinity,
      height: 100.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
    );
  }
}
