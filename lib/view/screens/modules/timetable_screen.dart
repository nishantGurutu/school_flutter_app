import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_state.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  int _selectedDayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedDay = _days[_selectedDayIndex];
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
          'School Timetable',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SchoolBloc, SchoolState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final daySlots = state.timetable.where((s) => s.dayOfWeek == selectedDay).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 46.h,
                margin: EdgeInsets.symmetric(vertical: 12.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: _days.length,
                  itemBuilder: (context, i) {
                    final day = _days[i];
                    final isSelected = _selectedDayIndex == i;
                    final activeColor = isSelected ? AppColors.primary : Colors.transparent;
                    final textCol = isSelected ? Colors.white : AppColors.textSecondary;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDayIndex = i;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 10.w),
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            color: textCol,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: daySlots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy_rounded, size: 48.sp, color: AppColors.textMuted),
                            12.h.height,
                            Text(
                              'No classes scheduled for $selectedDay',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                        itemCount: daySlots.length,
                        itemBuilder: (context, i) {
                          final slot = daySlots[i];
                          Color badgeCol = AppColors.primary;
                          if (slot.subject.contains('Math')) {
                            badgeCol = AppColors.primary;
                          } else if (slot.subject.contains('Science') || slot.subject.contains('Physic') || slot.subject.contains('Chemis')) {
                            badgeCol = AppColors.info;
                          } else if (slot.subject.contains('English')) {
                            badgeCol = AppColors.secondary;
                          } else if (slot.subject.contains('Art') || slot.subject.contains('Lib') || slot.subject.contains('Sport')) {
                            badgeCol = AppColors.warning;
                          }
                          return Container(
                            margin: EdgeInsets.only(bottom: 14.h),
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 75.w,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        slot.startTime.split(' ').first,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        slot.startTime.split(' ').last,
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      4.h.height,
                                      Text(
                                        'to ${slot.endTime}',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 2.5,
                                  height: 45.h,
                                  color: badgeCol.withOpacity(0.4),
                                ),
                                16.w.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot.subject,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      4.h.height,
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 12.sp),
                                          4.w.width,
                                          Text(
                                            slot.teacherName,
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: badgeCol.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(color: badgeCol.withOpacity(0.25)),
                                  ),
                                  child: Text(
                                    slot.classroom,
                                    style: TextStyle(
                                      color: badgeCol,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              100.h.height,  
            ],
          );
        },
      ),
    );
  }
}
