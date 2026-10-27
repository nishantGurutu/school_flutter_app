class StudentReportModel {
  final String id,
      title,
      term,
      description,
      fileName,
      fileUrl,
      studentName,
      date;
  const StudentReportModel({
    required this.id,
    required this.title,
    required this.term,
    required this.description,
    required this.fileName,
    required this.fileUrl,
    required this.studentName,
    required this.date,
  });
  factory StudentReportModel.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key]?.toString() ?? '';
    return StudentReportModel(
      id: text('id'),
      title: text('title'),
      term: text('term'),
      description: text('description'),
      fileName: text('fileName'),
      fileUrl: text('fileUrl'),
      studentName: text('studentName'),
      date: text('createdAt').split('T').first,
    );
  }
}
