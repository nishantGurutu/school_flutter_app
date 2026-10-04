import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../widgets/glass_card.dart';

class CalendarEvent {
  final String title;
  final String dateRange;
  final String month;
  final String day;
  final String category; // 'Exam', 'Holiday', 'Event', 'Meeting', 'Vacation'
  final String description;
  final Color color;

  const CalendarEvent({
    required this.title,
    required this.dateRange,
    required this.month,
    required this.day,
    required this.category,
    required this.description,
    required this.color,
  });
}

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  String _selectedCategory = 'All';
  int _selectedMonthIndex = 9; // October (0-indexed: 9)

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<CalendarEvent> _events = const [
    CalendarEvent(
      title: 'Gandhi Jayanti',
      dateRange: 'Oct 02, 2026',
      month: 'OCT',
      day: '02',
      category: 'Holiday',
      description: 'National holiday in honor of Mahatma Gandhi.',
      color: AppColors.success,
    ),
    CalendarEvent(
      title: 'Mid-Term Examinations (Term 1)',
      dateRange: 'Oct 12 - Oct 20, 2026',
      month: 'OCT',
      day: '12',
      category: 'Exam',
      description: 'Summative assessment for classes 6 through 12 across all subjects.',
      color: AppColors.warning,
    ),
    CalendarEvent(
      title: 'Annual Science & Tech Fair',
      dateRange: 'Oct 24, 2026',
      month: 'OCT',
      day: '24',
      category: 'Event',
      description: 'Student exhibits, robotics demonstrations, and chemistry lab live models.',
      color: AppColors.primary,
    ),
    CalendarEvent(
      title: 'Parent-Teacher Meeting (PTM)',
      dateRange: 'Oct 31, 2026',
      month: 'OCT',
      day: '31',
      category: 'Meeting',
      description: 'Term 1 progress report discussion and student feedback session.',
      color: AppColors.info,
    ),
    CalendarEvent(
      title: 'Diwali & Chhath Puja Break',
      dateRange: 'Nov 08 - Nov 15, 2026',
      month: 'NOV',
      day: '08',
      category: 'Vacation',
      description: 'School remains closed for festival celebration and staff recess.',
      color: AppColors.error,
    ),
    CalendarEvent(
      title: 'Annual Athletic Meet & Sports Day',
      dateRange: 'Nov 28, 2026',
      month: 'NOV',
      day: '28',
      category: 'Event',
      description: 'Track and field events, inter-house relay, and prize distribution.',
      color: AppColors.secondary,
    ),
    CalendarEvent(
      title: 'Winter Vacation Commencement',
      dateRange: 'Dec 24 - Jan 02, 2027',
      month: 'DEC',
      day: '24',
      category: 'Vacation',
      description: 'Winter holiday break for students and faculty.',
      color: AppColors.info,
    ),
    CalendarEvent(
      title: 'Republic Day Celebration',
      dateRange: 'Jan 26, 2027',
      month: 'JAN',
      day: '26',
      category: 'Holiday',
      description: 'Flag hoisting ceremony, patriotic cultural performances.',
      color: AppColors.success,
    ),
    CalendarEvent(
      title: 'Final Term Board Mock Tests',
      dateRange: 'Feb 10 - Feb 18, 2027',
      month: 'FEB',
      day: '10',
      category: 'Exam',
      description: 'Comprehensive preparatory exams for Class 10 and Class 12.',
      color: AppColors.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _events.where((e) {
      if (_selectedCategory != 'All' && e.category != _selectedCategory) {
        return false;
      }
      return true;
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
            Text('Academic Calendar', style: context.h2.copyWith(color: AppColors.textPrimary)),
            Text('Session 2026 - 2027', style: context.caption.copyWith(color: AppColors.textMuted)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar Hero Banner
            GlassCard(
              padding: EdgeInsets.all(18.w),
              borderColor: AppColors.primary.withOpacity(0.3),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 28.sp),
                  ),
                  14.w.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('School Year Schedule', style: context.bodyBold.copyWith(fontSize: 15.sp)),
                        4.h.height,
                        Text(
                          'Track examinations, gazetted holidays, school terms, and extracurricular events.',
                          style: context.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            16.h.height,

            // Month Selector Scrollable Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(_months.length, (idx) {
                  final isSelected = _selectedMonthIndex == idx;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: InkWell(
                      onTap: () => setState(() => _selectedMonthIndex = idx),
                      borderRadius: BorderRadius.circular(12.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          _months[idx],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            16.h.height,

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All', 'Exam', 'Holiday', 'Event', 'Meeting', 'Vacation'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.sp,
                      ),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                }).toList(),
              ),
            ),
            18.h.height,

            // Event List
            if (filteredEvents.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 48.sp, color: AppColors.textMuted),
                      12.h.height,
                      Text('No events found for this filter', style: context.bodyBold),
                    ],
                  ),
                ),
              )
            else
              ...filteredEvents.map((evt) => _buildEventCard(context, evt)),

            40.h.height,
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent evt) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Badge (Left column)
            Container(
              width: 52.w,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: evt.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: evt.color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    evt.month,
                    style: TextStyle(
                      color: evt.color,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  2.h.height,
                  Text(
                    evt.day,
                    style: TextStyle(
                      color: evt.color,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            14.w.width,

            // Event Details (Right column)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          evt.title,
                          style: context.bodyBold.copyWith(fontSize: 14.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: evt.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          evt.category,
                          style: TextStyle(
                            color: evt.color,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  6.h.height,
                  Text(
                    evt.dateRange,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  4.h.height,
                  Text(
                    evt.description,
                    style: context.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
