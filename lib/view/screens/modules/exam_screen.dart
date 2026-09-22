import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_event.dart';
import '../../../logic/school/school_state.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/school_models.dart';

class ExamScreen extends StatefulWidget {
  final int initialTab;

  const ExamScreen({super.key, this.initialTab = 0});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateExamModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CreateExamSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final userRole = authState.user?.role ?? UserRole.student;
    final isTeacherOrAdmin = userRole == UserRole.teacher ||
        userRole == UserRole.staff ||
        userRole == UserRole.admin ||
        userRole == UserRole.masterAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Examinations',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (isTeacherOrAdmin)
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.primary, size: 26),
                tooltip: 'Schedule New Exam',
                onPressed: () => _showCreateExamModal(context),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle:
              TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Results'),
          ],
        ),
      ),
      floatingActionButton: isTeacherOrAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateExamModal(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Schedule Exam',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            )
          : null,
      body: BlocListener<SchoolBloc, SchoolState>(
        listenWhen: (previous, current) =>
            previous.actionSuccessMessage != current.actionSuccessMessage ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.actionSuccessMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionSuccessMessage!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<SchoolBloc, SchoolState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final upcoming = state.exams
                .where((e) =>
                    e.status == ExamStatus.upcoming ||
                    (e.status == ExamStatus.ongoing))
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            final completed = state.exams
                .where((e) => e.status == ExamStatus.completed)
                .toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            return TabBarView(
              controller: _tabController,
              children: [
                _ExamListTab(
                  exams: upcoming,
                  emptyIcon: Icons.event_available_rounded,
                  emptyText: 'No upcoming exams scheduled',
                  userRole: userRole,
                ),
                _ExamListTab(
                  exams: completed,
                  emptyIcon: Icons.grade_rounded,
                  emptyText: 'No completed exams yet',
                  showResults: true,
                  userRole: userRole,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExamListTab extends StatelessWidget {
  final List<ExamItem> exams;
  final IconData emptyIcon;
  final String emptyText;
  final bool showResults;
  final UserRole userRole;

  const _ExamListTab({
    required this.exams,
    required this.emptyIcon,
    required this.emptyText,
    this.showResults = false,
    required this.userRole,
  });

  void _showRecordScoreModal(BuildContext context, ExamItem exam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RecordScoreSheet(exam: exam),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacherOrAdmin = userRole == UserRole.teacher ||
        userRole == UserRole.staff ||
        userRole == UserRole.admin ||
        userRole == UserRole.masterAdmin;
    final isParent = userRole == UserRole.parent;

    double avgPercentage = 0.0;
    String overallGrade = 'N/A';
    if (showResults && exams.isNotEmpty) {
      final scoredExams = exams.where((e) => e.scoredMarks != null).toList();
      if (scoredExams.isNotEmpty) {
        final totalPct = scoredExams.fold(0.0, (sum, e) => sum + e.percentage);
        avgPercentage = double.parse((totalPct / scoredExams.length).toStringAsFixed(1));
        if (avgPercentage >= 90) overallGrade = 'A+';
        else if (avgPercentage >= 80) overallGrade = 'A';
        else if (avgPercentage >= 70) overallGrade = 'B';
        else if (avgPercentage >= 60) overallGrade = 'C';
        else if (avgPercentage >= 50) overallGrade = 'D';
        else overallGrade = 'F';
      }
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      children: [
        if (showResults && isParent && exams.isNotEmpty) ...[
          Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      overallGrade,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                16.w.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Child\'s Exam Performance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      4.h.height,
                      Text(
                        'Average Score: $avgPercentage%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      2.h.height,
                      Text(
                        'Grade Rating: $overallGrade (Overall Outstanding)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        if (exams.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 60.h),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(emptyIcon, size: 48.sp, color: AppColors.textMuted),
                  12.h.height,
                  Text(
                    emptyText,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...exams.map((exam) {
            final isToday = exam.date.day == DateTime.now().day &&
                exam.date.month == DateTime.now().month &&
                exam.date.year == DateTime.now().year;

            final dayDiff = exam.date.difference(DateTime.now()).inDays;
            String dateLabel;
            Color dateColor;

            if (showResults) {
              dateLabel = _formatDate(exam.date);
              dateColor = AppColors.textMuted;
            } else if (isToday) {
              dateLabel = 'Today';
              dateColor = AppColors.warning;
            } else if (dayDiff == 0) {
              dateLabel = 'Tomorrow';
              dateColor = AppColors.info;
            } else if (dayDiff < 0) {
              dateLabel = 'Overdue';
              dateColor = AppColors.error;
            } else {
              dateLabel = 'In $dayDiff days';
              dateColor = AppColors.success;
            }
            final subjectColor = _getSubjectColor(exam.subject);

            return Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: subjectColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.quiz_outlined,
                            color: subjectColor,
                            size: 22.sp,
                          ),
                        ),
                      ),
                      14.w.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    exam.subject,
                                    style: TextStyle(
                                      color: subjectColor,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: dateColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    dateLabel,
                                    style: TextStyle(
                                      color: dateColor,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            4.h.height,
                            Text(
                              exam.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  12.h.height,
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.description,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        10.h.height,
                        Row(
                          children: [
                            _ExamInfoChip(
                              icon: Icons.calendar_today_rounded,
                              label: _formatDate(exam.date),
                            ),
                            12.w.width,
                            _ExamInfoChip(
                              icon: Icons.schedule_rounded,
                              label: '${exam.startTime} - ${exam.endTime}',
                            ),
                            12.w.width,
                            _ExamInfoChip(
                              icon: Icons.meeting_room_rounded,
                              label: exam.room,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showResults && exam.scoredMarks != null) ...[
                    12.h.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: (exam.isPassed
                                        ? AppColors.success
                                        : AppColors.error)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Grade: ${exam.gradeLabel} (${exam.percentage}%)',
                                style: TextStyle(
                                  color: exam.isPassed
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            gradient: exam.scoredMarks! / exam.maxMarks >= 0.6
                                ? AppColors.successGradient
                                : AppColors.errorGradient,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'Score: ${exam.scoredMarks!.toInt()}/${exam.maxMarks.toInt()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!showResults) ...[
                    12.h.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Max Marks: ${exam.maxMarks.toInt()}',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            exam.className,
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isTeacherOrAdmin) ...[
                    12.h.height,
                    const Divider(height: 1, color: AppColors.border),
                    8.h.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showRecordScoreModal(context, exam),
                          icon: Icon(
                            exam.scoredMarks != null
                                ? Icons.edit_note_rounded
                                : Icons.upload_file_rounded,
                            size: 16.sp,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            exam.scoredMarks != null
                                ? 'Update Score'
                                : 'Record Score',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        SizedBox(height: isTeacherOrAdmin ? 60.h : 20.h),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _getSubjectColor(String subject) {
    if (subject.contains('Math')) return AppColors.primary;
    if (subject.contains('Science') || subject.contains('Physics') || subject.contains('Chemistry')) return AppColors.info;
    if (subject.contains('English')) return AppColors.secondary;
    if (subject.contains('Hindi') || subject.contains('Social')) return AppColors.warning;
    return AppColors.primary;
  }
}

class _ExamInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ExamInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.sp, color: AppColors.textMuted),
        4.w.width,
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CreateExamSheet extends StatefulWidget {
  const _CreateExamSheet();

  @override
  State<_CreateExamSheet> createState() => _CreateExamSheetState();
}

class _CreateExamSheetState extends State<_CreateExamSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _roomController = TextEditingController(text: 'Room 12');
  final _maxMarksController = TextEditingController(text: '100');
  final _startTimeController = TextEditingController(text: '09:00 AM');
  final _endTimeController = TextEditingController(text: '11:30 AM');

  String _selectedSubject = 'Mathematics';
  String _selectedClass = 'Class 10-A';
  final DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'English',
    'Social Studies',
    'Physics',
    'Chemistry',
    'Computer Science',
  ];

  final List<String> _classes = [
    'Class 10-A',
    'Class 10-B',
    'Class 9-A',
    'Class 9-B',
    'Class 8-A',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _roomController.dispose();
    _maxMarksController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final exam = ExamItem(
        id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
        subject: _selectedSubject,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        room: _roomController.text.trim(),
        maxMarks: double.tryParse(_maxMarksController.text.trim()) ?? 100,
        status: ExamStatus.upcoming,
        className: _selectedClass,
      );

      context.read<SchoolBloc>().add(CreateExamRequested(exam));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              16.h.height,
              Text(
                'Schedule New Exam',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              16.h.height,
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubject = val);
                },
              ),
              12.h.height,
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Exam Title',
                  hintText: 'e.g. Midterm Examination',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter title' : null,
              ),
              12.h.height,
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description / Syllabus',
                  hintText: 'e.g. Chapters 1 to 5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter description'
                    : null,
              ),
              12.h.height,
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      items: _classes
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedClass = val);
                      },
                    ),
                  ),
                  12.w.width,
                  Expanded(
                    child: TextFormField(
                      controller: _maxMarksController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max Marks',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Enter max' : null,
                    ),
                  ),
                ],
              ),
              12.h.height,
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startTimeController,
                      decoration: InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  12.w.width,
                  Expanded(
                    child: TextFormField(
                      controller: _endTimeController,
                      decoration: InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              12.h.height,
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room Venue',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              20.h.height,
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Schedule Exam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordScoreSheet extends StatefulWidget {
  final ExamItem exam;

  const _RecordScoreSheet({required this.exam});

  @override
  State<_RecordScoreSheet> createState() => _RecordScoreSheetState();
}

class _RecordScoreSheetState extends State<_RecordScoreSheet> {
  final _scoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.exam.scoredMarks != null) {
      _scoreController.text = widget.exam.scoredMarks!.toInt().toString();
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _scoreController.text.trim();
    if (text.isNotEmpty) {
      final score = double.tryParse(text);
      if (score != null) {
        context.read<SchoolBloc>().add(
              UploadExamScoreRequested(
                examId: widget.exam.id,
                score: score,
              ),
            );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          16.h.height,
          Text(
            'Record Exam Score',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          6.h.height,
          Text(
            '${widget.exam.subject} - ${widget.exam.title}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          16.h.height,
          TextFormField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Scored Marks (Max: ${widget.exam.maxMarks.toInt()})',
              suffixText: '/ ${widget.exam.maxMarks.toInt()}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          20.h.height,
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Publish Score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
