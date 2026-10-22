class CertificateModel {
  final dynamic id;
  final String name;
  final String? admissionNo;
  final String? rollNo;
  final String? className;
  final String certificateName;
  final String? bgImage;
  final String? avatar;
  final String date;
  final String footerLeft;
  final String footerRight;

  CertificateModel({
    required this.id,
    required this.name,
    this.admissionNo,
    this.rollNo,
    this.className,
    required this.certificateName,
    this.bgImage,
    this.avatar,
    required this.date,
    this.footerLeft = 'Principal Signature',
    this.footerRight = 'Class Teacher Signature',
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    return CertificateModel(
      id: json['id'],
      name: (json['name'] ?? '').toString(),
      admissionNo: json['admissionNo']?.toString(),
      rollNo: json['rollNo']?.toString(),
      className: json['className']?.toString(),
      certificateName: (json['certificateName'] ?? json['title'] ?? 'Certificate of Recognition').toString(),
      bgImage: json['bgImage']?.toString(),
      avatar: json['avatar']?.toString(),
      date: (json['date'] ?? json['issueDate'] ?? json['createdAt'] ?? '').toString(),
      footerLeft: (json['footerLeft'] ?? 'Principal Signature').toString(),
      footerRight: (json['footerRight'] ?? 'Class Teacher Signature').toString(),
    );
  }
}
