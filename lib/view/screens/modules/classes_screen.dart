import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/routes/routes_name.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/smooth_skeleton.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  List<TeacherClassModel> _classes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final data = await _repository.getTeacherClasses();
    if (mounted) {
      setState(() {
        _classes = data;
        _isLoading = false;
      });
    }
  }

  void _showStudentsBottomSheet(BuildContext context, TeacherClassModel classModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (ctx) {
        return _ClassStudentsSheet(
          classModel: classModel,
          repository: _repository,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;

    final filteredList = _classes.where((c) {
      final matchesSearch = c.className.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.section.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedFilter == 'Class Teacher') {
        return matchesSearch && c.isClassTeacher;
      } else if (_selectedFilter != 'All') {
        return matchesSearch && c.className.toLowerCase().contains(_selectedFilter.toLowerCase());
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Reload Classes',
            onPressed: _loadClasses,
          ),
        ],
      ),
      body: _isLoading
          ? const SmoothSkeletonCardList(count: 3)
          : RefreshIndicator(
              onRefresh: _loadClasses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                            borderColor: AppColors.primary.withValues(alpha: 0.2),
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
                            borderColor: AppColors.success.withValues(alpha: 0.2),
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
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Column(
                            children: [
                              Icon(Icons.search_off_rounded, size: 48.sp, color: AppColors.textMuted),
                              12.h.height,
                              Text(
                                'No classes match your query',
                                style: context.bodyBold.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => 14.h.height,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return _buildClassCard(context, item);
                        },
                      ),
                    20.h.height,
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildClassCard(BuildContext context, TeacherClassModel item) {
    return InkWell(
      onTap: () => _showStudentsBottomSheet(context, item),
      borderRadius: BorderRadius.circular(18.r),
      child: GlassCard(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Class name, Section, Subject, and Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
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
                      color: AppColors.success.withValues(alpha: 0.1),
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
                  flex: 5,
                  child: ElevatedButton.icon(
                    onPressed: () => _showStudentsBottomSheet(context, item),
                    icon: Icon(Icons.people_alt_rounded, size: 15.sp, color: Colors.white),
                    label: Text(
                      'View Students (${item.totalStudents})',
                      style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                8.w.width,
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, RoutesName.homework),
                    icon: Icon(Icons.assignment_rounded, size: 14.sp, color: const Color(0xFF0284C7)),
                    label: Text('Assign', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      side: const BorderSide(color: Color(0xFF0284C7), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
                8.w.width,
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, RoutesName.lesson),
                    icon: Icon(Icons.menu_book_rounded, size: 14.sp, color: const Color(0xFF059669)),
                    label: Text('Lesson', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      side: const BorderSide(color: Color(0xFF059669), width: 1),
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

class _ClassStudentsSheet extends StatefulWidget {
  final TeacherClassModel classModel;
  final ApiSchoolRepository repository;

  const _ClassStudentsSheet({
    required this.classModel,
    required this.repository,
  });

  @override
  State<_ClassStudentsSheet> createState() => _ClassStudentsSheetState();
}

class _ClassStudentsSheetState extends State<_ClassStudentsSheet> {
  List<StudentInClassModel> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    final list = await widget.repository.getClassStudents(
      widget.classModel.className,
      section: widget.classModel.section,
    );
    if (mounted) {
      setState(() {
        _students = list;
        _loading = false;
      });
    }
  }

  void _assignToStudent(BuildContext context, StudentInClassModel student) {
    Navigator.pop(context); // Close sheet
    Navigator.pushNamed(
      context,
      RoutesName.homework,
      arguments: {
        'targetStudentId': student.id,
        'targetStudentName': student.name,
        'className': widget.classModel.className,
        'section': widget.classModel.section,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.classModel.className} - ${widget.classModel.section}',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'Enrolled Students (${_students.length}) • ID-Wise Assignment',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          12.h.height,
          const Divider(color: AppColors.border),
          8.h.height,
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_students.isEmpty)
            Expanded(
              child: Center(
                child: Text('No students found in this class', style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp)),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _students.length,
                separatorBuilder: (_, __) => 8.h.height,
                itemBuilder: (context, i) {
                  final s = _students[i];
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20.r,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: s.studentPhoto != null && s.studentPhoto!.isNotEmpty
                              ? NetworkImage(s.studentPhoto!)
                              : null,
                          child: s.studentPhoto == null || s.studentPhoto!.isEmpty
                              ? Text(
                                  s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                                )
                              : null,
                        ),
                        12.w.width,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s.name,
                                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  6.w.width,
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0E7FF),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      'ID: #${s.id}',
                                      style: TextStyle(color: const Color(0xFF4338CA), fontSize: 10.sp, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              3.h.height,
                              Text(
                                'Roll: ${s.rollNo ?? 'N/A'} • Adm: ${s.admissionNo}',
                                style: TextStyle(fontSize: 11.5.sp, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _assignToStudent(context, s),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                          ),
                          child: Text(
                            'Assign Task',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
