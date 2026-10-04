import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../widgets/glass_card.dart';

class LessonItem {
  final String id;
  final String title;
  final String chapter;
  final String className;
  final String subject;
  final String duration;
  final String date;
  final String objectives;
  bool isCompleted;
  final bool isInProgress;

  LessonItem({
    required this.id,
    required this.title,
    required this.chapter,
    required this.className,
    required this.subject,
    required this.duration,
    required this.date,
    required this.objectives,
    this.isCompleted = false,
    this.isInProgress = false,
  });
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String _selectedClass = 'All Classes';

  final List<LessonItem> _lessons = [
    LessonItem(
      id: '1',
      title: 'Newton\'s Laws of Motion & Gravitation',
      chapter: 'Chapter 1: Force & Laws of Motion',
      className: 'Class 9-A',
      subject: 'Science',
      duration: '4 Lectures (45 mins each)',
      date: 'Completed on Sep 28',
      objectives: 'Understand inertia, momentum, and apply second law formulas to real-world scenarios.',
      isCompleted: true,
      isInProgress: false,
    ),
    LessonItem(
      id: '2',
      title: 'Structure of the Atom & Subatomic Particles',
      chapter: 'Chapter 2: Atoms and Molecules',
      className: 'Class 9-A',
      subject: 'Science',
      duration: '3 Lectures (45 mins each)',
      date: 'Ongoing • Started Oct 2',
      objectives: 'Differentiate Thomson, Rutherford, and Bohr models; understand valence electrons.',
      isCompleted: false,
      isInProgress: true,
    ),
    LessonItem(
      id: '3',
      title: 'Chemical Reactions & Balancing Equations',
      chapter: 'Chapter 1: Chemical Reactions',
      className: 'Class 10-A',
      subject: 'Chemistry',
      duration: '5 Lectures (45 mins each)',
      date: 'Planned for Oct 10',
      objectives: 'Master combination, decomposition, displacement, and redox reactions with lab practicals.',
      isCompleted: false,
      isInProgress: false,
    ),
    LessonItem(
      id: '4',
      title: 'Electric Current & Ohm\'s Law Application',
      chapter: 'Chapter 3: Electricity',
      className: 'Class 10-A',
      subject: 'Physics',
      duration: '4 Lectures (45 mins each)',
      date: 'Planned for Oct 18',
      objectives: 'Calculate resistance in series and parallel circuits; apply Joule\'s heating law.',
      isCompleted: false,
      isInProgress: false,
    ),
    LessonItem(
      id: '5',
      title: 'Cell: The Fundamental Unit of Life',
      chapter: 'Chapter 5: Cell Biology',
      className: 'Class 9-B',
      subject: 'Biology',
      duration: '3 Lectures (45 mins each)',
      date: 'Completed on Sep 22',
      objectives: 'Analyze plant vs animal cell organelles, osmosis, and diffusion mechanisms.',
      isCompleted: true,
      isInProgress: false,
    ),
  ];

  void _showAddLessonDialog() {
    final titleCtrl = TextEditingController();
    final chapterCtrl = TextEditingController();
    final objectivesCtrl = TextEditingController();
    String selectedClass = 'Class 9-A';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add New Lesson Plan', style: context.h2),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    14.h.height,
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(labelText: 'Target Class'),
                      items: ['Class 9-A', 'Class 9-B', 'Class 10-A', 'Class 10-B']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedClass = val!),
                    ),
                    12.h.height,
                    TextField(
                      controller: chapterCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chapter Name',
                        hintText: 'e.g. Chapter 4: Carbon & Its Compounds',
                      ),
                    ),
                    12.h.height,
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Title',
                        hintText: 'e.g. Covalent Bonding & Allotropes of Carbon',
                      ),
                    ),
                    12.h.height,
                    TextField(
                      controller: objectivesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Learning Objectives',
                        hintText: 'Describe key outcomes students should achieve...',
                      ),
                    ),
                    20.h.height,
                    ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.isNotEmpty) {
                          setState(() {
                            _lessons.add(
                              LessonItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text.trim(),
                                chapter: chapterCtrl.text.isNotEmpty ? chapterCtrl.text.trim() : 'General Topic',
                                className: selectedClass,
                                subject: 'Science',
                                duration: '3 Lectures',
                                date: 'Created Today',
                                objectives: objectivesCtrl.text.isNotEmpty
                                    ? objectivesCtrl.text.trim()
                                    : 'Cover foundational concepts and classroom exercises.',
                                isCompleted: false,
                                isInProgress: false,
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                          context.showAppSnackBar('New lesson plan added successfully!');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: const Text('Save Lesson Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedClass == 'All Classes'
        ? _lessons
        : _lessons.where((l) => l.className == _selectedClass).toList();

    final completedCount = _lessons.where((l) => l.isCompleted).length;
    final inProgressCount = _lessons.where((l) => l.isInProgress).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Lesson Planning', style: context.h2.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'Add Lesson',
            onPressed: _showAddLessonDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLessonDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text('Add Lesson Plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Dashboard Banner
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.all(14.w),
                    borderColor: AppColors.success.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed', style: context.mutedText),
                        6.h.height,
                        Text('$completedCount', style: context.h2.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
                ),
                10.w.width,
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.all(14.w),
                    borderColor: AppColors.warning.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('In Progress', style: context.mutedText),
                        6.h.height,
                        Text('$inProgressCount', style: context.h2.copyWith(color: AppColors.warning)),
                      ],
                    ),
                  ),
                ),
                10.w.width,
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.all(14.w),
                    borderColor: AppColors.primary.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Lessons', style: context.mutedText),
                        6.h.height,
                        Text('${_lessons.length}', style: context.h2.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            16.h.height,

            // Filter Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All Classes', 'Class 9-A', 'Class 9-B', 'Class 10-A'].map((cls) {
                  final isSelected = _selectedClass == cls;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text(cls),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedClass = cls),
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
            16.h.height,

            // Lesson Cards List
            ...filtered.map((item) => _buildLessonCard(context, item)),

            60.h.height,
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, LessonItem item) {
    Color badgeColor;
    String statusLabel;
    if (item.isCompleted) {
      badgeColor = AppColors.success;
      statusLabel = 'Completed';
    } else if (item.isInProgress) {
      badgeColor = AppColors.warning;
      statusLabel = 'In Progress';
    } else {
      badgeColor = AppColors.textMuted;
      statusLabel = 'Upcoming';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: item.isInProgress ? AppColors.warning.withOpacity(0.5) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    item.className,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ],
            ),
            8.h.height,
            Text(item.chapter, style: context.mutedText),
            4.h.height,
            Text(item.title, style: context.bodyBold.copyWith(fontSize: 15.sp)),
            8.h.height,
            Text(
              item.objectives,
              style: context.caption.copyWith(color: AppColors.textSecondary),
            ),
            12.h.height,
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14.sp, color: AppColors.textMuted),
                4.w.width,
                Text(item.duration, style: context.mutedText),
                16.w.width,
                Icon(Icons.calendar_today_outlined, size: 14.sp, color: AppColors.textMuted),
                4.w.width,
                Text(item.date, style: context.mutedText),
              ],
            ),
            12.h.height,
            const Divider(color: AppColors.border, height: 1),
            8.h.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      item.isCompleted = !item.isCompleted;
                    });
                    context.showAppSnackBar(
                      item.isCompleted ? 'Marked as completed!' : 'Marked as pending!',
                    );
                  },
                  icon: Icon(
                    item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 16.sp,
                    color: item.isCompleted ? AppColors.success : AppColors.primary,
                  ),
                  label: Text(
                    item.isCompleted ? 'Completed' : 'Mark Complete',
                    style: TextStyle(
                      color: item.isCompleted ? AppColors.success : AppColors.primary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
