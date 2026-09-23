import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/extensions/context_extensions.dart';
import '../../data/models/school_models.dart';
import '../../data/models/user_model.dart';
import '../../logic/school/school_bloc.dart';
import '../../logic/school/school_event.dart';
import '../../logic/school/school_state.dart';
import 'glass_card.dart';

class AttendanceCheckInBanner extends StatelessWidget {
  final UserModel user;

  const AttendanceCheckInBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return BlocListener<SchoolBloc, SchoolState>(
      listenWhen: (prev, curr) =>
          (curr.errorMessage != null &&
              prev.errorMessage != curr.errorMessage) ||
          (curr.actionSuccessMessage != null &&
              prev.actionSuccessMessage != curr.actionSuccessMessage),
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state.actionSuccessMessage != null &&
            state.actionSuccessMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionSuccessMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<SchoolBloc, SchoolState>(
        builder: (context, state) {
          AttendanceRecord? todayRecord;
          try {
            todayRecord = state.attendance.firstWhere(
              (r) =>
                  r.date.year == today.year &&
                  r.date.month == today.month &&
                  r.date.day == today.day,
            );
          } catch (_) {
            todayRecord = null;
          }

          final bool hasCheckedIn = todayRecord?.checkInTime != null;
          final bool hasCheckedOut = todayRecord?.checkOutTime != null;
          final String checkInTimeStr = todayRecord?.checkInTime ?? '--:--';
          final String checkOutTimeStr = todayRecord?.checkOutTime ?? '--:--';

          return GlassCard(
            padding: EdgeInsets.all(16.w),
            borderColor: hasCheckedIn
                ? AppColors.success.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Icon, Date, Status Badge
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color:
                            (hasCheckedIn
                                    ? AppColors.success
                                    : AppColors.primary)
                                .withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasCheckedIn
                              ? AppColors.success
                              : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        hasCheckedIn
                            ? Icons.check_circle_rounded
                            : Icons.fingerprint_rounded,
                        color: hasCheckedIn
                            ? AppColors.success
                            : AppColors.primary,
                        size: 24.sp,
                      ),
                    ),
                    12.w.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Attendance",
                            style: context.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          2.h.height,
                          Text(
                            '${_getDayName(today.weekday)}, ${today.day} ${_getMonthName(today.month)} ${today.year}',
                            style: context.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      hasCheckedIn: hasCheckedIn,
                      hasCheckedOut: hasCheckedOut,
                    ),
                  ],
                ),
                14.h.height,

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check In',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          4.h.height,
                          Row(
                            children: [
                              Icon(
                                Icons.login_rounded,
                                size: 14.sp,
                                color: hasCheckedIn
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                              6.w.width,
                              Text(
                                checkInTimeStr,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: hasCheckedIn
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        height: 28.h,
                        width: 1.w,
                        color: AppColors.border,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check Out',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          4.h.height,
                          Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 14.sp,
                                color: hasCheckedOut
                                    ? AppColors.info
                                    : AppColors.textMuted,
                              ),
                              6.w.width,
                              Text(
                                checkOutTimeStr,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: hasCheckedOut
                                      ? AppColors.info
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        height: 28.h,
                        width: 1.w,
                        color: AppColors.border,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'User ID',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          4.h.height,
                          Text(
                            user.name.split(' ').first,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                14.h.height,

                // Action Buttons Row (Direct Check-In / Check-Out for Logged-In User)
                if (!hasCheckedIn)
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 2,
                      ),
                      icon: state.isActionInProgress
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.touch_app_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                      label: Text(
                        'CHECK IN NOW',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: state.isActionInProgress
                          ? null
                          : () {
                              context.read<SchoolBloc>().add(
                                CheckInUserRequested(
                                  userId: user.id,
                                  name: user.name,
                                  className: user.className,
                                  role: user.role.name,
                                ),
                              );
                            },
                    ),
                  )
                else if (!hasCheckedOut)
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 2,
                      ),
                      icon: state.isActionInProgress
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.exit_to_app_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                      label: Text(
                        'CHECK OUT NOW',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: state.isActionInProgress
                          ? null
                          : () {
                              context.read<SchoolBloc>().add(
                                CheckOutUserRequested(
                                  userId: user.id,
                                  name: user.name,
                                  className: user.className,
                                  role: user.role.name,
                                ),
                              );
                            },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 18.sp,
                        ),
                        8.w.width,
                        Text(
                          'Attendance Completed for Today',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
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
    );
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  String _getMonthName(int month) {
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
      'Dec',
    ];
    return months[month - 1];
  }
}

class _StatusBadge extends StatelessWidget {
  final bool hasCheckedIn;
  final bool hasCheckedOut;

  const _StatusBadge({required this.hasCheckedIn, required this.hasCheckedOut});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    if (hasCheckedOut) {
      color = AppColors.info;
      text = 'Checked Out';
    } else if (hasCheckedIn) {
      color = AppColors.success;
      text = 'Checked In';
    } else {
      color = AppColors.warning;
      text = 'Not Checked In';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          6.w.width,
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
