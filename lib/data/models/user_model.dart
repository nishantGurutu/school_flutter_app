enum UserRole { student, parent, teacher, staff, admin, masterAdmin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
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

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token, String? refreshToken}) {
    String roleStr = (json['role'] ?? 'student').toString().toUpperCase();
    UserRole roleVal = UserRole.student;
    if (roleStr == 'PARENT') roleVal = UserRole.parent;
    if (roleStr == 'TEACHER') roleVal = UserRole.teacher;
    if (roleStr == 'STAFF') roleVal = UserRole.staff;
    if (roleStr == 'ADMIN') roleVal = UserRole.admin;
    if (roleStr == 'MASTER_ADMIN' || roleStr == 'MASTERADMIN') roleVal = UserRole.masterAdmin;

    return UserModel(
      id: (json['userId'] ?? json['id'] ?? '1').toString(),
      name: json['name'] ?? 'User',
      email: json['email'] ?? '',
      role: roleVal,
      avatarUrl: json['avatarUrl'] ?? 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
      className: json['className'],
      details: json['details'] ?? (roleStr == 'MASTER_ADMIN' ? 'System Administrator' : 'School Desk User'),
      token: token ?? json['accessToken'],
      refreshToken: refreshToken ?? json['refreshToken'],
      expiresAt: json['expiresAt'] is int ? json['expiresAt'] : (json['expiresAt'] != null ? int.tryParse(json['expiresAt'].toString()) : null),
      tokenType: json['tokenType'] ?? 'Bearer',
      entityId: json['entityId'],
      phone: json['phone'],
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'name': name,
      'email': email,
      'role': role.name.toUpperCase(),
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
    };
  }

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
    }
  }
}


