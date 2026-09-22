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
import '../../widgets/glass_card.dart';

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

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
          'Leave Requests',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyLeaveSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Apply Leave', style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700)),
      ),
      body: BlocListener<SchoolBloc, SchoolState>(
        listener: (context, state) {
          if (state.actionSuccessMessage != null &&
              (state.actionSuccessMessage!.contains('Leave') || state.actionSuccessMessage!.contains('leave'))) {
            context.showAppSnackBar(state.actionSuccessMessage!);
          }
        },
        child: BlocBuilder<SchoolBloc, SchoolState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allLeaves = state.leaves;
            final pending = allLeaves.where((l) => l.status == LeaveStatus.pending).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassCard(
                    padding: EdgeInsets.all(20.w),
                    borderColor: pending.isNotEmpty
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.success.withOpacity(0.3),
                    child: Column(
                      children: [
                        Text(
                          'Pending Approvals',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp, fontWeight: FontWeight.w500),
                        ),
                        10.h.height,
                        Text(
                          '${pending.length}',
                          style: TextStyle(
                            color: pending.isNotEmpty ? AppColors.primary : AppColors.success,
                            fontSize: 40.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (pending.isNotEmpty) ...[
                          6.h.height,
                          Text(
                            'leave request${pending.length > 1 ? 's' : ''} awaiting review',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
                          ),
                        ] else ...[
                          6.h.height,
                          Text(
                            'No pending requests',
                            style: TextStyle(color: AppColors.success, fontSize: 12.sp, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  24.h.height,

                  Text(
                    'All Leave Applications',
                    style: context.h3.copyWith(fontWeight: FontWeight.w800),
                  ),
                  14.h.height,

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: allLeaves.length,
                    itemBuilder: (context, i) {
                      final leave = allLeaves[i];
                      final isPending = leave.status == LeaveStatus.pending;
                      final isApproved = leave.status == LeaveStatus.approved;
                      final days = leave.toDate.difference(leave.fromDate).inDays + 1;

                      Color statusColor;
                      IconData statusIcon;
                      String statusLabel;
                      if (isApproved) {
                        statusColor = AppColors.success;
                        statusIcon = Icons.check_circle_rounded;
                        statusLabel = 'Approved';
                      } else if (leave.status == LeaveStatus.rejected) {
                        statusColor = AppColors.error;
                        statusIcon = Icons.cancel_rounded;
                        statusLabel = 'Rejected';
                      } else {
                        statusColor = AppColors.warning;
                        statusIcon = Icons.hourglass_empty_rounded;
                        statusLabel = 'Pending';
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isPending ? AppColors.primary.withOpacity(0.2) : AppColors.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(statusIcon, color: statusColor, size: 20.sp),
                                ),
                                12.w.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        leave.employeeName,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      2.h.height,
                                      Text(
                                        leave.designation,
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(color: statusColor, fontSize: 10.sp, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            12.h.height,
                            Text(
                              leave.reason,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                            ),
                            10.h.height,
                            Row(
                              children: [
                                _infoChip(Icons.date_range_outlined, '${_formatDate(leave.fromDate)} - ${_formatDate(leave.toDate)}'),
                                8.w.width,
                                _infoChip(Icons.today_outlined, '$days day${days > 1 ? 's' : ''}'),
                                8.w.width,
                                _infoChip(Icons.schedule_outlined, leave.appliedOn),
                              ],
                            ),
                            if (isPending) ...[
                              14.h.height,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 32.h,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _confirmReject(context, leave),
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      label: Text('Reject', style: TextStyle(fontSize: 11.sp)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      ),
                                    ),
                                  ),
                                  10.w.width,
                                  SizedBox(
                                    height: 32.h,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _confirmApprove(context, leave),
                                      icon: const Icon(Icons.check_rounded, size: 16),
                                      label: Text('Approve', style: TextStyle(fontSize: 11.sp)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  100.h.height,
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showApplyLeaveSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (statefulCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w, height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      16.h.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Apply Leave', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      16.h.height,
                      Form(
                        key: formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: nameCtrl,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Employee Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                            ),
                            12.h.height,
                            TextFormField(
                              controller: desigCtrl,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Designation',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter designation' : null,
                            ),
                            12.h.height,
                            TextFormField(
                              controller: reasonCtrl,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Reason',
                                prefixIcon: Icon(Icons.description_outlined),
                              ),
                              maxLines: 2,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter reason' : null,
                            ),
                            12.h.height,
                            Row(
                              children: [
                                Expanded(
                                  child: _DateField(
                                    label: 'From Date',
                                    date: fromDate,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: sheetCtx,
                                        initialDate: fromDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          fromDate = picked;
                                          if (toDate.isBefore(fromDate)) toDate = fromDate;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                12.w.width,
                                Expanded(
                                  child: _DateField(
                                    label: 'To Date',
                                    date: toDate,
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: sheetCtx,
                                        initialDate: toDate,
                                        firstDate: fromDate,
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                      );
                                      if (picked != null) {
                                        setModalState(() => toDate = picked);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            20.h.height,
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    context.read<SchoolBloc>().add(
                                      ApplyLeaveRequested(
                                        employeeName: nameCtrl.text.trim(),
                                        designation: desigCtrl.text.trim(),
                                        reason: reasonCtrl.text.trim(),
                                        fromDate: fromDate,
                                        toDate: toDate,
                                      ),
                                    );
                                    Navigator.pop(sheetCtx);
                                  }
                                },
                                child: Text('Submit Leave', style: TextStyle(fontSize: 14.sp)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmApprove(BuildContext context, LeaveRecord leave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Approve Leave'),
        content: Text('Approve leave for ${leave.employeeName} from ${_formatDate(leave.fromDate)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final userId = context.read<AuthBloc>().state.user?.id ?? 'staff_1';
              context.read<SchoolBloc>().add(ApproveLeaveRequested(userId: userId, leaveId: leave.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context, LeaveRecord leave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Reject Leave'),
        content: Text('Reject leave for ${leave.employeeName} from ${_formatDate(leave.fromDate)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final userId = context.read<AuthBloc>().state.user?.id ?? 'staff_1';
              context.read<SchoolBloc>().add(RejectLeaveRequested(userId: userId, leaveId: leave.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10.sp, color: AppColors.textMuted),
        4.w.width,
        Text(text, style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
