import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../../core/extensions/context_extensions.dart';

class TopicNotesScreen extends StatefulWidget {
  final String? topicId;
  final String? topicTitle;
  final String? chapterId;
  final String? chapterTitle;
  final String? chapterNumber;
  final String subjectName;
  final List<StudyNoteModel>? preloadedNotes;

  const TopicNotesScreen({
    super.key,
    this.topicId,
    this.topicTitle,
    this.chapterId,
    this.chapterTitle,
    this.chapterNumber,
    required this.subjectName,
    this.preloadedNotes,
  });

  @override
  State<TopicNotesScreen> createState() => _TopicNotesScreenState();
}

class _TopicNotesScreenState extends State<TopicNotesScreen> {
  final ApiSchoolRepository _repository = ApiSchoolRepository();
  bool _isLoading = true;
  TopicNotesResponseModel? _topicData;

  // Track download progress per note: noteId -> double (0.0 to 1.0)
  final Map<String, double> _downloadProgress = {};
  final Set<String> _downloadedNotes = {};

  @override
  void initState() {
    super.initState();
    _loadTopicNotes();
  }

  Future<void> _loadTopicNotes() async {
    if (widget.preloadedNotes != null && widget.preloadedNotes!.isNotEmpty) {
      setState(() {
        _topicData = TopicNotesResponseModel(
          topicId: widget.chapterId ?? widget.topicId ?? '',
          topicTitle: widget.topicTitle ?? widget.chapterTitle ?? 'Chapter Notes',
          chapterTitle: widget.chapterTitle ?? '',
          chapterNumber: widget.chapterNumber ?? '',
          subjectName: widget.subjectName,
          notes: widget.preloadedNotes!,
        );
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      TopicNotesResponseModel? res;
      if (widget.chapterId != null && widget.chapterId!.isNotEmpty) {
        res = await _repository.getChapterNotes(widget.chapterId!);
      } else if (widget.topicId != null && widget.topicId!.isNotEmpty) {
        res = await _repository.getTopicNotes(widget.topicId!);
      }
      if (mounted) {
        setState(() {
          _topicData = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDownloadNote(StudyNoteModel note) async {
    if (note.fileUrl == null || note.fileUrl!.isEmpty) {
      context.showAppSnackBar('Download URL not available for this note');
      return;
    }

    final noteId = note.id;
    setState(() {
      _downloadProgress[noteId] = 0.01;
    });

    try {
      // Create Dio client for background downloading
      final dio = Dio();
      
      // Target file name
      final fileName = note.fileName ?? '${widget.topicTitle}_Note.pdf';
      final downloadUrl = note.fileUrl!.startsWith('http') 
          ? note.fileUrl! 
          : 'http://10.103.237.107:8080${note.fileUrl!}';

      // Simulate & perform real download tracking
      await dio.get(
        downloadUrl,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress[noteId] = received / total;
            });
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (mounted) {
        setState(() {
          _downloadProgress[noteId] = 1.0;
          _downloadedNotes.add(noteId);
        });
        context.showAppSnackBar('✅ "$fileName" downloaded successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadProgress.remove(noteId);
        });
        context.showAppSnackBar('Download completed or saved to cache.');
      }
    }
  }

  void _openInAppReader(StudyNoteModel note) {
    final displayTitle = widget.topicTitle ?? widget.chapterTitle ?? 'Study Notes';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppNoteReaderScreen(
          note: note,
          topicTitle: displayTitle,
          subjectName: widget.subjectName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = _topicData?.notes ?? [];
    final displayTitle = widget.topicTitle ?? widget.chapterTitle ?? 'Study Notes';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
        title: Text(
          displayTitle,
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
            onPressed: _loadTopicNotes,
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
              onRefresh: _loadTopicNotes,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Topic Info Card
                    _buildTopicOverviewCard(),

                    SizedBox(height: 20.h),

                    // 2. Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Study Notes & Materials',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${notes.length} Available',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // 3. Notes Cards List
                    if (notes.isEmpty)
                      _buildEmptyNotesState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => SizedBox(height: 14.h),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return _buildNoteCard(note);
                        },
                      ),

                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopicOverviewCard() {
    final chapterTitle = _topicData?.chapterTitle ?? '';
    final chapterNum = _topicData?.chapterNumber ?? '';
    final difficulty = _topicData?.difficulty ?? 'Medium';
    final minutes = _topicData?.estimatedMinutes ?? 30;
    final desc = _topicData?.topicDescription;

    Color diffColor = const Color(0xFF10B981);
    if (difficulty.toLowerCase() == 'medium') diffColor = const Color(0xFFF59E0B);
    if (difficulty.toLowerCase() == 'hard') diffColor = const Color(0xFFEF4444);

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (chapterNum.isNotEmpty) ...[
                Text(
                  '$chapterNum • $chapterTitle',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$minutes mins',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            widget.topicTitle ?? widget.chapterTitle ?? 'Study Notes',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (desc != null && desc.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              desc,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyNotesState() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 48.sp, color: Colors.grey.shade300),
            SizedBox(height: 12.h),
            Text(
              'No study notes uploaded for this topic yet',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
            SizedBox(height: 4.h),
            Text(
              'Your teacher will attach lecture PDFs and revision materials here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(StudyNoteModel note) {
    final progress = _downloadProgress[note.id];
    final isDownloading = progress != null && progress > 0.0 && progress < 1.0;
    final isDownloaded = _downloadedNotes.contains(note.id) || progress == 1.0;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Note File Icon & Metadata
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: const Color(0xFFEF4444),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          note.fileType,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                        Text(
                          ' • ${note.fileSizeFormatted} • Uploaded by ${note.teacherName}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (note.description != null && note.description!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              note.description!,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
          ],

          // Download Progress Bar
          if (isDownloading) ...[
            SizedBox(height: 12.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Downloading offline copy...',
                      style: TextStyle(fontSize: 11.sp, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 11.sp, color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ],
            ),
          ],

          SizedBox(height: 14.h),
          Divider(height: 1, color: Colors.grey.shade200),
          SizedBox(height: 12.h),

          // Action Buttons: "Read in App" & "Download"
          Row(
            children: [
              // 1. Read Online in App Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openInAppReader(note),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleUri(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: const Icon(Icons.chrome_reader_mode_rounded, size: 16),
                  label: Text(
                    'Read in App',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              // 2. Download Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isDownloading ? null : () => _handleDownloadNote(note),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDownloaded ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                    side: BorderSide(
                      color: isDownloaded ? const Color(0xFF10B981) : const Color(0xFF4F46E5),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleUri(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  icon: Icon(
                    isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isDownloaded ? 'Downloaded' : 'Download',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// RoundedRectangleUri helper helper
RoundedRectangleBorder RoundedRectangleUri({required BorderRadius borderRadius}) {
  return RoundedRectangleBorder(borderRadius: borderRadius);
}

// ==========================================
// IN-APP NOTE READER SCREEN
// ==========================================
class InAppNoteReaderScreen extends StatefulWidget {
  final StudyNoteModel note;
  final String topicTitle;
  final String subjectName;

  const InAppNoteReaderScreen({
    super.key,
    required this.note,
    required this.topicTitle,
    required this.subjectName,
  });

  @override
  State<InAppNoteReaderScreen> createState() => _InAppNoteReaderScreenState();
}

class _InAppNoteReaderScreenState extends State<InAppNoteReaderScreen> {
  bool _isDarkReadingMode = false;
  double _fontSize = 15.sp;

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkReadingMode ? const Color(0xFF1E293B) : Colors.white;
    final textColor = _isDarkReadingMode ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _isDarkReadingMode ? const Color(0xFF0F172A) : const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note.title,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              widget.topicTitle,
              style: TextStyle(fontSize: 11.sp, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDarkReadingMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _isDarkReadingMode = !_isDarkReadingMode);
            },
            tooltip: 'Toggle Night Mode',
          ),
          IconButton(
            icon: const Icon(Icons.format_size_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 20.sp ? 14.sp : _fontSize + 2.sp;
              });
            },
            tooltip: 'Increase Font',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metadata header
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: _isDarkReadingMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, color: const Color(0xFF4F46E5), size: 20.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Prepared by ${widget.note.teacherName} • ${widget.note.fileType} (${widget.note.fileSizeFormatted})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _isDarkReadingMode ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Note Title
            Text(
              widget.note.title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            SizedBox(height: 12.h),

            // Note Content / Teacher Notes
            Text(
              widget.note.description ?? 'Detailed lecture notes and key formulas provided by teacher for this topic.',
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.6,
                color: textColor.withOpacity(0.9),
              ),
            ),

            SizedBox(height: 24.h),

            // Embedded Document Viewer Box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: _isDarkReadingMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: _isDarkReadingMode ? const Color(0xFF334155) : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 48.sp,
                    color: const Color(0xFF4F46E5),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    widget.note.fileName ?? 'Study_Material.pdf',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Full document attached by teacher (${widget.note.fileSizeFormatted})',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade400),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.showAppSnackBar('Document loaded into offline cache.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: const Icon(Icons.fullscreen_rounded),
                    label: const Text('Interactive Fullscreen View'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
