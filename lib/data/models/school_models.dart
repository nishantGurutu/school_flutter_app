
// Attendance
enum AttendanceStatus { present, absent, holiday, late }

class AttendanceRecord {
  final String id;
  final String? userId;
  final String? admissionNo;
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
    this.admissionNo,
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
      admissionNo: json['admissionNo'],
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
      'admissionNo': admissionNo,
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
      admissionNo: admissionNo,
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

  factory AttendanceStats.empty() {
    return const AttendanceStats(
      totalStudents: 0,
      presentStudents: 0,
      absentStudents: 0,
      studentPercentage: 0.0,
      totalStaff: 0,
      presentStaff: 0,
      absentStaff: 0,
      staffPercentage: 0.0,
      overallPercentage: 0.0,
      classBreakdown: [],
      date: 'Today',
    );
  }

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    final list = json['classBreakdown'] is List ? (json['classBreakdown'] as List) : [];
    return AttendanceStats(
      totalStudents: (json['totalStudents'] ?? 0) is int ? json['totalStudents'] : int.tryParse(json['totalStudents'].toString()) ?? 0,
      presentStudents: (json['presentStudents'] ?? 0) is int ? json['presentStudents'] : int.tryParse(json['presentStudents'].toString()) ?? 0,
      absentStudents: (json['absentStudents'] ?? 0) is int ? json['absentStudents'] : int.tryParse(json['absentStudents'].toString()) ?? 0,
      studentPercentage: ((json['studentPercentage'] ?? 0.0) is num ? json['studentPercentage'] : double.tryParse(json['studentPercentage'].toString()) ?? 0.0).toDouble(),
      totalStaff: (json['totalStaff'] ?? 0) is int ? json['totalStaff'] : int.tryParse(json['totalStaff'].toString()) ?? 0,
      presentStaff: (json['presentStaff'] ?? 0) is int ? json['presentStaff'] : int.tryParse(json['presentStaff'].toString()) ?? 0,
      absentStaff: (json['absentStaff'] ?? 0) is int ? json['absentStaff'] : int.tryParse(json['absentStaff'].toString()) ?? 0,
      staffPercentage: ((json['staffPercentage'] ?? 0.0) is num ? json['staffPercentage'] : double.tryParse(json['staffPercentage'].toString()) ?? 0.0).toDouble(),
      overallPercentage: ((json['overallPercentage'] ?? 0.0) is num ? json['overallPercentage'] : double.tryParse(json['overallPercentage'].toString()) ?? 0.0).toDouble(),
      classBreakdown: list.map((item) => ClassAttendanceStat.fromJson(item)).toList(),
      date: json['date'] ?? 'Today',
    );
  }
}

// Homework & Assignments
enum HomeworkStatus { pending, submitted, overdue, accepted, rejected, graded }

class HomeworkItem {
  final String id;
  final String subject;
  final String title;
  final String description;
  final DateTime dueDate;
  final HomeworkStatus status;
  final String className;
  final String? section;
  final String? assignedDate;
  final String? assignedBy;
  final int points;
  final int maxPoints;
  final dynamic targetStudentId;
  final String? targetStudentName;
  final String? targetStudentAdmissionNo;
  final bool isPersonalized;
  final String? fileAttachmentUrl;
  final int submissionCount;
  final int evaluatedCount;
  final int totalStudents;
  final String? submissionStatus;
  final int? scoredPoints;
  final String? teacherFeedback;
  final String? submittedAt;
  final String? submissionText;
  final String? submissionFileUrl;

  const HomeworkItem({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.className,
    this.section,
    this.assignedDate,
    this.assignedBy,
    this.points = 100,
    this.maxPoints = 100,
    this.targetStudentId,
    this.targetStudentName,
    this.targetStudentAdmissionNo,
    this.isPersonalized = false,
    this.fileAttachmentUrl,
    this.submissionCount = 0,
    this.evaluatedCount = 0,
    this.totalStudents = 0,
    this.submissionStatus,
    this.scoredPoints,
    this.teacherFeedback,
    this.submittedAt,
    this.submissionText,
    this.submissionFileUrl,
  });

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    HomeworkStatus stat = HomeworkStatus.pending;
    final rawStatus = (json['status'] ?? json['submissionStatus'] ?? 'pending').toString().toLowerCase();
    if (rawStatus == 'submitted') {
      stat = HomeworkStatus.submitted;
    } else if (rawStatus == 'overdue') {
      stat = HomeworkStatus.overdue;
    } else if (rawStatus == 'accepted') {
      stat = HomeworkStatus.accepted;
    } else if (rawStatus == 'rejected') {
      stat = HomeworkStatus.rejected;
    } else if (rawStatus == 'graded') {
      stat = HomeworkStatus.graded;
    }

    final pts = (json['points'] ?? json['maxPoints'] ?? 100) is int
        ? (json['points'] ?? json['maxPoints'] ?? 100) as int
        : int.tryParse((json['points'] ?? json['maxPoints'] ?? 100).toString()) ?? 100;

    return HomeworkItem(
      id: (json['id'] ?? json['dbId'] ?? '').toString(),
      subject: json['subject'] ?? 'Subject',
      title: json['title'] ?? 'Assignment',
      description: json['description'] ?? '',
      dueDate: DateTime.tryParse(json['dueDate'] ?? json['due_date'] ?? '') ??
          DateTime.now().add(const Duration(days: 3)),
      status: stat,
      className: json['className'] ?? json['class_name'] ?? 'Class',
      section: json['section'],
      assignedDate: json['assignedDate'] ?? json['assigned_date'],
      assignedBy: json['assignedBy'] ?? json['assigned_by'],
      points: pts,
      maxPoints: pts,
      targetStudentId: json['targetStudentId'],
      targetStudentName: json['targetStudentName'],
      targetStudentAdmissionNo: json['targetStudentAdmissionNo'],
      isPersonalized: json['isPersonalized'] == true ||
          json['isTargetedToStudent'] == true ||
          json['targetStudentId'] != null,
      fileAttachmentUrl: json['fileAttachmentUrl'],
      submissionCount: (json['submissionCount'] ?? 0) is int
          ? json['submissionCount']
          : int.tryParse(json['submissionCount'].toString()) ?? 0,
      evaluatedCount: (json['evaluatedCount'] ?? 0) is int
          ? json['evaluatedCount']
          : int.tryParse(json['evaluatedCount'].toString()) ?? 0,
      totalStudents: (json['totalStudents'] ?? 0) is int
          ? json['totalStudents']
          : int.tryParse(json['totalStudents'].toString()) ?? 0,
      submissionStatus: json['submissionStatus'] ?? rawStatus,
      scoredPoints: json['scoredPoints'] != null
          ? int.tryParse(json['scoredPoints'].toString())
          : null,
      teacherFeedback: json['teacherFeedback'],
      submittedAt: json['submittedAt'],
      submissionText: json['submissionText'],
      submissionFileUrl: json['submissionFileUrl'] ?? json['fileUrl'],
    );
  }

  HomeworkItem copyWith({
    String? id,
    String? subject,
    String? title,
    String? description,
    DateTime? dueDate,
    HomeworkStatus? status,
    String? className,
    String? section,
    String? assignedDate,
    String? assignedBy,
    int? points,
    int? maxPoints,
    dynamic targetStudentId,
    String? targetStudentName,
    String? targetStudentAdmissionNo,
    bool? isPersonalized,
    String? fileAttachmentUrl,
    int? submissionCount,
    int? evaluatedCount,
    int? totalStudents,
    String? submissionStatus,
    int? scoredPoints,
    String? teacherFeedback,
    String? submittedAt,
    String? submissionText,
    String? submissionFileUrl,
  }) {
    return HomeworkItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      className: className ?? this.className,
      section: section ?? this.section,
      assignedDate: assignedDate ?? this.assignedDate,
      assignedBy: assignedBy ?? this.assignedBy,
      points: points ?? this.points,
      maxPoints: maxPoints ?? this.maxPoints,
      targetStudentId: targetStudentId ?? this.targetStudentId,
      targetStudentName: targetStudentName ?? this.targetStudentName,
      targetStudentAdmissionNo: targetStudentAdmissionNo ?? this.targetStudentAdmissionNo,
      isPersonalized: isPersonalized ?? this.isPersonalized,
      fileAttachmentUrl: fileAttachmentUrl ?? this.fileAttachmentUrl,
      submissionCount: submissionCount ?? this.submissionCount,
      evaluatedCount: evaluatedCount ?? this.evaluatedCount,
      totalStudents: totalStudents ?? this.totalStudents,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      scoredPoints: scoredPoints ?? this.scoredPoints,
      teacherFeedback: teacherFeedback ?? this.teacherFeedback,
      submittedAt: submittedAt ?? this.submittedAt,
      submissionText: submissionText ?? this.submissionText,
      submissionFileUrl: submissionFileUrl ?? this.submissionFileUrl,
    );
  }
}

class AssignmentSubmissionItem {
  final dynamic submissionId;
  final dynamic homeworkId;
  final dynamic studentId;
  final String studentName;
  final String? studentRollNo;
  final String? studentAdmissionNo;
  final String? submittedAt;
  final String? submissionText;
  final String? fileUrl;
  final String status;
  final int? points;
  final int maxPoints;
  final String? teacherFeedback;
  final String? reviewedAt;

  const AssignmentSubmissionItem({
    this.submissionId,
    this.homeworkId,
    this.studentId,
    required this.studentName,
    this.studentRollNo,
    this.studentAdmissionNo,
    this.submittedAt,
    this.submissionText,
    this.fileUrl,
    required this.status,
    this.points,
    this.maxPoints = 100,
    this.teacherFeedback,
    this.reviewedAt,
  });

  factory AssignmentSubmissionItem.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionItem(
      submissionId: json['submissionId'],
      homeworkId: json['homeworkId'],
      studentId: json['studentId'],
      studentName: json['studentName'] ?? 'Student',
      studentRollNo: json['studentRollNo']?.toString(),
      studentAdmissionNo: json['studentAdmissionNo']?.toString(),
      submittedAt: json['submittedAt']?.toString(),
      submissionText: json['submissionText']?.toString(),
      fileUrl: json['fileUrl']?.toString(),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      points: json['points'] != null ? int.tryParse(json['points'].toString()) : null,
      maxPoints: json['maxPoints'] != null ? int.tryParse(json['maxPoints'].toString()) ?? 100 : 100,
      teacherFeedback: json['teacherFeedback']?.toString(),
      reviewedAt: json['reviewedAt']?.toString(),
    );
  }
}

class TeacherClassModel {
  final String id;
  final String className;
  final String section;
  final String subject;
  final int totalStudents;
  final String room;
  final bool isClassTeacher;
  final String timing;
  final double syllabusProgress;

  const TeacherClassModel({
    required this.id,
    required this.className,
    required this.section,
    required this.subject,
    required this.totalStudents,
    required this.room,
    this.isClassTeacher = false,
    required this.timing,
    required this.syllabusProgress,
  });

  factory TeacherClassModel.fromJson(Map<String, dynamic> json) {
    return TeacherClassModel(
      id: (json['id'] ?? '').toString(),
      className: json['className'] ?? '',
      section: json['section'] ?? '',
      subject: json['subject'] ?? '',
      totalStudents: (json['totalStudents'] ?? 0) is int
          ? json['totalStudents']
          : int.tryParse(json['totalStudents'].toString()) ?? 0,
      room: json['room'] ?? '',
      isClassTeacher: json['isClassTeacher'] == true,
      timing: json['timing'] ?? '',
      syllabusProgress: (json['syllabusProgress'] ?? 0.0).toDouble(),
    );
  }
}

class StudentInClassModel {
  final dynamic id;
  final String admissionNo;
  final String? rollNo;
  final String name;
  final String className;
  final String? section;
  final String? gender;
  final String? phone;
  final String? email;
  final String? studentPhoto;

  const StudentInClassModel({
    required this.id,
    required this.admissionNo,
    this.rollNo,
    required this.name,
    required this.className,
    this.section,
    this.gender,
    this.phone,
    this.email,
    this.studentPhoto,
  });

  factory StudentInClassModel.fromJson(Map<String, dynamic> json) {
    return StudentInClassModel(
      id: json['id'],
      admissionNo: json['admissionNo'] ?? '',
      rollNo: json['rollNo']?.toString(),
      name: json['name'] ?? 'Student',
      className: json['className'] ?? '',
      section: json['section'],
      gender: json['gender'],
      phone: json['phone'],
      email: json['email'],
      studentPhoto: json['studentPhoto'],
    );
  }
}

class TeacherTopicModel {
  final dynamic id;
  final String title;
  final String description;
  final String difficulty;
  final int estimatedMinutes;
  final String status;

  const TeacherTopicModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.status,
  });

  factory TeacherTopicModel.fromJson(Map<String, dynamic> json) {
    return TeacherTopicModel(
      id: json['id'],
      title: json['title'] ?? 'Topic',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
      estimatedMinutes: (json['estimatedMinutes'] ?? 30) is int
          ? json['estimatedMinutes']
          : int.tryParse(json['estimatedMinutes'].toString()) ?? 30,
      status: json['status'] ?? 'Active',
    );
  }
}

class TeacherLessonModel {
  final dynamic id;
  final String chapterNumber;
  final String chapterTitle;
  final String title;
  final String description;
  final String className;
  final dynamic subjectId;
  final String subjectName;
  final int topicsCount;
  final List<TeacherTopicModel> topics;

  const TeacherLessonModel({
    required this.id,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.title,
    required this.description,
    required this.className,
    this.subjectId,
    required this.subjectName,
    required this.topicsCount,
    required this.topics,
  });

  factory TeacherLessonModel.fromJson(Map<String, dynamic> json) {
    List<TeacherTopicModel> parsedTopics = [];
    if (json['topics'] is List) {
      parsedTopics = (json['topics'] as List)
          .where((t) => t != null && t is Map)
          .map((t) => TeacherTopicModel.fromJson(Map<String, dynamic>.from(t)))
          .toList();
    }

    return TeacherLessonModel(
      id: json['id'],
      chapterNumber: json['chapterNumber'] ?? 'Chapter 1',
      chapterTitle: json['chapterTitle'] ?? 'Lesson',
      title: json['title'] ??
          ('${json['chapterNumber'] ?? ''}: ${json['chapterTitle'] ?? ''}'),
      description: json['description'] ?? '',
      className: json['className'] ?? '',
      subjectId: json['subjectId'],
      subjectName: json['subjectName'] ?? 'General',
      topicsCount: json['topicsCount'] ?? parsedTopics.length,
      topics: parsedTopics,
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
  final String? className;
  final String? section;
  final String? periodName;

  const TimetableSlot({
    required this.id,
    required this.dayOfWeek,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.teacherName,
    required this.classroom,
    this.className,
    this.section,
    this.periodName,
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
  final String? section;

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
    this.section,
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
      section: section,
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

// Holiday Model
class HolidayModel {
  final String id;
  final String title;
  final String date;
  final String? endDate;
  final String? category;
  final String? description;
  final String? target;

  const HolidayModel({
    required this.id,
    required this.title,
    required this.date,
    this.endDate,
    this.category,
    this.description,
    this.target,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? 'School Holiday',
      date: json['date'] ?? '',
      endDate: json['endDate'],
      category: json['category'] ?? 'School Holiday',
      description: json['description'],
      target: json['target'] ?? 'ALL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'endDate': endDate,
      'category': category,
      'description': description,
      'target': target,
    };
  }

  bool coversDate(DateTime dt) {
    try {
      final start = DateTime.parse(date);
      final check = DateTime(dt.year, dt.month, dt.day);
      final startD = DateTime(start.year, start.month, start.day);
      if (endDate != null && endDate!.isNotEmpty) {
        final end = DateTime.parse(endDate!);
        final endD = DateTime(end.year, end.month, end.day);
        return !check.isBefore(startD) && !check.isAfter(endD);
      }
      return check.isAtSameMomentAs(startD);
    } catch (_) {
      return false;
    }
  }
}
