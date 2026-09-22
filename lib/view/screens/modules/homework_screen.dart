import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_event.dart';
import '../../../logic/school/school_state.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../data/models/school_models.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSubmitBottomSheet(BuildContext context, HomeworkItem hw) {
    String mockFileName = '';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (statefulCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20.h,
                left: 20.w,
                right: 20.w,
                bottom: MediaQuery.of(statefulCtx).viewInsets.bottom + 24.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Submit Assignment',
                        style: context.h2.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(statefulCtx),
                      ),
                    ],
                  ),
                  14.h.height,
                  Text(
                    hw.subject,
                    style: TextStyle(color: AppColors.primary, fontSize: 13.sp, fontWeight: FontWeight.bold),
                  ),
                  4.h.height,
                  Text(
                    hw.title,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  16.h.height,

                  // File upload card placeholder
                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        mockFileName = '${hw.subject.replaceAll(" ", "_")}_Solution.pdf';
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: mockFileName.isEmpty ? AppColors.border : AppColors.primary,
                          width: 1.5,
                          style: mockFileName.isEmpty ? BorderStyle.solid : BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            mockFileName.isEmpty ? Icons.cloud_upload_outlined : Icons.picture_as_pdf_rounded,
                            color: mockFileName.isEmpty ? AppColors.textMuted : AppColors.primary,
                            size: 44.sp,
                          ),
                          10.h.height,
                          Text(
                            mockFileName.isEmpty ? 'Tap to browse solution files' : mockFileName,
                            style: TextStyle(
                              color: mockFileName.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          4.h.height,
                          Text(
                            mockFileName.isEmpty ? 'Supports PDF, JPEG (max 10MB)' : 'File selected successfully',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                  24.h.height,

                  // Submit CTA
                  ElevatedButton(
                    onPressed: mockFileName.isEmpty
                        ? null
                        : () {
                            final userId = context.read<AuthBloc>().state.user?.id ?? 'student_1';
                            context.read<SchoolBloc>().add(
                                  SubmitHomeworkRequested(userId: userId, homeworkId: hw.id),
                                );
                            Navigator.pop(bottomSheetCtx);
                            context.showAppSnackBar('Uploading solution files. Submitting assignment...');
                          },
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.textMuted,
                    ),
                    child: const Text('Submit Assignment'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Homework & Tasks',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Pending Tasks'),
            Tab(text: 'Submitted'),
          ],
        ),
      ),
      body: BlocListener<SchoolBloc, SchoolState>(
        listener: (context, state) {
          if (state.actionSuccessMessage != null && state.actionSuccessMessage!.contains('Homework')) {
            context.showAppSnackBar(state.actionSuccessMessage!);
          }
        },
        child: BlocBuilder<SchoolBloc, SchoolState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final pendingList = state.homework.where((h) => h.status == HomeworkStatus.pending).toList();
            final submittedList = state.homework.where((h) => h.status == HomeworkStatus.submitted).toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _HomeworkListBuilder(
                  homeworkList: pendingList,
                  isPending: true,
                  onAction: (hw) => _showSubmitBottomSheet(context, hw),
                ),
                _HomeworkListBuilder(
                  homeworkList: submittedList,
                  isPending: false,
                  onAction: (hw) {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeworkListBuilder extends StatelessWidget {
  final List<HomeworkItem> homeworkList;
  final bool isPending;
  final Function(HomeworkItem) onAction;

  const _HomeworkListBuilder({
    required this.homeworkList,
    required this.isPending,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (homeworkList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPending ? Icons.check_circle_outline_rounded : Icons.assignment_late_outlined,
              size: 48.sp,
              color: AppColors.textMuted,
            ),
            12.h.height,
            Text(
              isPending ? 'No pending homework!' : 'No submitted tasks found.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: homeworkList.length,
      itemBuilder: (context, i) {
        final hw = homeworkList[i];
        final remainingDays = hw.dueDate.difference(DateTime.now()).inDays;
        String dueText;
        Color dateColor;

        if (isPending) {
          if (remainingDays < 0) {
            dueText = 'Overdue by ${remainingDays.abs()} days';
            dateColor = AppColors.error;
          } else if (remainingDays == 0) {
            dueText = 'Due Today';
            dateColor = AppColors.warning;
          } else {
            dueText = 'Due in $remainingDays days';
            dateColor = AppColors.info;
          }
        } else {
          dueText = 'Submitted';
          dateColor = AppColors.success;
        }

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hw.subject,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: dateColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      dueText,
                      style: TextStyle(color: dateColor, fontSize: 11.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              6.h.height,
              Text(
                hw.title,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15.sp, fontWeight: FontWeight.bold),
              ),
              8.h.height,
              Text(
                hw.description,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, height: 1.35),
              ),
              if (isPending) ...[
                14.h.height,
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => onAction(hw),
                    icon: Icon(Icons.upload_file_outlined, size: 16.sp, color: Colors.white),
                    label: const Text('Upload Solution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
