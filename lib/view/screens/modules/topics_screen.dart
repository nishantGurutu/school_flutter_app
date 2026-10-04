import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../widgets/glass_card.dart';

class CurriculumTopic {
  final String id;
  final String title;
  final String chapter;
  final String subject;
  final String className;
  final int estimatedHours;
  final String difficulty;
  String status; // 'Covered', 'In Progress', 'Pending'

  CurriculumTopic({
    required this.id,
    required this.title,
    required this.chapter,
    required this.subject,
    required this.className,
    required this.estimatedHours,
    required this.difficulty,
    this.status = 'Pending',
  });
}

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  String _selectedSubject = 'All';
  String _searchQuery = '';

  final List<CurriculumTopic> _topics = [
    CurriculumTopic(
      id: '1',
      title: 'Newton\'s First & Second Laws of Motion',
      chapter: 'Force & Motion',
      subject: 'Physics',
      className: 'Class 9',
      estimatedHours: 3,
      difficulty: 'Medium',
      status: 'Covered',
    ),
    CurriculumTopic(
      id: '2',
      title: 'Universal Law of Gravitation & Free Fall',
      chapter: 'Gravitation',
      subject: 'Physics',
      className: 'Class 9',
      estimatedHours: 4,
      difficulty: 'Hard',
      status: 'In Progress',
    ),
    CurriculumTopic(
      id: '3',
      title: 'Atomic Number, Mass Number & Isotopes',
      chapter: 'Structure of the Atom',
      subject: 'Chemistry',
      className: 'Class 9',
      estimatedHours: 2,
      difficulty: 'Easy',
      status: 'Covered',
    ),
    CurriculumTopic(
      id: '4',
      title: 'Types of Chemical Reactions (Redox & Displacement)',
      chapter: 'Chemical Reactions',
      subject: 'Chemistry',
      className: 'Class 10',
      estimatedHours: 3,
      difficulty: 'Medium',
      status: 'Pending',
    ),
    CurriculumTopic(
      id: '5',
      title: 'Cell Organelles: Mitochondria & Golgi Apparatus',
      chapter: 'Cell Biology',
      subject: 'Biology',
      className: 'Class 9',
      estimatedHours: 2,
      difficulty: 'Easy',
      status: 'Covered',
    ),
    CurriculumTopic(
      id: '6',
      title: 'Respiration & Photosynthesis in Plants',
      chapter: 'Life Processes',
      subject: 'Biology',
      className: 'Class 10',
      estimatedHours: 4,
      difficulty: 'Hard',
      status: 'Pending',
    ),
    CurriculumTopic(
      id: '7',
      title: 'Ohm\'s Law, Resistance & Resistivity Factors',
      chapter: 'Electricity',
      subject: 'Physics',
      className: 'Class 10',
      estimatedHours: 4,
      difficulty: 'Medium',
      status: 'Pending',
    ),
  ];

  void _showAddTopicDialog() {
    final titleCtrl = TextEditingController();
    final chapterCtrl = TextEditingController();
    String subject = 'Physics';
    String className = 'Class 9';

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
                        Text('Add Syllabus Topic', style: context.h2),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    14.h.height,
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: subject,
                            decoration: const InputDecoration(labelText: 'Subject'),
                            items: ['Physics', 'Chemistry', 'Biology']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) => setModalState(() => subject = val!),
                          ),
                        ),
                        12.w.width,
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: className,
                            decoration: const InputDecoration(labelText: 'Class'),
                            items: ['Class 9', 'Class 10', 'Class 11', 'Class 12']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) => setModalState(() => className = val!),
                          ),
                        ),
                      ],
                    ),
                    12.h.height,
                    TextField(
                      controller: chapterCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Chapter Name',
                        hintText: 'e.g. Chapter 4: Light & Optics',
                      ),
                    ),
                    12.h.height,
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Topic Title',
                        hintText: 'e.g. Refraction of Light through a Glass Prism',
                      ),
                    ),
                    20.h.height,
                    ElevatedButton(
                      onPressed: () {
                        if (titleCtrl.text.isNotEmpty) {
                          setState(() {
                            _topics.add(
                              CurriculumTopic(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text.trim(),
                                chapter: chapterCtrl.text.isNotEmpty ? chapterCtrl.text.trim() : 'General',
                                subject: subject,
                                className: className,
                                estimatedHours: 3,
                                difficulty: 'Medium',
                                status: 'Pending',
                              ),
                            );
                          });
                          Navigator.pop(ctx);
                          context.showAppSnackBar('New topic added to curriculum!');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: const Text('Add Topic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final filtered = _topics.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.chapter.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedSubject == 'All') return matchesSearch;
      return matchesSearch && t.subject == _selectedSubject;
    }).toList();

    final coveredCount = _topics.where((t) => t.status == 'Covered').length;
    final totalHours = _topics.fold<int>(0, (sum, t) => sum + t.estimatedHours);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Curriculum Topics', style: context.h2.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip: 'Add Topic',
            onPressed: _showAddTopicDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTopicDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Topic', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Overview Banner
            Row(
              children: [
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.all(16.w),
                    borderColor: AppColors.success.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Topics Covered', style: context.mutedText),
                        6.h.height,
                        Text('$coveredCount / ${_topics.length}', style: context.h2.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
                ),
                12.w.width,
                Expanded(
                  child: GlassCard(
                    padding: EdgeInsets.all(16.w),
                    borderColor: AppColors.info.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Teaching Hours', style: context.mutedText),
                        6.h.height,
                        Text('$totalHours hrs', style: context.h2.copyWith(color: AppColors.info)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            16.h.height,

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search topic or chapter name...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            12.h.height,

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['All', 'Physics', 'Chemistry', 'Biology'].map((sub) {
                  final isSelected = _selectedSubject == sub;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: ChoiceChip(
                      label: Text(sub),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedSubject = sub),
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

            // Topic Items List
            ...filtered.map((item) => _buildTopicTile(context, item)),

            60.h.height,
          ],
        ),
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, CurriculumTopic item) {
    Color statusColor;
    if (item.status == 'Covered') {
      statusColor = AppColors.success;
    } else if (item.status == 'In Progress') {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.textMuted;
    }

    Color diffColor;
    if (item.difficulty == 'Hard') {
      diffColor = AppColors.error;
    } else if (item.difficulty == 'Medium') {
      diffColor = AppColors.warning;
    } else {
      diffColor = AppColors.success;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '${item.className} • ${item.subject}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  8.w.width,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: diffColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      item.difficulty,
                      style: TextStyle(color: diffColor, fontSize: 10.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    if (item.status == 'Pending') {
                      item.status = 'In Progress';
                    } else if (item.status == 'In Progress') {
                      item.status = 'Covered';
                    } else {
                      item.status = 'Pending';
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.status == 'Covered'
                            ? Icons.check_circle_rounded
                            : (item.status == 'In Progress' ? Icons.timelapse_rounded : Icons.pending_rounded),
                        size: 13.sp,
                        color: statusColor,
                      ),
                      4.w.width,
                      Text(
                        item.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          8.h.height,
          Text(item.title, style: context.bodyBold.copyWith(fontSize: 14.sp)),
          4.h.height,
          Text('Chapter: ${item.chapter} • Est. ${item.estimatedHours} hrs', style: context.mutedText),
        ],
      ),
    );
  }
}
