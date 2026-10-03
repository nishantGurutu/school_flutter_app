import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/school/school_bloc.dart';
import '../../../logic/school/school_event.dart';
import '../../../logic/school/school_state.dart';
import '../../../data/models/user_model.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    final wd = DateTime.now().weekday; // 1 = Mon, 6 = Sat, 7 = Sun
    if (wd >= 1 && wd <= 6) {
      _selectedDayIndex = wd - 1;
    } else {
      _selectedDayIndex = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTimetable(_days[_selectedDayIndex]);
    });
  }

  void _fetchTimetable(String day) {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState.user;
    context.read<SchoolBloc>().add(
      FetchTimetableRequested(
        userId: currentUser?.id ?? '1',
        className: currentUser?.className,
        day: day,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _days[_selectedDayIndex];
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState.user;
    final userRole = currentUser?.role ?? UserRole.student;

    String screenTitle;
    String contextSubtitle;
    IconData roleIcon;

    if (userRole == UserRole.student) {
      screenTitle = 'Class Timetable';
      contextSubtitle = '${currentUser?.className ?? 'Class 6-A'} • Student Schedule';
      roleIcon = Icons.school_rounded;
    } else if (userRole == UserRole.teacher) {
      screenTitle = 'Teacher Timetable';
      contextSubtitle = '${currentUser?.name ?? 'Teacher'} • Assigned Classes';
      roleIcon = Icons.co_present_rounded;
    } else if (userRole == UserRole.parent) {
      screenTitle = 'Child Timetable';
      contextSubtitle = currentUser?.details.isNotEmpty == true
          ? currentUser!.details
          : 'Child Class & Section Schedule';
      roleIcon = Icons.family_restroom_rounded;
    } else {
      screenTitle = 'School Timetable';
      contextSubtitle = 'Academic Desk Schedule';
      roleIcon = Icons.calendar_today_rounded;
    }

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
            Text(
              screenTitle,
              style: context.h2.copyWith(color: AppColors.textPrimary),
            ),
            2.h.height,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 12.sp, color: AppColors.primary),
                4.w.width,
                Text(
                  contextSubtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Sync Timetable',
            onPressed: () {
              _fetchTimetable(_days[_selectedDayIndex]);
            },
          ),
        ],
      ),
      body: BlocBuilder<SchoolBloc, SchoolState>(
        builder: (context, state) {
          // Filter slots by selected day (case-insensitive prefix match)
          final daySlots = state.timetable.where((s) {
            if (s.dayOfWeek.trim().isEmpty) return true;
            final slotDay = s.dayOfWeek.toLowerCase().trim();
            final targetDay = selectedDay.toLowerCase().trim();
            return slotDay == targetDay || slotDay.startsWith(targetDay) || targetDay.startsWith(slotDay);
          }).toList();

          // Sort chronologically by start time
          daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));

          return RefreshIndicator(
            onRefresh: () async {
              _fetchTimetable(_days[_selectedDayIndex]);
            },
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Day Selector Tab Bar
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
                      return GestureDetector(
                        onTap: () {
                          if (_selectedDayIndex != i) {
                            setState(() {
                              _selectedDayIndex = i;
                            });
                            _fetchTimetable(_days[i]);
                          }
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
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            day,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Slots List
                Expanded(
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : daySlots.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 120.h),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_busy_rounded, size: 52.sp, color: AppColors.textMuted),
                                  12.h.height,
                                  Text(
                                    'No classes scheduled for $selectedDay',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  6.h.height,
                                  Text(
                                    'Admin timetable changes reflect here in real-time',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                            } else if (slot.subject.contains('Social') || slot.subject.contains('History')) {
                              badgeCol = Colors.purple;
                            } else if (slot.subject.contains('Computer') || slot.subject.contains('Coding')) {
                              badgeCol = Colors.teal;
                            } else if (slot.subject.contains('Hindi') || slot.subject.contains('Art') || slot.subject.contains('Sport')) {
                              badgeCol = AppColors.warning;
                            }

                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  // Time Column
                                  SizedBox(
                                    width: 78.w,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          slot.startTime,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        2.h.height,
                                        Text(
                                          'to ${slot.endTime}',
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                        if (slot.periodName != null && slot.periodName!.isNotEmpty) ...[
                                          4.h.height,
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: badgeCol.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              slot.periodName!,
                                              style: TextStyle(
                                                color: badgeCol,
                                                fontSize: 8.5.sp,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Divider Line
                                  Container(
                                    width: 2.5,
                                    height: 50.h,
                                    decoration: BoxDecoration(
                                      color: badgeCol,
                                      borderRadius: BorderRadius.circular(2.r),
                                    ),
                                  ),
                                  14.w.width,

                                  // Subject & Details
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
                                        if (userRole == UserRole.teacher) ...[
                                          Row(
                                            children: [
                                              Icon(Icons.groups_outlined, color: AppColors.textMuted, size: 12.sp),
                                              4.w.width,
                                              Text(
                                                slot.className != null && slot.className!.isNotEmpty
                                                    ? '${slot.className} (${slot.section ?? 'A'})'
                                                    : 'Class 6-A',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 11.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          Row(
                                            children: [
                                              Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 12.sp),
                                              4.w.width,
                                              Expanded(
                                                child: Text(
                                                  slot.teacherName.isNotEmpty ? slot.teacherName : 'Assigned Teacher',
                                                  style: TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 11.sp,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Room Badge
                                  if (slot.classroom.isNotEmpty)
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
                30.h.height,
              ],
            ),
          );
        },
      ),
    );
  }
}
