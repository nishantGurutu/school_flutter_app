
// Attendance
enum AttendanceStatus { present, absent, holiday, late }

class AttendanceRecord {
  final String id;
  final String? userId;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;
  final String? name;
  final String? rollNo;
  final String? className;
  final String? department;
  final String? designation;
  final String? attendanceType;
  final String? checkInTime;
  final String? checkOutTime;

  const AttendanceRecord({
    this.id = '',
    this.userId,
    required this.date,
    required this.status,
    this.notes,
    this.name,
    this.rollNo,
    this.className,
    this.department,
    this.designation,
    this.attendanceType,
    this.checkInTime,
    this.checkOutTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    AttendanceStatus stat = AttendanceStatus.present;
    final statusStr = (json['status'] ?? 'present').toString().toLowerCase();
    if (statusStr == 'absent') stat = AttendanceStatus.absent;
    if (statusStr == 'holiday') stat = AttendanceStatus.holiday;
    if (statusStr == 'late') stat = AttendanceStatus.late;

    return AttendanceRecord(
      id: (json['id'] ?? '').toString(),
      userId: json['userId'] ?? json['user_id'],
      date: DateTime.tryParse(json['date'] ?? json['attendanceDate'] ?? '') ?? DateTime.now(),
      status: stat,
      notes: json['notes'] ?? json['note'],
      name: json['name'],
      rollNo: json['rollNo'],
      className: json['className'],
      department: json['department'],
      designation: json['designation'],
      attendanceType: json['attendanceType'],
      checkInTime: json['checkInTime'] ?? json['check_in_time'],
      checkOutTime: json['checkOutTime'] ?? json['check_out_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'status': status.name,
      'notes': notes,
      'name': name,
      'rollNo': rollNo,
      'className': className,
      'department': department,
      'designation': designation,
      'attendanceType': attendanceType,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
    };
  }

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    DateTime? date,
    AttendanceStatus? status,
    String? notes,
    String? name,
    String? rollNo,
    String? className,
    String? department,
    String? designation,
    String? attendanceType,
    String? checkInTime,
    String? checkOutTime,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      name: name ?? this.name,
      rollNo: rollNo ?? this.rollNo,
      className: className ?? this.className,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      attendanceType: attendanceType ?? this.attendanceType,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }
}

class ClassAttendanceStat {
  final String className;
  final int total;
  final int present;
  final int absent;
  final double percentage;

  const ClassAttendanceStat({
    required this.className,
    required this.total,
    required this.present,
    required this.absent,
    required this.percentage,
  });

  factory ClassAttendanceStat.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceStat(
      className: json['className'] ?? 'Class',
      total: (json['total'] ?? 0) is int ? json['total'] : int.tryParse(json['total'].toString()) ?? 0,
      present: (json['present'] ?? 0) is int ? json['present'] : int.tryParse(json['present'].toString()) ?? 0,
      absent: (json['absent'] ?? 0) is int ? json['absent'] : int.tryParse(json['absent'].toString()) ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
}

class AttendanceStats {
  final int totalStudents;
  final int presentStudents;
  final int absentStudents;
  final double studentPercentage;
  final int totalStaff;
  final int presentStaff;
  final int absentStaff;
  final double staffPercentage;
  final double overallPercentage;
  final List<ClassAttendanceStat> classBreakdown;
  final String date;

  const AttendanceStats({
    required this.totalStudents,
    required this.presentStudents,
    required this.absentStudents,
    required this.studentPercentage,
    required this.totalStaff,
    required this.presentStaff,
    required this.absentStaff,
    required this.staffPercentage,
    required this.overallPercentage,
    required this.classBreakdown,
    required this.date,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    final list = json['classBreakdown'] is List ? (json['classBreakdown'] as List) : [];
    return AttendanceStats(
      totalStudents: (json['totalStudents'] ?? 450) is int ? json['totalStudents'] : int.tryParse(json['totalStudents'].toString()) ?? 450,
      presentStudents: (json['presentStudents'] ?? 418) is int ? json['presentStudents'] : int.tryParse(json['presentStudents'].toString()) ?? 418,
      absentStudents: (json['absentStudents'] ?? 32) is int ? json['absentStudents'] : int.tryParse(json['absentStudents'].toString()) ?? 32,
      studentPercentage: (json['studentPercentage'] ?? 92.8).toDouble(),
      totalStaff: (json['totalStaff'] ?? 45) is int ? json['totalStaff'] : int.tryParse(json['totalStaff'].toString()) ?? 45,
      presentStaff: (json['presentStaff'] ?? 42) is int ? json['presentStaff'] : int.tryParse(json['presentStaff'].toString()) ?? 42,
      absentStaff: (json['absentStaff'] ?? 3) is int ? json['absentStaff'] : int.tryParse(json['absentStaff'].toString()) ?? 3,
      staffPercentage: (json['staffPercentage'] ?? 93.3).toDouble(),
      overallPercentage: (json['overallPercentage'] ?? 93.0).toDouble(),
      classBreakdown: list.map((item) => ClassAttendanceStat.fromJson(item)).toList(),
      date: json['date'] ?? '',
    );
  }
}

// Homework
enum HomeworkStatus { pending, submitted }

class HomeworkItem {
  final String id;
  final String subject;
  final String title;
  final String description;
  final DateTime dueDate;
  final HomeworkStatus status;
  final String className;

  const HomeworkItem({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.className,
  });

  HomeworkItem copyWith({
    String? id,
    String? subject,
    String? title,
    String? description,
    DateTime? dueDate,
    HomeworkStatus? status,
    String? className,
  }) {
    return HomeworkItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      className: className ?? this.className,
    );
  }
}
 
enum FeeStatus { unpaid, paid }

class FeeRecord {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final FeeStatus status;
  final DateTime? paymentDate;
  final String? transactionId;

  const FeeRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paymentDate,
    this.transactionId,
  });

  FeeRecord copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    FeeStatus? status,
    DateTime? paymentDate,
    String? transactionId,
  }) {
    return FeeRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

// Timetable
class TimetableSlot {
  final String id;
  final String dayOfWeek; 
  final String subject;
  final String startTime;
  final String endTime;
  final String teacherName;
  final String classroom;

  const TimetableSlot({
    required this.id,
    required this.dayOfWeek,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.teacherName,
    required this.classroom,
  });
}

// Exam
enum ExamStatus { upcoming, ongoing, completed }

class ExamItem {
  final String id;
  final String subject;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String room;
  final double maxMarks;
  final double? scoredMarks;
  final ExamStatus status;
  final String className;

  const ExamItem({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.maxMarks,
    this.scoredMarks,
    required this.status,
    required this.className,
  });

  ExamItem copyWith({
    String? id,
    String? subject,
    String? title,
    String? description,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? room,
    double? maxMarks,
    double? scoredMarks,
    ExamStatus? status,
    String? className,
  }) {
    return ExamItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      maxMarks: maxMarks ?? this.maxMarks,
      scoredMarks: scoredMarks ?? this.scoredMarks,
      status: status ?? this.status,
      className: className ?? this.className,
    );
  }

  double get percentage {
    if (scoredMarks == null || maxMarks <= 0) return 0.0;
    return double.parse(((scoredMarks! / maxMarks) * 100).toStringAsFixed(1));
  }

  String get gradeLabel {
    final p = percentage;
    if (p >= 90) return 'A+';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B';
    if (p >= 60) return 'C';
    if (p >= 50) return 'D';
    return 'F';
  }

  bool get isPassed => percentage >= 40;
}

// Expense
enum ExpenseStatus { pending, approved, rejected }
enum ExpenseCategory { maintenance, supplies, transport, utilities, other }

class ExpenseItem {
  final String id;
  final String title;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final ExpenseStatus status;
  final String submittedBy;
  final String? approvedBy;

  const ExpenseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.status,
    required this.submittedBy,
    this.approvedBy,
  });

  ExpenseItem copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    ExpenseStatus? status,
    String? submittedBy,
    String? approvedBy,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      approvedBy: approvedBy ?? this.approvedBy,
    );
  }
}

// Leave
enum LeaveStatus { pending, approved, rejected }

class LeaveRecord {
  final String id;
  final String employeeName;
  final String designation;
  final String reason;
  final DateTime fromDate;
  final DateTime toDate;
  final LeaveStatus status;
  final String appliedOn;

  const LeaveRecord({
    required this.id,
    required this.employeeName,
    required this.designation,
    required this.reason,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.appliedOn,
  });

  LeaveRecord copyWith({
    String? id,
    String? employeeName,
    String? designation,
    String? reason,
    DateTime? fromDate,
    DateTime? toDate,
    LeaveStatus? status,
    String? appliedOn,
  }) {
    return LeaveRecord(
      id: id ?? this.id,
      employeeName: employeeName ?? this.employeeName,
      designation: designation ?? this.designation,
      reason: reason ?? this.reason,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      appliedOn: appliedOn ?? this.appliedOn,
    );
  }
}

// Payroll
enum PayrollStatus { processed, pending, cancelled }

class PayrollRecord {
  final String id;
  final String employeeName;
  final String designation;
  final double grossSalary;
  final double deductions;
  final double netPay;
  final DateTime payDate;
  final String month;
  final PayrollStatus status;

  const PayrollRecord({
    required this.id,
    required this.employeeName,
    required this.designation,
    required this.grossSalary,
    required this.deductions,
    required this.netPay,
    required this.payDate,
    required this.month,
    required this.status,
  });
}

// Notice
enum NoticeCategory { urgent, regular, informational }

class NoticeItem {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final NoticeCategory category;

  const NoticeItem({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.category,
  });
}
