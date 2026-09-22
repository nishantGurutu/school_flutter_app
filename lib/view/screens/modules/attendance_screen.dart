import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_event.dart';
import '../../../logic/school/school_state.dart';
import '../../../data/models/school_models.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/glass_card.dart';

class AttendanceScreen extends StatelessWidget {
  final bool isInline;

  const AttendanceScreen({super.key, this.isInline = false});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final bool canMark = user != null && user.role != UserRole.parent;

        return BlocListener<SchoolBloc, SchoolState>(
          listenWhen: (prev, curr) => curr.actionSuccessMessage != null && prev.actionSuccessMessage != curr.actionSuccessMessage,
          listener: (context, state) {
            if (state.actionSuccessMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionSuccessMessage!),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: isInline
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
              title: Text(
                'School Attendance',
                style: context.h2.copyWith(color: AppColors.textPrimary),
              ),
              centerTitle: true,
              actions: [
                if (canMark)
                  Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
                      ),
                      onPressed: () => _showMarkAttendanceSheet(context, user),
                    ),
                  ),
              ],
            ),
            floatingActionButton: canMark
                ? FloatingActionButton.extended(
                    onPressed: () => _showMarkAttendanceSheet(context, user),
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.edit_calendar_rounded, color: Colors.white),
                    label: Text(
                      'Mark Attendance',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
            body: BlocBuilder<SchoolBloc, SchoolState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final records = state.attendance;
                final rate = state.attendancePercentage;
                final totalDays = records.where((r) => r.status != AttendanceStatus.holiday).length;
                final presentDays = records.where((r) => r.status == AttendanceStatus.present).length;
                final absentDays = records.where((r) => r.status == AttendanceStatus.absent).length;
                final holidayDays = records.where((r) => r.status == AttendanceStatus.holiday).length;

                final year = DateTime.now().year;
                final month = DateTime.now().month;
                final daysInMonth = DateTime(year, month + 1, 0).day;
                final firstWeekday = DateTime(year, month, 1).weekday;
                final String monthName = _getMonthName(month);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Column(
                    children: [
                      // Role Context Card
                      if (user != null)
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 16.h),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20.r,
                                backgroundImage: NetworkImage(user.avatarUrl),
                              ),
                              12.w.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      user.details,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: canMark ? AppColors.success.withOpacity(0.15) : AppColors.info.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  canMark ? 'Marking Enabled' : 'View Only',
                                  style: TextStyle(
                                    color: canMark ? AppColors.success : AppColors.info,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Metrics Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Attendance Rate',
                              value: '${rate.toStringAsFixed(1)}%',
                              color: AppColors.success,
                              icon: Icons.percent_rounded,
                            ),
                          ),
                          12.w.width,
                          Expanded(
                            child: _MetricCard(
                              title: 'Present Days',
                              value: '$presentDays/$totalDays',
                              color: AppColors.primary,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      12.h.height,
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Leaves / Absences',
                              value: '$absentDays Days',
                              color: AppColors.error,
                              icon: Icons.cancel_outlined,
                            ),
                          ),
                          12.w.width,
                          Expanded(
                            child: _MetricCard(
                              title: 'Total Holidays',
                              value: '$holidayDays Days',
                              color: AppColors.info,
                              icon: Icons.holiday_village_outlined,
                            ),
                          ),
                        ],
                      ),
                      20.h.height,

                      // Calendar Card
                      GlassCard(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary, size: 24.sp),
                                Text(
                                  '$monthName $year',
                                  style: context.h2.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24.sp),
                              ],
                            ),
                            18.h.height,

                            // Weekdays Headers row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                                return SizedBox(
                                  width: 32.w,
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }).toList(),
                            ),
                            12.h.height,

                            // Calendar Dates Grid Builder
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: daysInMonth + (firstWeekday - 1),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                              ),
                              itemBuilder: (context, i) {
                                final dayIndex = i - (firstWeekday - 1) + 1;
                                if (dayIndex <= 0) {
                                  return const SizedBox.shrink();
                                }

                                AttendanceRecord? record;
                                final matchedRecords = records.where((r) => r.date.day == dayIndex);
                                if (matchedRecords.isNotEmpty) {
                                  record = matchedRecords.first;
                                }

                                return _CalendarDayCell(day: dayIndex, record: record);
                              },
                            ),
                          ],
                        ),
                      ),

                      110.h.height, // Spacer for nav bar & FAB
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showMarkAttendanceSheet(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MarkAttendanceSheet(user: user, parentContext: context),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          12.w.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp, fontWeight: FontWeight.w600),
                ),
                4.h.height,
                Text(
                  value,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  final int day;
  final AttendanceRecord? record;

  const _CalendarDayCell({required this.day, this.record});

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color borderCol = Colors.transparent;
    Color textCol = AppColors.textPrimary;

    if (record != null) {
      switch (record!.status) {
        case AttendanceStatus.present:
          bgColor = AppColors.success.withOpacity(0.12);
          borderCol = AppColors.success.withOpacity(0.4);
          textCol = AppColors.success;
          break;
        case AttendanceStatus.absent:
          bgColor = AppColors.error.withOpacity(0.12);
          borderCol = AppColors.error.withOpacity(0.4);
          textCol = AppColors.error;
          break;
        case AttendanceStatus.late:
          bgColor = AppColors.warning.withOpacity(0.12);
          borderCol = AppColors.warning.withOpacity(0.4);
          textCol = AppColors.warning;
          break;
        case AttendanceStatus.holiday:
          bgColor = AppColors.info.withOpacity(0.08);
          borderCol = AppColors.info.withOpacity(0.3);
          textCol = AppColors.info;
          break;
      }
    } else {
      bgColor = Colors.transparent;
      textCol = AppColors.textMuted;
    }

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Text(
        '$day',
        style: TextStyle(
          color: textCol,
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MarkAttendanceSheet extends StatefulWidget {
  final UserModel? user;
  final BuildContext parentContext;

  const _MarkAttendanceSheet({required this.user, required this.parentContext});

  @override
  State<_MarkAttendanceSheet> createState() => _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends State<_MarkAttendanceSheet> {
  late DateTime _selectedDate;
  late AttendanceStatus _selectedStatus;
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late String _attendanceType;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedStatus = AttendanceStatus.present;

    String roleName = widget.user?.role.name ?? 'student';
    if (roleName == 'teacher' || roleName == 'staff' || roleName == 'masterAdmin' || roleName == 'admin') {
      _attendanceType = roleName == 'teacher' ? 'student' : 'staff';
    } else {
      _attendanceType = 'student';
    }

    _nameController = TextEditingController(text: widget.user?.name ?? 'Rohan Sharma');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mark Attendance', style: context.h2),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          16.h.height,

          // Attendance Type Selector
          Text('Attendance Category', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          8.h.height,
          Row(
            children: [
              _TypeChip(
                label: 'Student',
                isSelected: _attendanceType == 'student',
                onTap: () => setState(() => _attendanceType = 'student'),
              ),
              10.w.width,
              _TypeChip(
                label: 'Teacher',
                isSelected: _attendanceType == 'teacher',
                onTap: () => setState(() => _attendanceType = 'teacher'),
              ),
              10.w.width,
              _TypeChip(
                label: 'Staff',
                isSelected: _attendanceType == 'staff',
                onTap: () => setState(() => _attendanceType = 'staff'),
              ),
            ],
          ),
          16.h.height,

          // Status Selector
          Text('Attendance Status', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          8.h.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusOption(
                label: 'Present',
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
                isSelected: _selectedStatus == AttendanceStatus.present,
                onTap: () => setState(() => _selectedStatus = AttendanceStatus.present),
              ),
              _StatusOption(
                label: 'Absent',
                color: AppColors.error,
                icon: Icons.cancel_rounded,
                isSelected: _selectedStatus == AttendanceStatus.absent,
                onTap: () => setState(() => _selectedStatus = AttendanceStatus.absent),
              ),
              _StatusOption(
                label: 'Late',
                color: AppColors.warning,
                icon: Icons.access_time_filled_rounded,
                isSelected: _selectedStatus == AttendanceStatus.late,
                onTap: () => setState(() => _selectedStatus = AttendanceStatus.late),
              ),
              _StatusOption(
                label: 'Holiday',
                color: AppColors.info,
                icon: Icons.beach_access_rounded,
                isSelected: _selectedStatus == AttendanceStatus.holiday,
                onTap: () => setState(() => _selectedStatus = AttendanceStatus.holiday),
              ),
            ],
          ),
          16.h.height,

          // Member Name
          Text('Name / Class Target', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          8.h.height,
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter name or class (e.g. Rohan Sharma)',
              filled: true,
              fillColor: AppColors.background,
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          16.h.height,

          // Notes / Reason
          Text('Notes / Reason (Optional)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
          8.h.height,
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'e.g. On-time check in, Medical leave note',
              filled: true,
              fillColor: AppColors.background,
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          24.h.height,

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              ),
              onPressed: () {
                final record = AttendanceRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: _selectedDate,
                  status: _selectedStatus,
                  notes: _notesController.text.trim().isEmpty ? 'Marked via App' : _notesController.text.trim(),
                  name: _nameController.text.trim(),
                  className: widget.user?.className ?? 'Class 10-A',
                  department: widget.user?.department ?? 'General',
                  attendanceType: _attendanceType,
                );

                widget.parentContext.read<SchoolBloc>().add(MarkAttendanceRequested(record));
                Navigator.pop(context);
              },
              child: Text('Submit Attendance', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22.sp),
            6.h.height,
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textMuted,
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
