import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../widgets/glass_card.dart';

class TeacherClassItem {
  final String className;
  final String section;
  final String subject;
  final int totalStudents;
  final String room;
  final bool isClassTeacher;
  final String timing;
  final double syllabusProgress;

  const TeacherClassItem({
    required this.className,
    required this.section,
    required this.subject,
    required this.totalStudents,
    required this.room,
    this.isClassTeacher = false,
    required this.timing,
    required this.syllabusProgress,
  });
}

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<TeacherClassItem> _classes = const [
    TeacherClassItem(
      className: 'Class 9',
      section: 'A',
      subject: 'General Science',
      totalStudents: 42,
      room: 'Room 102',
      isClassTeacher: true,
      timing: '09:00 AM - 09:45 AM',
      syllabusProgress: 0.72,
    ),
    TeacherClassItem(
      className: 'Class 9',
      section: 'B',
      subject: 'Science & Biology',
      totalStudents: 38,
      room: 'Room 104',
      isClassTeacher: false,
      timing: '10:00 AM - 10:45 AM',
      syllabusProgress: 0.65,
    ),
    TeacherClassItem(
      className: 'Class 10',
      section: 'A',
      subject: 'Physics & Chemistry',
      totalStudents: 45,
      room: 'Science Lab 1',
      isClassTeacher: false,
      timing: '11:15 AM - 12:00 PM',
      syllabusProgress: 0.80,
    ),
    TeacherClassItem(
      className: 'Class 10',
      section: 'B',
      subject: 'Science & Chemistry',
      totalStudents: 40,
      room: 'Science Lab 2',
      isClassTeacher: false,
      timing: '12:45 PM - 01:30 PM',
      syllabusProgress: 0.58,
    ),
    TeacherClassItem(
      className: 'Class 8',
      section: 'C',
      subject: 'Basic Science',
      totalStudents: 35,
      room: 'Room 205',
      isClassTeacher: false,
      timing: '02:00 PM - 02:45 PM',
      syllabusProgress: 0.75,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;

    final filteredList = _classes.where((c) {
      final matchesSearch = c.className.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.section.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedFilter == 'Class Teacher') {
        return matchesSearch && c.isClassTeacher;
      } else if (_selectedFilter == 'Class 9') {
        return matchesSearch && c.className.contains('9');
      } else if (_selectedFilter == 'Class 10') {
        return matchesSearch && c.className.contains('10');
      }
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('My Classes', style: context.h2.copyWith(color: AppColors.textPrimary)),
            Text(
              user?.name ?? 'Teacher Dashboard',
              style: context.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Stats Cards
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.all(16.w),
                    borderColor: AppColors.primary.withOpacity(0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Classes', style: context.caption),
                            Icon(Icons.class_rounded, color: AppColors.primary, size: 20.sp),
                          ],
                        ),
                        8.h.height,
                        Text('${_classes.length}', style: context.h1.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
                12.w.width,
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.all(16.w),
                    borderColor: AppColors.success.withOpacity(0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Students', style: context.caption),
                            Icon(Icons.groups_rounded, color: AppColors.success, size: 20.sp),
                          ],
                        ),
                        8.h.height,
                        Text(
                          '${_classes.fold<int>(0, (sum, c) => sum + c.totalStudents)}',
                          style: context.h1.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            16.h.height,

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by class, subject, or section...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            12.h.height,

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All', 'Class Teacher', 'Class 9', 'Class 10'].map((chip) {
                  final isSelected = _selectedFilter == chip;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text(chip),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = chip),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            16.h.height,

            // Class Cards List
            if (filteredList.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48.sp, color: AppColors.textMuted),
                      12.h.height,
                      Text('No classes match your query', style: context.bodyBold),
                    ],
                  ),
                ),
              )
            else
              ...filteredList.map((item) => _buildClassCard(context, item)),

            40.h.height,
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, TeacherClassItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Class + Section + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${item.className} - ${item.section}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    8.w.width,
                    Text(
                      item.subject,
                      style: context.bodyBold.copyWith(fontSize: 14.sp),
                    ),
                  ],
                ),
                if (item.isClassTeacher)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Class Teacher',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
              ],
            ),
            12.h.height,

            // Details Row: Students, Room, Time
            Row(
              children: [
                _infoChip(Icons.people_outline_rounded, '${item.totalStudents} Students'),
                12.w.width,
                _infoChip(Icons.meeting_room_outlined, item.room),
                12.w.width,
                Expanded(
                  child: _infoChip(Icons.schedule_rounded, item.timing),
                ),
              ],
            ),
            12.h.height,

            // Syllabus Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Syllabus Completion', style: context.mutedText),
                    Text(
                      '${(item.syllabusProgress * 100).toInt()}%',
                      style: context.captionBold.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                6.h.height,
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: item.syllabusProgress,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6.h,
                  ),
                ),
              ],
            ),
            14.h.height,
            const Divider(color: AppColors.border, height: 1),
            10.h.height,

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, RoutesName.attendance),
                    icon: Icon(Icons.fact_check_rounded, size: 16.sp, color: AppColors.primary),
                    label: Text('Attendance', style: TextStyle(fontSize: 11.sp, color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      side: const BorderSide(color: AppColors.primary, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                8.w.width,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, RoutesName.homework),
                    icon: Icon(Icons.assignment_rounded, size: 16.sp, color: AppColors.info),
                    label: Text('Assignment', style: TextStyle(fontSize: 11.sp, color: AppColors.info)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      side: const BorderSide(color: AppColors.info, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                8.w.width,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, RoutesName.lesson),
                    icon: Icon(Icons.menu_book_rounded, size: 16.sp, color: AppColors.secondary),
                    label: Text('Lesson', style: TextStyle(fontSize: 11.sp, color: AppColors.secondary)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      side: const BorderSide(color: AppColors.secondary, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textMuted),
        4.w.width,
        Text(
          text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
