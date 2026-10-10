import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import 'topic_notes_screen.dart';

class SubjectCurriculumScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String? subjectCode;
  final String? colorHex;
  final String? secondaryColorHex;

  const SubjectCurriculumScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.subjectCode,
    this.colorHex,
    this.secondaryColorHex,
  });

  @override
  State<SubjectCurriculumScreen> createState() => _SubjectCurriculumScreenState();
}

class _SubjectCurriculumScreenState extends State<SubjectCurriculumScreen> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  bool _isLoading = true;
  SubjectCurriculumModel? _curriculum;
  String _searchQuery = '';
  final Set<String> _expandedChapterIds = {};

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repository.getSubjectCurriculum(widget.subjectId);
      if (mounted) {
        setState(() {
          _curriculum = res;
          _isLoading = false;
          // Auto-expand all chapters
          if (res != null) {
            for (final ch in res.chapters) {
              _expandedChapterIds.add(ch.chapterId);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _resolvePrimaryColor() {
    if (widget.colorHex != null && widget.colorHex!.startsWith('#')) {
      try {
        final hex = widget.colorHex!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return const Color(0xFF4F46E5); // Indigo default
  }

  Color _resolveSecondaryColor() {
    if (widget.secondaryColorHex != null && widget.secondaryColorHex!.startsWith('#')) {
      try {
        final hex = widget.secondaryColorHex!.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    return const Color(0xFF7C3AED); // Purple default
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _resolvePrimaryColor();
    final secondaryColor = _resolveSecondaryColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.subjectName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadCurriculum,
            tooltip: 'Refresh syllabus',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCurriculum,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Hero Subject Banner
                  SliverToBoxAdapter(
                    child: _buildHeroBanner(primaryColor, secondaryColor),
                  ),

                  // 2. Search & Stats Filter
                  SliverToBoxAdapter(
                    child: _buildSearchAndStats(),
                  ),

                  // 3. Chapters & Topics List
                  _buildChaptersList(primaryColor),

                  SliverToBoxAdapter(
                    child: SizedBox(height: 40.h),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBanner(Color primaryColor, Color secondaryColor) {
    final totalChapters = _curriculum?.totalChapters ?? _curriculum?.chapters.length ?? 0;
    final totalTopics = _curriculum?.totalTopics ?? 0;
    final totalNotes = _curriculum?.totalNotes ?? 0;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  widget.subjectCode ?? 'COURSE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4.w),
                    Text(
                      'Teacher Verified',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            widget.subjectName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Complete Syllabus, Topics & Teacher Study Materials',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildStatChip(Icons.layers_rounded, '$totalChapters Chapters'),
              SizedBox(width: 8.w),
              _buildStatChip(Icons.menu_book_rounded, '$totalTopics Topics'),
              SizedBox(width: 8.w),
              _buildStatChip(Icons.picture_as_pdf_rounded, '$totalNotes Notes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14.sp),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndStats() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search chapters or topics...',
          hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20.sp),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildChaptersList(Color primaryColor) {
    final rawChapters = _curriculum?.chapters ?? [];
    final filteredChapters = rawChapters.where((ch) {
      if (_searchQuery.isEmpty) return true;
      final matchChapter = ch.chapterTitle.toLowerCase().contains(_searchQuery) ||
          ch.chapterNumber.toLowerCase().contains(_searchQuery);
      final matchTopics = ch.topics.any((t) => t.title.toLowerCase().contains(_searchQuery));
      return matchChapter || matchTopics;
    }).toList();

    if (filteredChapters.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.menu_book_outlined, size: 48.sp, color: Colors.grey.shade300),
                SizedBox(height: 12.h),
                Text(
                  _searchQuery.isEmpty ? 'No topics uploaded yet for this subject' : 'No matching topics found',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your teacher will add chapters & notes soon.',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final chapter = filteredChapters[index];
            final isExpanded = _expandedChapterIds.contains(chapter.chapterId);
            final topics = chapter.topics.where((t) {
              if (_searchQuery.isEmpty) return true;
              return t.title.toLowerCase().contains(_searchQuery);
            }).toList();

            return Container(
              margin: EdgeInsets.only(bottom: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chapter Header
                  InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedChapterIds.remove(chapter.chapterId);
                        } else {
                          _expandedChapterIds.add(chapter.chapterId);
                        }
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              chapter.chapterNumber,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chapter.chapterTitle,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                if (chapter.description != null && chapter.description!.isNotEmpty)
                                  Text(
                                    chapter.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (chapter.notesCount > 0)
                            Container(
                              margin: EdgeInsets.only(right: 6.w),
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.description_rounded, size: 11.sp, color: primaryColor),
                                  SizedBox(width: 3.w),
                                  Text(
                                    '${chapter.notesCount} ${chapter.notesCount == 1 ? "Note" : "Notes"}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (topics.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '${topics.length} ${topics.length == 1 ? "topic" : "topics"}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          SizedBox(width: 4.w),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content inside Chapter: Direct Chapter Notes + Topics
                  if (isExpanded) ...[
                    Divider(height: 1, color: Colors.grey.shade100),

                    // Direct Chapter Notes Opener ("notes chapter ki hogi")
                    InkWell(
                      borderRadius: BorderRadius.circular(14.r),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopicNotesScreen(
                              chapterId: chapter.chapterId,
                              chapterTitle: chapter.chapterTitle,
                              chapterNumber: chapter.chapterNumber,
                              subjectName: widget.subjectName,
                              preloadedNotes: chapter.notes.isNotEmpty ? chapter.notes : null,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                        margin: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor.withOpacity(0.08), primaryColor.withOpacity(0.03)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 18.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${chapter.chapterNumber} Study Notes & PDFs',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    chapter.notesCount > 0
                                        ? '${chapter.notesCount} ${chapter.notesCount == 1 ? "note" : "notes"} attached • Tap to read or download'
                                        : 'View notes attached to this chapter',
                                    style: TextStyle(fontSize: 11.sp, color: primaryColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: primaryColor),
                          ],
                        ),
                      ),
                    ),

                    if (topics.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                        child: Row(
                          children: [
                            Text(
                              'Topics in this chapter',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        itemCount: topics.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, tIndex) {
                          final topic = topics[tIndex];
                          return _buildTopicTile(topic, tIndex + 1);
                        },
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
          childCount: filteredChapters.length,
        ),
      ),
    );
  }

  Widget _buildTopicTile(CurriculumTopicModel topic, int index) {
    Color difficultyColor = const Color(0xFF10B981);
    if (topic.difficulty.toLowerCase() == 'medium') {
      difficultyColor = const Color(0xFFF59E0B);
    } else if (topic.difficulty.toLowerCase() == 'hard') {
      difficultyColor = const Color(0xFFEF4444);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicNotesScreen(
              topicId: topic.topicId,
              topicTitle: topic.title,
              subjectName: widget.subjectName,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: TextStyle(
                  color: const Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          topic.difficulty,
                          style: TextStyle(
                            color: difficultyColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${topic.estimatedMinutes} mins',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (topic.notesCount > 0) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: const Color(0xFFEC4899), size: 10.sp),
                              SizedBox(width: 3.w),
                              Text(
                                '${topic.notesCount} ${topic.notesCount == 1 ? "Note" : "Notes"}',
                                style: TextStyle(
                                  color: const Color(0xFFEC4899),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
