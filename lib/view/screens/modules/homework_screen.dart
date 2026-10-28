import 'dart:async';
import 'assignment_submission_screen.dart';
import '../../widgets/create_assignment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/smooth_skeleton.dart';

class HomeworkScreen extends StatefulWidget {
  final bool isInline;
  final ApiSchoolRepository? repository;
  final UserModel? user;
  const HomeworkScreen({
    super.key,
    this.isInline = false,
    this.repository,
    this.user,
  });

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ApiSchoolRepository _repository =
      widget.repository ?? ApiSchoolRepository();
  late TabController _tabController;
  List<HomeworkItem> _homeworkList = [];
  bool _isLoading = true;
  bool _hasCheckedArgs = false;
  bool _fetching = false;
  String? _loadError;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _startRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedArgs) {
      _hasCheckedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showCreateAssignmentSheet(
            prefilledStudentId: args['targetStudentId'],
            prefilledStudentName: args['targetStudentName']?.toString(),
            prefilledClass: args['className']?.toString(),
            prefilledSection: args['section']?.toString(),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  void _startRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (ModalRoute.of(context)?.isCurrent != false) _loadData(silent: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(silent: true);
      _startRefresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!mounted || _fetching) return;
    _fetching = true;
    if (!silent) setState(() => _isLoading = true);
    try {
      final currentUser = widget.user ?? context.read<AuthBloc>().state.user;
      if (currentUser == null) {
        throw StateError('Please sign in to view assignments.');
      }
      final list = currentUser.role == UserRole.teacher
          ? await _repository.getTeacherAssignments()
          : await _repository.getStudentAssignments(
              admissionNo: currentUser.admissionNo,
            );
      if (mounted) {
        setState(() {
          _homeworkList = list;
          _loadError = null;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error.toString();
          _isLoading = false;
        });
      }
    } finally {
      _fetching = false;
    }
  }

  Future<void> _showCreateAssignmentSheet({
    dynamic prefilledStudentId,
    String? prefilledStudentName,
    String? prefilledClass,
    String? prefilledSection,
  }) async {
    final user = widget.user ?? context.read<AuthBloc>().state.user;
    if (user?.role != UserRole.teacher) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => CreateAssignmentSheet(
        repository: _repository,
        prefilledStudentId: prefilledStudentId,
        prefilledClass: prefilledClass,
        prefilledSection: prefilledSection,
      ),
    );
    if (created == true && mounted) await _loadData();
  }

  void _showSubmissionsSheet(HomeworkItem hw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (ctx) {
        return _SubmissionsReviewSheet(
          assignment: hw,
          repository: _repository,
          onReviewDone: _loadData,
        );
      },
    );
  }

  Future<void> _showStudentSubmitSheet(
    HomeworkItem hw, {
    bool readOnly = false,
  }) async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentSubmissionScreen(
          assignment: hw,
          repository: _repository,
          readOnly: readOnly,
        ),
      ),
    );
    if (!mounted) return;
    if (submitted == true) {
      context.showAppSnackBar(
        'Work submitted successfully. Your teacher can now review it.',
      );
      await _loadData();
      if (mounted) _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user ?? context.watch<AuthBloc>().state.user;
    final isTeacher = user?.role == UserRole.teacher;

    final pendingList = _homeworkList.where((h) {
      final s = (h.submissionStatus ?? h.status.name).toLowerCase();
      return s == 'pending' || s == 'overdue' || s == 'rejected';
    }).toList();

    final completedList = _homeworkList.where((h) {
      final s = (h.submissionStatus ?? h.status.name).toLowerCase();
      return s == 'submitted' || s == 'accepted' || s == 'graded';
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isInline
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          isTeacher ? 'Assignment Manager' : 'Assignments & Tasks',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Reload',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isTeacher
              ? const Color(0xFF0284C7)
              : AppColors.primary,
          labelColor: isTeacher ? const Color(0xFF0284C7) : AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              text: isTeacher
                  ? 'All Assignments (${_homeworkList.length})'
                  : 'Pending (${pendingList.length})',
            ),
            Tab(
              text: isTeacher
                  ? 'Active Tasks'
                  : 'Submitted & Graded (${completedList.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateAssignmentSheet(),
              backgroundColor: const Color(0xFF0284C7),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'New Assignment',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const SmoothSkeletonCardList(count: 3)
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 12),
                    const Text('Unable to load assignments'),
                    const SizedBox(height: 8),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListView(
                  isTeacher ? _homeworkList : pendingList,
                  isTeacher: isTeacher,
                  isPending: true,
                ),
                _buildListView(
                  isTeacher
                      ? _homeworkList
                            .where((h) => h.status != HomeworkStatus.overdue)
                            .toList()
                      : completedList,
                  isTeacher: isTeacher,
                  isPending: false,
                ),
              ],
            ),
    );
  }

  Widget _buildListView(
    List<HomeworkItem> list, {
    required bool isTeacher,
    required bool isPending,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48.sp,
              color: AppColors.textMuted,
            ),
            12.h.height,
            Text(
              isTeacher
                  ? 'No assignments created yet'
                  : (isPending
                        ? 'No pending assignments!'
                        : 'No submitted tasks.'),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isTeacher) ...[
              6.h.height,
              Text(
                'Tap "+ New Assignment" to create and assign ID-wise.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      itemCount: list.length,
      separatorBuilder: (_, _) => 12.h.height,
      itemBuilder: (context, i) {
        final hw = list[i];
        return _buildAssignmentCard(hw, isTeacher: isTeacher);
      },
    );
  }

  Widget _buildAssignmentCard(HomeworkItem hw, {required bool isTeacher}) {
    final statusStr = (hw.submissionStatus ?? hw.status.name).toLowerCase();
    final isStudent =
        (widget.user ?? context.read<AuthBloc>().state.user)?.role ==
        UserRole.student;
    Color statusColor = AppColors.info;
    String statusLabel = 'Pending';

    if (statusStr == 'submitted') {
      statusColor = const Color(0xFF0284C7);
      statusLabel = 'Submitted';
    } else if (statusStr == 'accepted' || statusStr == 'graded') {
      statusColor = AppColors.success;
      statusLabel = hw.scoredPoints != null
          ? 'Graded: ${hw.scoredPoints}/${hw.maxPoints}'
          : 'Accepted';
    } else if (statusStr == 'rejected') {
      statusColor = AppColors.error;
      statusLabel = 'Needs Resubmission';
    } else if (statusStr == 'overdue') {
      statusColor = AppColors.error;
      statusLabel = 'Overdue';
    }

    return GlassCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  hw.subject,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          8.h.height,

          // Title & Description
          Text(
            hw.title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (hw.description.isNotEmpty) ...[
            4.h.height,
            Text(
              hw.description,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
          10.h.height,

          // Target Badges: ID-Wise student vs Whole Class
          if (hw.isPersonalized)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_pin_rounded,
                    size: 16.sp,
                    color: const Color(0xFF2563EB),
                  ),
                  6.w.width,
                  Expanded(
                    child: Text(
                      isTeacher
                          ? 'Targeted Student: ${hw.targetStudentName ?? 'Student'} (ID: #${hw.targetStudentId})'
                          : 'Personalized Task assigned directly to Your Student ID',
                      style: TextStyle(
                        color: const Color(0xFF1D4ED8),
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Class: ${hw.className}${hw.section != null ? ' - ${hw.section}' : ''} • Whole Class',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Evaluation details for student
          if (!isTeacher &&
              hw.teacherFeedback != null &&
              hw.teacherFeedback!.isNotEmpty)
            Container(
              padding: EdgeInsets.all(10.w),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.comment_rounded,
                    size: 16.sp,
                    color: AppColors.success,
                  ),
                  8.w.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Remarks:',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        2.h.height,
                        Text(
                          hw.teacherFeedback!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Footer info: Due date, Points, and Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 13.sp,
                    color: AppColors.textMuted,
                  ),
                  4.w.width,
                  Text(
                    'Due: ${hw.dueDate.day}/${hw.dueDate.month}/${hw.dueDate.year}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5.sp,
                    ),
                  ),
                  12.w.width,
                  Icon(
                    Icons.star_outline_rounded,
                    size: 14.sp,
                    color: AppColors.textMuted,
                  ),
                  4.w.width,
                  Text(
                    '${hw.points} pts',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ],
              ),

              if (isTeacher)
                ElevatedButton.icon(
                  onPressed: () => _showSubmissionsSheet(hw),
                  icon: Icon(
                    Icons.people_alt_outlined,
                    size: 14.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Submissions (${hw.submissionCount})',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                )
              else if (isStudent &&
                  ['pending', 'overdue', 'rejected'].contains(statusStr))
                ElevatedButton.icon(
                  onPressed: () => _showStudentSubmitSheet(hw),
                  icon: Icon(
                    Icons.upload_file_rounded,
                    size: 14.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Submit Work',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                )
              else if (isStudent &&
                  ['submitted', 'accepted', 'graded'].contains(statusStr))
                OutlinedButton.icon(
                  onPressed: () => _showStudentSubmitSheet(hw, readOnly: true),
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('View submission'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmissionsReviewSheet extends StatefulWidget {
  final HomeworkItem assignment;
  final ApiSchoolRepository repository;
  final VoidCallback onReviewDone;

  const _SubmissionsReviewSheet({
    required this.assignment,
    required this.repository,
    required this.onReviewDone,
  });

  @override
  State<_SubmissionsReviewSheet> createState() =>
      _SubmissionsReviewSheetState();
}

class _SubmissionsReviewSheetState extends State<_SubmissionsReviewSheet> {
  List<AssignmentSubmissionItem> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    final list = await widget.repository.getAssignmentSubmissions(
      widget.assignment.id,
    );
    if (mounted) {
      setState(() {
        _submissions = list;
        _loading = false;
      });
    }
  }

  void _showGradeDialog(AssignmentSubmissionItem sub) {
    final pointsCtrl = TextEditingController(
      text: sub.points != null
          ? sub.points.toString()
          : '${widget.assignment.points}',
    );
    final feedbackCtrl = TextEditingController(text: sub.teacherFeedback ?? '');
    String chosenStatus = sub.status == 'PENDING' ? 'ACCEPTED' : sub.status;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                'Grade Submission • ID: #${sub.studentId}',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Student: ${sub.studentName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                    if (sub.submissionText != null &&
                        sub.submissionText!.isNotEmpty) ...[
                      8.h.height,
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          'Submitted Work:\n${sub.submissionText}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                    12.h.height,
                    TextField(
                      controller: pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Marks Scored (Max: ${sub.maxPoints})',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    10.h.height,
                    DropdownButtonFormField<String>(
                      initialValue: chosenStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      items: ['ACCEPTED', 'GRADED', 'REJECTED']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => chosenStatus = val);
                        }
                      },
                    ),
                    10.h.height,
                    TextField(
                      controller: feedbackCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Teacher Remarks / Feedback',
                        hintText: 'e.g. Well answered, keep it up!',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (sub.submissionId != null) {
                      await widget.repository.reviewSubmission(
                        assignmentId: widget.assignment.id,
                        submissionId: sub.submissionId,
                        status: chosenStatus,
                        points: int.tryParse(pointsCtrl.text.trim()),
                        feedback: feedbackCtrl.text.trim(),
                      );
                      _fetchSubmissions();
                      widget.onReviewDone();
                    }
                  },
                  child: const Text('Save Grade'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assignment.title,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Submissions & ID-Wise Evaluation (${_submissions.length})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
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
          else if (_submissions.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No student records found.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _submissions.length,
                separatorBuilder: (_, _) => 8.h.height,
                itemBuilder: (context, i) {
                  final sub = _submissions[i];
                  Color statusColor = AppColors.textMuted;
                  if (sub.status == 'SUBMITTED') {
                    statusColor = const Color(0xFF0284C7);
                  }
                  if (sub.status == 'ACCEPTED' || sub.status == 'GRADED') {
                    statusColor = AppColors.success;
                  }
                  if (sub.status == 'REJECTED') statusColor = AppColors.error;

                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  sub.studentName,
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                6.w.width,
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'ID: #${sub.studentId}',
                                    style: TextStyle(
                                      color: const Color(0xFF4338CA),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                sub.status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        4.h.height,
                        Text(
                          'Roll: ${sub.studentRollNo ?? 'N/A'} • Adm: ${sub.studentAdmissionNo ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (sub.submissionText != null &&
                            sub.submissionText!.isNotEmpty) ...[
                          6.h.height,
                          Text(
                            'Answer: "${sub.submissionText}"',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                        if (sub.points != null) ...[
                          4.h.height,
                          Text(
                            'Marks Scored: ${sub.points} / ${sub.maxPoints}',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                        8.h.height,
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _showGradeDialog(sub),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                            ),
                            child: Text(
                              sub.points != null
                                  ? 'Edit Grade'
                                  : 'Grade / Review',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
