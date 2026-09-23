import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_state.dart';
import '../../../data/models/school_models.dart';
import '../../widgets/glass_card.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isInline;

  const AttendanceScreen({super.key, this.isInline = false});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _focusedMonth = DateTime.now();
  int _selectedDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: widget.isInline
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: Text(
              'Attendance History',
              style: context.h2.copyWith(color: AppColors.textPrimary),
            ),
            centerTitle: true,
          ),
          body: BlocBuilder<SchoolBloc, SchoolState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final allRecords = state.attendance;

              // Filter records dynamically for currently focused month and year
              final monthRecords = allRecords.where((r) {
                return r.date.year == _focusedMonth.year &&
                    r.date.month == _focusedMonth.month;
              }).toList();

              // Calculate 4 top metric boxes dynamically based on filtered month attendance
              final totalWorkingDays = monthRecords
                  .where((r) => r.status != AttendanceStatus.holiday)
                  .length;
              final presentDays = monthRecords
                  .where((r) =>
                      r.status == AttendanceStatus.present ||
                      r.status == AttendanceStatus.late)
                  .length;
              final absentDays = monthRecords
                  .where((r) => r.status == AttendanceStatus.absent)
                  .length;
              final holidayDays = monthRecords
                  .where((r) => r.status == AttendanceStatus.holiday)
                  .length;

              final double rate = totalWorkingDays > 0
                  ? ((presentDays / totalWorkingDays) * 100.0)
                  : (monthRecords.isNotEmpty ? 100.0 : 0.0);

              final year = _focusedMonth.year;
              final month = _focusedMonth.month;
              final daysInMonth = DateTime(year, month + 1, 0).day;
              final firstWeekday = DateTime(year, month, 1).weekday;
              final String monthName = _getMonthName(month);

              // Find record for currently selected day in focused month
              AttendanceRecord? selectedRecord;
              final matchedSelected =
                  monthRecords.where((r) => r.date.day == _selectedDay);
              if (matchedSelected.isNotEmpty) {
                selectedRecord = matchedSelected.first;
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role Context Header Card (Read-only View)
                    if (user != null)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                'Date-wise View',
                                style: TextStyle(
                                  color: AppColors.info,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Dynamic 4 Metrics Cards Row (Calculated from API records)
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
                            value: '$presentDays/$totalWorkingDays',
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

                    // Interactive Calendar Card with Dynamic Month Switching
                    GlassCard(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.chevron_left_rounded,
                                    color: AppColors.textPrimary, size: 28.sp),
                                onPressed: () {
                                  setState(() {
                                    _focusedMonth = DateTime(_focusedMonth.year,
                                        _focusedMonth.month - 1, 1);
                                    _selectedDay = 1;
                                  });
                                },
                              ),
                              Text(
                                '$monthName $year',
                                style: context.h2
                                    .copyWith(fontWeight: FontWeight.w800),
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textPrimary, size: 28.sp),
                                onPressed: () {
                                  setState(() {
                                    _focusedMonth = DateTime(_focusedMonth.year,
                                        _focusedMonth.month + 1, 1);
                                    _selectedDay = 1;
                                  });
                                },
                              ),
                            ],
                          ),
                          14.h.height,

                          // Weekdays Headers row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                .map((day) {
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

                          // Calendar Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: daysInMonth + (firstWeekday - 1),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                              final matchedRecords = monthRecords
                                  .where((r) => r.date.day == dayIndex);
                              if (matchedRecords.isNotEmpty) {
                                record = matchedRecords.first;
                              }

                              return _CalendarDayCell(
                                day: dayIndex,
                                record: record,
                                isSelected: _selectedDay == dayIndex,
                                onTap: () {
                                  setState(() {
                                    _selectedDay = dayIndex;
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    20.h.height,

                    // Date-wise Specific Attendance Detail Section
                    Text(
                      'Attendance Details for $_selectedDay $monthName $year',
                      style: context.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                    12.h.height,
                    _DateDetailCard(
                      day: _selectedDay,
                      monthName: monthName,
                      year: year,
                      record: selectedRecord,
                      userName: user?.name ?? 'Student Account',
                    ),

                    110.h.height, // Spacer for nav bar
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
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
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600),
                ),
                4.h.height,
                Text(
                  value,
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold),
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
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    this.record,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color borderCol = isSelected ? AppColors.primary : Colors.transparent;
    Color textCol = AppColors.textPrimary;

    if (record != null) {
      switch (record!.status) {
        case AttendanceStatus.present:
          bgColor = AppColors.success.withOpacity(0.15);
          textCol = AppColors.success;
          break;
        case AttendanceStatus.absent:
          bgColor = AppColors.error.withOpacity(0.15);
          textCol = AppColors.error;
          break;
        case AttendanceStatus.late:
          bgColor = AppColors.warning.withOpacity(0.15);
          textCol = AppColors.warning;
          break;
        case AttendanceStatus.holiday:
          bgColor = AppColors.info.withOpacity(0.12);
          textCol = AppColors.info;
          break;
      }
    } else {
      bgColor = Colors.transparent;
      textCol = AppColors.textMuted;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.25) : bgColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : borderCol,
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            color: isSelected ? AppColors.primary : textCol,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DateDetailCard extends StatelessWidget {
  final int day;
  final String monthName;
  final int year;
  final AttendanceRecord? record;
  final String userName;

  const _DateDetailCard({
    required this.day,
    required this.monthName,
    required this.year,
    this.record,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.textMuted;
    String statusLabel = 'NO RECORD';

    if (record != null) {
      switch (record!.status) {
        case AttendanceStatus.present:
          statusColor = AppColors.success;
          statusLabel = 'PRESENT';
          break;
        case AttendanceStatus.absent:
          statusColor = AppColors.error;
          statusLabel = 'ABSENT';
          break;
        case AttendanceStatus.late:
          statusColor = AppColors.warning;
          statusLabel = 'LATE';
          break;
        case AttendanceStatus.holiday:
          statusColor = AppColors.info;
          statusLabel = 'HOLIDAY';
          break;
      }
    }

    final String checkInStr = record?.checkInTime ??
        (record?.status == AttendanceStatus.present ||
                record?.status == AttendanceStatus.late
            ? '09:00 AM'
            : 'Not Recorded');

    final String checkOutStr = record?.checkOutTime ??
        (record?.status == AttendanceStatus.present ||
                record?.status == AttendanceStatus.late
            ? '04:30 PM'
            : 'Not Recorded');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event_note_rounded,
                      color: AppColors.primary, size: 20.sp),
                  8.w.width,
                  Text(
                    '$day $monthName $year',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          14.h.height,
          const Divider(color: AppColors.border, height: 1),
          14.h.height,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-In Time',
                      style: TextStyle(
                          fontSize: 11.sp, color: AppColors.textMuted),
                    ),
                    4.h.height,
                    Text(
                      checkInStr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: checkInStr != 'Not Recorded'
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-Out Time',
                      style: TextStyle(
                          fontSize: 11.sp, color: AppColors.textMuted),
                    ),
                    4.h.height,
                    Text(
                      checkOutStr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: checkOutStr != 'Not Recorded'
                            ? AppColors.info
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          12.h.height,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes & Details',
                style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
              ),
              4.h.height,
              Text(
                record?.notes ??
                    (record?.status == AttendanceStatus.holiday
                        ? 'Official School Holiday'
                        : (record != null
                            ? 'Attendance recorded for $userName'
                            : 'No attendance record found for this date')),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
