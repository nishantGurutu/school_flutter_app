import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/routes/routes_name.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../core/extensions/context_extensions.dart';
import '../../logic/school/school_bloc.dart';
import 'certificate_viewer_dialog.dart';

class MoreMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const MoreMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class StudentMoreBottomSheet extends StatelessWidget {
  final BuildContext? parentContext;
  final UserModel? user;
  final String? overrideName;
  final String? overrideClass;
  final String? overrideRollNo;
  final String? overrideAvatar;

  const StudentMoreBottomSheet({
    super.key,
    this.parentContext,
    this.user,
    this.overrideName,
    this.overrideClass,
    this.overrideRollNo,
    this.overrideAvatar,
  });

  static void show(
    BuildContext context, {
    UserModel? user,
    String? overrideName,
    String? overrideClass,
    String? overrideRollNo,
    String? overrideAvatar,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StudentMoreBottomSheet(
        parentContext: context,
        user: user,
        overrideName: overrideName,
        overrideClass: overrideClass,
        overrideRollNo: overrideRollNo,
        overrideAvatar: overrideAvatar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        overrideName ??
        (user?.name.isNotEmpty == true ? user!.name : 'Kauan Sousa');

    String rawClass =
        overrideClass ??
        (user?.className?.isNotEmpty == true
            ? user!.className!
            : 'Class : 10 - A English');
    if (!rawClass.toLowerCase().contains('class')) {
      rawClass = 'Class : $rawClass';
    }

    final displayRoll = overrideRollNo ?? '31';
    final displayAvatar =
        overrideAvatar ??
        (user?.avatarUrl.isNotEmpty == true
            ? user!.avatarUrl
            : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80');

    final items = _buildMenuItems(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          10.h.height,

          // Drag Handle bar
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          12.h.height,

          // Student Profile Card matching image
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                // Circular Avatar
                Container(
                  width: 58.w,
                  height: 58.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      displayAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.person_rounded,
                          size: 30.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),

                16.w.horizontalSpace,

                // Name & Class Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      4.h.verticalSpace,
                      Text(
                        rawClass,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      2.h.verticalSpace,
                      Text(
                        'Roll No : $displayRoll',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Chevron icon
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Color(0xFF1E293B),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showStudentDetailsDialog(
                      context,
                      name: displayName,
                      className: rawClass,
                      rollNo: displayRoll,
                      avatarUrl: displayAvatar,
                    );
                  },
                ),
              ],
            ),
          ),

          16.h.height,

          // Thin Divider matching image
          const Divider(color: Color(0xFFE2E8F0), thickness: 1, height: 1),

          16.h.height,

          // 14 Options Grid (Scrollable)
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14.w,
                      mainAxisSpacing: 22.h,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (ctx, index) {
                      final item = items[index];
                      return _buildGridTile(item);
                    },
                  ),
                  36.h.height,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridTile(MoreMenuItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rounded icon container with soft pastel background matching image
          Container(
            width: 58.w,
            height: 58.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FA), // Soft light blue-gray
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Center(
              child: Icon(
                item.icon,
                color: const Color(0xFF2C4A6F), // Deep slate petrol blue
                size: 26.sp,
              ),
            ),
          ),
          8.h.verticalSpace,
          Flexible(
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MoreMenuItem> _buildMenuItems(BuildContext context) {
    final targetCtx = parentContext ?? context;
    return [
      // 1. Attendance
      MoreMenuItem(
        label: 'Attendance',
        icon: Icons.fact_check_outlined,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.attendance);
        },
      ),

      // 2. Timetable
      MoreMenuItem(
        label: 'Timetable',
        icon: Icons.calendar_month_outlined,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.timetable);
        },
      ),

      // 3. Notice Board
      MoreMenuItem(
        label: 'Notice Board',
        icon: Icons.co_present_outlined,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.notice);
        },
      ),

      // 4. Exams
      MoreMenuItem(
        label: 'Exams',
        icon: Icons.assignment_outlined,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.exam);
        },
      ),

      // 5. Result
      MoreMenuItem(
        label: 'Result',
        icon: Icons.military_tech_outlined,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.exam, arguments: 1);
        },
      ),

      // 6. Report
      MoreMenuItem(
        label: 'Report',
        icon: Icons.description_outlined,
        onTap: () {
          Navigator.pop(context);
          _showReportCardDialog(targetCtx);
        },
      ),

      // 7. Guardian details
      MoreMenuItem(
        label: 'Guardian details',
        icon: Icons.family_restroom_rounded,
        onTap: () {
          Navigator.pop(context);
          _showGuardianDialog(targetCtx);
        },
      ),

      // 8. Holidays
      MoreMenuItem(
        label: 'Holidays',
        icon: Icons.beach_access_rounded,
        onTap: () {
          Navigator.pop(context);
          _showHolidaysDialog(targetCtx);
        },
      ),

      // 9. Gallery -> Opens dynamic GalleryScreen from backend API
      MoreMenuItem(
        label: 'Gallery',
        icon: Icons.photo_library_outlined,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.gallery);
        },
      ),

      MoreMenuItem(
        label: 'Tasks',
        icon: Icons.task_alt_rounded,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.homework);
        },
      ),

      // 10. My Diary
      MoreMenuItem(
        label: 'My Diary',
        icon: Icons.menu_book_rounded,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.homework);
        },
      ),

      // 11. Transportation
      MoreMenuItem(
        label: 'Transportation',
        icon: Icons.directions_bus_rounded,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(targetCtx, RoutesName.studentTransport);
        },
      ),

      // 12. Certificate -> Live from Backend API & Interactive Certificate Viewer
      MoreMenuItem(
        label: 'Certificate',
        icon: Icons.workspace_premium_outlined,
        onTap: () {
          Navigator.pop(context);
          CertificatesDialog.show(targetCtx, user: user);
        },
      ),

      // 13. Teachers
      MoreMenuItem(
        label: 'Teachers',
        icon: Icons.school_outlined,
        onTap: () {
          Navigator.pop(context);
          _showTeachersDialog(targetCtx);
        },
      ),

      // 14. Settings
      MoreMenuItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        onTap: () {
          Navigator.pop(context);
          _showSettingsDialog(targetCtx);
        },
      ),
    ];
  }

  // --- Interactive Feature Modals ---

  static void _showStudentDetailsDialog(
    BuildContext context, {
    required String name,
    required String className,
    required String rollNo,
    required String avatarUrl,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            const Icon(Icons.badge_rounded, color: AppColors.primary),
            8.w.horizontalSpace,
            const Text('Student Profile'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36.r,
              backgroundImage: NetworkImage(avatarUrl),
            ),
            12.h.verticalSpace,
            Text(
              name,
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
            ),
            4.h.verticalSpace,
            Text(
              className,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
            ),
            Text(
              'Roll Number: $rollNo',
              style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
            ),
            12.h.verticalSpace,
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Attendance',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        '94.2%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Rank',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        '03 / 42',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'GPA',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        '3.9 / 4.0',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _showGuardianDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            const Icon(Icons.family_restroom_rounded, color: AppColors.primary),
            8.w.horizontalSpace,
            const Text('Guardian Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactTile(
              icon: Icons.person_outline_rounded,
              title: 'Father: Robert Sousa',
              subtitle: 'Phone: +1 (555) 321-9876 • Software Engineer',
            ),
            10.h.verticalSpace,
            _buildContactTile(
              icon: Icons.person_outline_rounded,
              title: 'Mother: Maria Sousa',
              subtitle: 'Phone: +1 (555) 789-4321 • Physician',
            ),
            10.h.verticalSpace,
            _buildContactTile(
              icon: Icons.home_outlined,
              title: 'Residential Address',
              subtitle: 'Apt 4B, Greenfield Avenue, New York, NY 10001',
            ),
            10.h.verticalSpace,
            _buildContactTile(
              icon: Icons.emergency_outlined,
              title: 'Emergency Contact',
              subtitle: '+1 (555) 000-1122 (Aunt: Clara Sousa)',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: AppColors.primary),
          10.w.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                2.h.verticalSpace,
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showHolidaysDialog(BuildContext context) {
    List<Map<String, String>> holidays = [];
    try {
      final stateHolidays = context.read<SchoolBloc>().state.holidays;
      if (stateHolidays.isNotEmpty) {
        holidays = stateHolidays
            .map(
              (h) => {
                'name': h.title,
                'date': h.endDate != null && h.endDate!.isNotEmpty
                    ? '${h.date} - ${h.endDate}'
                    : h.date,
                'days': h.category ?? 'Holiday',
              },
            )
            .toList();
      }
    } catch (_) {}

    if (holidays.isEmpty) {
      holidays = [
        {
          'name': 'Diwali & New Year Vacation',
          'date': '24 Oct - 28 Oct 2026',
          'days': '5 Days',
        },
        {'name': 'Guru Nanak Jayanti', 'date': '15 Nov 2026', 'days': '1 Day'},
        {
          'name': 'Winter Holiday Break',
          'date': '24 Dec - 02 Jan 2027',
          'days': '10 Days',
        },
        {'name': 'Republic Day', 'date': '26 Jan 2027', 'days': '1 Day'},
        {
          'name': 'Holi Spring Festival',
          'date': '18 Mar 2027',
          'days': '1 Day',
        },
      ];
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            const Icon(Icons.beach_access_rounded, color: AppColors.warning),
            8.w.horizontalSpace,
            const Text('School Holidays 2026-27'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: holidays.length,
            separatorBuilder: (context, index) => 8.h.verticalSpace,
            itemBuilder: (context, i) {
              final h = holidays[i];
              return Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                    ),
                    12.w.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h['name']!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            h['date']!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        h['days']!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _showReportCardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            const Icon(Icons.assessment_outlined, color: AppColors.primary),
            8.w.horizontalSpace,
            const Text('Academic Report Card'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Term 1 Comprehensive Progress Report has been published and approved by the academic council.',
              style: TextStyle(fontSize: 13),
            ),
            12.h.verticalSpace,
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Term_1_Report_Card_2026.pdf',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Size: 1.4 MB • Certified',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              context.showAppSnackBar('Downloading Report Card PDF...');
            },
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static void _showTeachersDialog(BuildContext context) {
    final teachers = [
      {
        'name': 'Mr. David Clark',
        'subject': 'Mathematics & Algebra (Class Teacher)',
        'email': 'd.clark@school.edu',
      },
      {
        'name': 'Mrs. Sarah Jenkins',
        'subject': 'English Literature & Grammar',
        'email': 's.jenkins@school.edu',
      },
      {
        'name': 'Dr. Robert Miller',
        'subject': 'Physics & Natural Sciences',
        'email': 'r.miller@school.edu',
      },
      {
        'name': 'Ms. Elena Rostova',
        'subject': 'Computer Science & Coding',
        'email': 'e.rostova@school.edu',
      },
      {
        'name': 'Mr. Rajesh Sharma',
        'subject': 'Social Studies & World History',
        'email': 'r.sharma@school.edu',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            const Icon(Icons.school_outlined, color: AppColors.primary),
            8.w.horizontalSpace,
            const Text('My Teachers'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: teachers.length,
            separatorBuilder: (context, index) => 8.h.verticalSpace,
            itemBuilder: (context, i) {
              final t = teachers[i];
              return Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        t['name']![4],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    10.w.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['name']!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            t['subject']!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            t['email']!,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings_outlined, color: AppColors.primary),
            8.w.horizontalSpace,
            const Text('App & Account Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Push Notifications',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              trailing: Switch(value: true, onChanged: (_) {}),
            ),
            ListTile(
              leading: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(ctx);
                context.showAppSnackBar('Opening password reset...');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'App Version',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              trailing: const Text(
                'v2.4.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
