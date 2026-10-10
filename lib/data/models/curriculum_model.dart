class SubjectCurriculumModel {
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int totalChapters;
  final int totalTopics;
  final int totalNotes;
  final List<CurriculumChapterModel> chapters;

  SubjectCurriculumModel({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    this.totalChapters = 0,
    this.totalTopics = 0,
    this.totalNotes = 0,
    this.chapters = const [],
  });

  factory SubjectCurriculumModel.fromJson(Map<String, dynamic> json) {
    return SubjectCurriculumModel(
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? 'Subject',
      subjectCode: json['subjectCode']?.toString() ?? '',
      totalChapters: json['totalChapters'] is int ? json['totalChapters'] : int.tryParse(json['totalChapters']?.toString() ?? '0') ?? 0,
      totalTopics: json['totalTopics'] is int ? json['totalTopics'] : int.tryParse(json['totalTopics']?.toString() ?? '0') ?? 0,
      totalNotes: json['totalNotes'] is int ? json['totalNotes'] : int.tryParse(json['totalNotes']?.toString() ?? '0') ?? 0,
      chapters: (json['chapters'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map((e) => CurriculumChapterModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CurriculumChapterModel {
  final String chapterId;
  final String chapterNumber;
  final String chapterTitle;
  final String? className;
  final String? description;
  final int notesCount;
  final bool hasNotes;
  final List<StudyNoteModel> notes;
  final List<CurriculumTopicModel> topics;

  CurriculumChapterModel({
    required this.chapterId,
    required this.chapterNumber,
    required this.chapterTitle,
    this.className,
    this.description,
    this.notesCount = 0,
    this.hasNotes = false,
    this.notes = const [],
    this.topics = const [],
  });

  factory CurriculumChapterModel.fromJson(Map<String, dynamic> json) {
    final n = json['notesCount'] is int
        ? json['notesCount']
        : int.tryParse(json['notesCount']?.toString() ?? '0') ?? 0;
    final notesList = (json['notes'] as List? ?? [])
        .where((e) => e != null && e is Map)
        .map((e) => StudyNoteModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return CurriculumChapterModel(
      chapterId: json['chapterId']?.toString() ?? '',
      chapterNumber: json['chapterNumber']?.toString() ?? 'Chapter 1',
      chapterTitle: json['chapterTitle']?.toString() ?? 'Chapter',
      className: json['className']?.toString(),
      description: json['description']?.toString(),
      notesCount: notesList.isNotEmpty ? notesList.length : n,
      hasNotes: json['hasNotes'] == true || notesList.isNotEmpty || n > 0,
      notes: notesList,
      topics: (json['topics'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map((e) => CurriculumTopicModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CurriculumTopicModel {
  final String topicId;
  final String title;
  final String? description;
  final String difficulty; // Easy, Medium, Hard
  final int estimatedMinutes;
  final int notesCount;
  final bool hasNotes;

  CurriculumTopicModel({
    required this.topicId,
    required this.title,
    this.description,
    this.difficulty = 'Medium',
    this.estimatedMinutes = 30,
    this.notesCount = 0,
    this.hasNotes = false,
  });

  factory CurriculumTopicModel.fromJson(Map<String, dynamic> json) {
    final n = json['notesCount'] is int ? json['notesCount'] : int.tryParse(json['notesCount']?.toString() ?? '0') ?? 0;
    return CurriculumTopicModel(
      topicId: json['topicId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Topic',
      description: json['description']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'Medium',
      estimatedMinutes: json['estimatedMinutes'] is int ? json['estimatedMinutes'] : int.tryParse(json['estimatedMinutes']?.toString() ?? '30') ?? 30,
      notesCount: n,
      hasNotes: json['hasNotes'] == true || n > 0,
    );
  }
}

class TopicNotesResponseModel {
  final String topicId;
  final String topicTitle;
  final String? topicDescription;
  final String difficulty;
  final int estimatedMinutes;
  final String chapterTitle;
  final String chapterNumber;
  final String subjectName;
  final List<StudyNoteModel> notes;

  TopicNotesResponseModel({
    required this.topicId,
    required this.topicTitle,
    this.topicDescription,
    this.difficulty = 'Medium',
    this.estimatedMinutes = 30,
    this.chapterTitle = '',
    this.chapterNumber = '',
    this.subjectName = '',
    this.notes = const [],
  });

  factory TopicNotesResponseModel.fromJson(Map<String, dynamic> json) {
    return TopicNotesResponseModel(
      topicId: json['topicId']?.toString() ?? '',
      topicTitle: json['topicTitle']?.toString() ?? 'Topic Notes',
      topicDescription: json['topicDescription']?.toString(),
      difficulty: json['difficulty']?.toString() ?? 'Medium',
      estimatedMinutes: json['estimatedMinutes'] is int ? json['estimatedMinutes'] : 30,
      chapterTitle: json['chapterTitle']?.toString() ?? '',
      chapterNumber: json['chapterNumber']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      notes: (json['notes'] as List? ?? [])
          .where((e) => e != null && e is Map)
          .map((e) => StudyNoteModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class StudyNoteModel {
  final String id;
  final String title;
  final String? description;
  final String? contentHtml;
  final String? fileName;
  final String? fileUrl;
  final String fileType; // PDF, DOC, IMAGE
  final String fileSizeFormatted;
  final bool isDownloadable;
  final bool isPreviewable;
  final String teacherName;
  final String uploadedDate;

  StudyNoteModel({
    required this.id,
    required this.title,
    this.description,
    this.contentHtml,
    this.fileName,
    this.fileUrl,
    this.fileType = 'PDF',
    this.fileSizeFormatted = '1.0 MB',
    this.isDownloadable = true,
    this.isPreviewable = true,
    this.teacherName = 'Teacher',
    this.uploadedDate = 'Recent',
  });

  factory StudyNoteModel.fromJson(Map<String, dynamic> json) {
    return StudyNoteModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Study Note',
      description: json['description']?.toString(),
      contentHtml: json['contentHtml']?.toString(),
      fileName: json['fileName']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      fileType: json['fileType']?.toString() ?? 'PDF',
      fileSizeFormatted: json['fileSizeFormatted']?.toString() ?? '1.0 MB',
      isDownloadable: json['isDownloadable'] != false,
      isPreviewable: json['isPreviewable'] != false,
      teacherName: json['teacherName']?.toString() ?? 'Teacher',
      uploadedDate: json['uploadedDate']?.toString() ?? 'Recent',
    );
  }
}
