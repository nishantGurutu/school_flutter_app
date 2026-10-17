enum UserRole { student, parent, teacher, staff, admin, masterAdmin, driver }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? userType;
  final String avatarUrl;
  final String? className; // e.g., "Class 10-A"
  final String details; // e.g. "Roll No: 24" or "Parent of Rohan" or "Mathematics Teacher"
  final String? token;
  final String? refreshToken;
  final int? expiresAt;
  final String? tokenType;
  final dynamic entityId;
  final String? phone;
  final String? department;
  final String? admissionNo;
  final String? rollNo;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.userType,
    required this.avatarUrl,
    this.className,
    required this.details,
    this.token,
    this.refreshToken,
    this.expiresAt,
    this.tokenType,
    this.entityId,
    this.phone,
    this.department,
    this.admissionNo,
    this.rollNo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token, String? refreshToken}) {
    final rawUserType = json['userType']?.toString();
    final rawRole = json['role']?.toString();
    String roleStr = (rawUserType ?? rawRole ?? 'student').toString().toUpperCase();
    final dept = json['department']?.toString().toUpperCase() ?? '';
    final details = json['details']?.toString().toUpperCase() ?? '';
    final desig = (json['designation'] ?? json['className'])?.toString().toUpperCase() ?? '';

    UserRole roleVal = UserRole.student;
    if (roleStr == 'PARENT') roleVal = UserRole.parent;
    if (roleStr == 'TEACHER') roleVal = UserRole.teacher;
    if (roleStr == 'STAFF' || roleStr == 'PRINCIPAL') roleVal = UserRole.staff;
    if (roleStr == 'ADMIN') roleVal = UserRole.admin;
    if (roleStr == 'MASTER_ADMIN' || roleStr == 'MASTERADMIN') roleVal = UserRole.masterAdmin;
    if (roleStr == 'DRIVER' || dept == 'DRIVER' || dept == 'TRANSPORT' || desig.contains('DRIVER') || details.contains('DRIVER')) {
      roleVal = UserRole.driver;
    }

    // className is only for students (and teachers assigned to a class), never for drivers, staff, or admin
    String? resolvedClassName = json['className']?.toString();
    if (roleVal != UserRole.student && roleVal != UserRole.teacher) {
      resolvedClassName = null;
    } else if (resolvedClassName != null && 
        (resolvedClassName.toLowerCase().contains('driver') || 
         resolvedClassName.toLowerCase().contains('faculty') || 
         resolvedClassName.toLowerCase().contains('staff'))) {
      resolvedClassName = null;
    }

    return UserModel(
      id: (json['userId'] ?? json['id'] ?? '1').toString(),
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      role: roleVal,
      userType: roleVal == UserRole.driver ? 'DRIVER' : (rawUserType ?? rawRole ?? roleVal.name.toUpperCase()),
      avatarUrl: json['avatarUrl'] ?? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      className: resolvedClassName,
      details: json['details'] ?? (roleVal == UserRole.driver ? 'Bus Driver • Transport' : (roleStr == 'MASTER_ADMIN' ? 'System Administrator' : 'School Desk User')),
      token: token ?? json['accessToken'],
      refreshToken: refreshToken ?? json['refreshToken'],
      expiresAt: json['expiresAt'] is int ? json['expiresAt'] : (json['expiresAt'] != null ? int.tryParse(json['expiresAt'].toString()) : null),
      tokenType: json['tokenType'] ?? 'Bearer',
      entityId: json['entityId'],
      phone: json['phone'],
      department: json['department'],
      admissionNo: json['admissionNo'] ?? json['admission_no'],
      rollNo: json['rollNo'] ?? json['roll_no'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'name': name,
      'email': email,
      'role': role.name.toUpperCase(),
      'userType': userType ?? role.name.toUpperCase(),
      'avatarUrl': avatarUrl,
      'className': className,
      'details': details,
      'accessToken': token,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
      'tokenType': tokenType,
      'entityId': entityId,
      'phone': phone,
      'department': department,
      'admissionNo': admissionNo,
      'rollNo': rollNo,
    };
  }

  bool get isTeacher =>
      role == UserRole.teacher || (userType?.toUpperCase() == 'TEACHER');

  String get roleDisplayName {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.staff:
        return 'Staff';
      case UserRole.admin:
        return 'Admin';
      case UserRole.masterAdmin:
        return 'Master Admin';
      case UserRole.driver:
        return 'Driver';
    }
  }
}


