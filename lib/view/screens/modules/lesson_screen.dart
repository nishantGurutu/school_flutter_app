import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/smooth_skeleton.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, this.initialClassName});

  final String? initialClassName;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  List<TeacherLessonModel> _lessons = [];
  bool _isLoading = true;
  String _selectedClass = 'All Classes';
  List<String> _assignedClasses = [];
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.initialClassName ?? _selectedClass;
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final version = ++_loadVersion;
    setState(() => _isLoading = true);
    final classes = await _repository.getTeacherClasses();
    if (!mounted || version != _loadVersion) return;
    final names = classes
        .map((c) => c.className.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (!names.contains(_selectedClass)) {
      _selectedClass = names.isEmpty ? 'All Classes' : names.first;
    }
    final selected = _selectedClass;
    final data = names.isEmpty
        ? <TeacherLessonModel>[]
        : await _repository.getTeacherLessons(
            className: selected == 'All Classes' ? null : selected,
          );
    if (mounted && version == _loadVersion) {
      setState(() {
        _assignedClasses = names;
        _lessons = data;
        _isLoading = false;
      });
    }
  }

  void _showAddLessonDialog() {
    if (_assignedClasses.isEmpty || _isLoading) return;
    final chapterNoCtrl = TextEditingController(
      text: 'Chapter ${_lessons.length + 1}',
    );
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String chosenClass = _selectedClass == 'All Classes'
        ? _assignedClasses.first
        : _selectedClass;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                        Text(
                          'Add New Lesson / Chapter',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    14.h.height,
                    TextField(
                      controller: chapterNoCtrl,
                      decoration: InputDecoration(
                        labelText: 'Chapter Number',
                        hintText: 'e.g. Chapter 1',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    12.h.height,
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Lesson / Chapter Title',
                        hintText: 'e.g. Laws of Motion & Gravitation',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    12.h.height,
                    DropdownButtonFormField<String>(
                      initialValue: chosenClass,
                      decoration: InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      items: _assignedClasses.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => chosenClass = val);
                      },
                    ),
                    12.h.height,
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description / Learning Objectives',
                        hintText: 'Key topics covered in this lesson...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    16.h.height,
                    ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        await _repository.createTeacherLesson(
                          className: chosenClass,
                          chapterNumber: chapterNoCtrl.text.trim(),
                          chapterTitle: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                        );
                        _loadLessons();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Save Lesson',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  void _showAddTopicDialog(TeacherLessonModel lesson) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final minCtrl = TextEditingController(text: '30');
    String difficulty = 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                        Expanded(
                          child: Text(
                            'Add Topic to ${lesson.chapterNumber}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    14.h.height,
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Topic Title',
                        hintText:
                            'e.g. Newton\'s Second Law & Practical Problems',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    12.h.height,
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: difficulty,
                            decoration: InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                            ),
                            items: ['Easy', 'Medium', 'Hard'].map((d) {
                              return DropdownMenuItem(value: d, child: Text(d));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => difficulty = val);
                              }
                            },
                          ),
                        ),
                        10.w.width,
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Est. Duration (Mins)',
                              hintText: '30',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                            ),
                          ),
                        ),
                      ],
                    ),
                    12.h.height,
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Topic Overview',
                        hintText: 'Summary notes or formula highlights...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    16.h.height,
                    ElevatedButton(
                      onPressed: () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        await _repository.addLessonTopic(
                          lessonId: lesson.id.toString(),
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          difficulty: difficulty,
                          estimatedMinutes:
                              int.tryParse(minCtrl.text.trim()) ?? 30,
                        );
                        _loadLessons();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Add Topic',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  void _confirmDeleteLesson(TeacherLessonModel lesson) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lesson?'),
        content: Text(
          'Are you sure you want to remove "${lesson.chapterNumber}: ${lesson.chapterTitle}" and its topics?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _repository.deleteLesson(lesson.id.toString());
              _loadLessons();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lessons & Topics',
          style: context.h2.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Reload Lessons',
            onPressed: _loadLessons,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _assignedClasses.isEmpty || _isLoading
            ? null
            : _showAddLessonDialog,
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Lesson',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
      ),
      body: _isLoading
          ? const SmoothSkeletonCardList(count: 3)
          : RefreshIndicator(
              onRefresh: _loadLessons,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Class Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: ['All Classes', ..._assignedClasses].map((c) {
                          final isSelected = _selectedClass == c;
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: ChoiceChip(
                              label: Text(c),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedClass = c);
                                _loadLessons();
                              },
                              selectedColor: const Color(0xFF059669),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 12.sp,
                              ),
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF059669)
                                      : AppColors.border,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    16.h.height,

                    if (_lessons.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Column(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 48.sp,
                                color: AppColors.textMuted,
                              ),
                              12.h.height,
                              Text(
                                'No lessons created yet',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              6.h.height,
                              Text(
                                _assignedClasses.isEmpty
                                    ? 'No classes assigned to you yet.'
                                    : 'Tap "+ New Lesson" below to create one.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _lessons.length,
                        separatorBuilder: (_, _) => 14.h.height,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return _buildLessonCard(context, lesson);
                        },
                      ),
                    80.h.height,
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLessonCard(BuildContext context, TeacherLessonModel lesson) {
    return GlassCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${lesson.chapterNumber} • ${lesson.className}',
                  style: TextStyle(
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20.sp,
                      color: const Color(0xFF059669),
                    ),
                    tooltip: 'Add Topic',
                    onPressed: () => _showAddTopicDialog(lesson),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20.sp,
                      color: AppColors.error,
                    ),
                    tooltip: 'Delete Lesson',
                    onPressed: () => _confirmDeleteLesson(lesson),
                  ),
                ],
              ),
            ],
          ),
          8.h.height,
          Text(
            lesson.chapterTitle,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (lesson.description.isNotEmpty) ...[
            6.h.height,
            Text(
              lesson.description,
              style: TextStyle(
                fontSize: 12.5.sp,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
          12.h.height,
          InkWell(
            onTap: () => _showChapterTopics(lesson),
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.list_alt_rounded,
                        size: 16.sp,
                        color: const Color(0xFF059669),
                      ),
                      8.w.width,
                      Text(
                        'Topics (${lesson.topics.length})',
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChapterTopics(TeacherLessonModel lesson) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.chapterTitle,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                '${lesson.chapterNumber} • ${lesson.className} • Topics (${lesson.topics.length})',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              16.h.height,
              Expanded(
                child: lesson.topics.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Center(
                          child: Text(
                            'No topics added. Tap "+" to add a topic.',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: lesson.topics.length,
                        separatorBuilder: (_, _) => 6.h.height,
                        itemBuilder: (context, i) {
                          final topic = lesson.topics[i];
                          return Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12.r,
                                  backgroundColor: const Color(
                                    0xFF059669,
                                  ).withValues(alpha: 0.1),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                                10.w.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topic.title,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (topic.description.isNotEmpty) ...[
                                        3.h.height,
                                        Text(
                                          topic.description,
                                          style: TextStyle(
                                            fontSize: 11.5.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      6.h.height,
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 2.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _difficultyColor(
                                                topic.difficulty,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              topic.difficulty,
                                              style: TextStyle(
                                                color: _difficultyColor(
                                                  topic.difficulty,
                                                ),
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          8.w.width,
                                          Text(
                                            '${topic.estimatedMinutes} mins',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _difficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}
