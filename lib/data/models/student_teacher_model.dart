class StudentTeacherModel {
  final String id, name, subject, email, phone, designation;
  const StudentTeacherModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.email,
    required this.phone,
    required this.designation,
  });
  factory StudentTeacherModel.fromJson(Map<String, dynamic> json) {
    String text(String key) => json[key]?.toString().trim() ?? '';
    return StudentTeacherModel(
      id: text('id'),
      name: text('name'),
      subject: text('subject'),
      email: text('email'),
      phone: text('phone'),
      designation: text('designation'),
    );
  }
}
