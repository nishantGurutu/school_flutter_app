import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/utils/app_url.dart';
import '../models/school_models.dart';
import '../models/chat_models.dart';
import 'school_repository.dart';

class ApiSchoolRepository implements SchoolRepository {
  final NetworkApiService _apiService;

  ApiSchoolRepository({NetworkApiService? apiService})
      : _apiService = apiService ?? NetworkApiService();

  List _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      if (res['data'] is List) return res['data'];
      if (res['content'] is List) return res['content'];
      if (res['items'] is List) return res['items'];
      if (res['result'] is List) return res['result'];
    }
    return [];
  }

  @override
  Future<List<AttendanceRecord>> getAttendance(String userId, {String? type, String? date, String? className}) async {
    try {
      String url = AppUrl.attendance;
      List<String> queryParams = [];
      if (type != null) queryParams.add('type=$type');
      if (date != null) queryParams.add('date=$date');
      if (className != null) queryParams.add('className=$className');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final res = await _apiService.getApi(url);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) => AttendanceRecord.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (_) {}
    return _fallbackAttendance();
  }

  @override
  Future<List<AttendanceRecord>> markAttendance(AttendanceRecord record) async {
    try {
      final payload = record.toJson();
      await _apiService.postApi(AppUrl.markAttendance, payload);
    } catch (_) {}
    return getAttendance('');
  }

  @override
  Future<AttendanceStats> getAttendanceStats() async {
    try {
      final res = await _apiService.getApi(AppUrl.attendanceStats);
      if (res != null && res is Map) {
        return AttendanceStats.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (_) {}
    return _fallbackStats();
  }

  AttendanceStats _fallbackStats() {
    return const AttendanceStats(
      totalStudents: 450,
      presentStudents: 418,
      absentStudents: 32,
      studentPercentage: 92.8,
      totalStaff: 45,
      presentStaff: 42,
      absentStaff: 3,
      staffPercentage: 93.3,
      overallPercentage: 93.0,
      classBreakdown: [
        ClassAttendanceStat(className: 'Class 10-A', total: 40, present: 38, absent: 2, percentage: 95.0),
        ClassAttendanceStat(className: 'Class 10-B', total: 42, present: 39, absent: 3, percentage: 92.8),
        ClassAttendanceStat(className: 'Class 9-A', total: 38, present: 36, absent: 2, percentage: 94.7),
        ClassAttendanceStat(className: 'Class 9-B', total: 45, present: 41, absent: 4, percentage: 91.1),
        ClassAttendanceStat(className: 'Class 8-A', total: 35, present: 34, absent: 1, percentage: 97.1),
      ],
      date: 'Today',
    );
  }

  @override
  Future<List<HomeworkItem>> getHomework(String userId, {String? className}) async {
    try {
      final res = await _apiService.getApi(AppUrl.homework);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          return HomeworkItem(
            id: item['id'].toString(),
            subject: item['subject'] ?? 'Subject',
            title: item['title'] ?? 'Title',
            description: item['description'] ?? '',
            dueDate: DateTime.tryParse(item['dueDate'] ?? '') ?? DateTime.now().add(const Duration(days: 2)),
            status: item['status'] == 'submitted' ? HomeworkStatus.submitted : HomeworkStatus.pending,
            className: item['className'] ?? 'Class 10-A',
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackHomework();
  }

  @override
  Future<List<HomeworkItem>> submitHomework(String userId, String homeworkId) async {
    try {
      await _apiService.postApi(AppUrl.submitHomework(homeworkId), {});
    } catch (_) {}
    return getHomework(userId);
  }

  @override
  Future<List<FeeRecord>> getFees(String userId) async {
    try {
      final res = await _apiService.getApi(AppUrl.fees);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          return FeeRecord(
            id: item['id'].toString(),
            title: item['title'] ?? 'School Fee',
            amount: (item['amount'] ?? 0.0).toDouble(),
            dueDate: DateTime.tryParse(item['dueDate'] ?? '') ?? DateTime.now(),
            status: item['status'] == 'paid' ? FeeStatus.paid : FeeStatus.unpaid,
            paymentDate: item['paymentDate'] != null ? DateTime.tryParse(item['paymentDate']) : null,
            transactionId: item['transactionId'],
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackFees();
  }

  @override
  Future<List<FeeRecord>> payFees(String userId, String feeId) async {
    try {
      await _apiService.postApi(AppUrl.payFee(feeId), {});
    } catch (_) {}
    return getFees(userId);
  }

  @override
  Future<List<TimetableSlot>> getTimetable(String userId, {String? className}) async {
    try {
      final res = await _apiService.getApi(AppUrl.timetable);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          return TimetableSlot(
            id: item['id'].toString(),
            dayOfWeek: item['dayOfWeek'] ?? 'Mon',
            subject: item['subject'] ?? '',
            startTime: item['startTime'] ?? '',
            endTime: item['endTime'] ?? '',
            teacherName: item['teacherName'] ?? '',
            classroom: item['classroom'] ?? '',
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackTimetable();
  }

  @override
  Future<List<ExamItem>> getExams(String userId, {String? className}) async {
    try {
      final res = await _apiService.getApi(AppUrl.exams);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          ExamStatus status = ExamStatus.upcoming;
          if (item['status'] == 'completed') status = ExamStatus.completed;
          if (item['status'] == 'ongoing') status = ExamStatus.ongoing;
          return ExamItem(
            id: item['id'].toString(),
            subject: item['subject'] ?? '',
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            date: DateTime.tryParse(item['date'] ?? '') ?? DateTime.now(),
            startTime: item['startTime'] ?? '',
            endTime: item['endTime'] ?? '',
            room: item['room'] ?? '',
            maxMarks: (item['maxMarks'] ?? 100.0).toDouble(),
            scoredMarks: item['scoredMarks'] != null ? (item['scoredMarks']).toDouble() : null,
            status: status,
            className: item['className'] ?? 'Class 10-A',
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackExams();
  }

  @override
  Future<List<ExamItem>> createExam(ExamItem exam) async {
    try {
      await _apiService.postApi(AppUrl.createExam, {
        'subject': exam.subject,
        'title': exam.title,
        'description': exam.description,
        'date': exam.date.toIso8601String().split('T')[0],
        'startTime': exam.startTime,
        'endTime': exam.endTime,
        'room': exam.room,
        'maxMarks': exam.maxMarks,
        'className': exam.className,
      });
    } catch (_) {}
    return getExams('system');
  }

  @override
  Future<List<ExamItem>> uploadExamScore(String examId, double score) async {
    try {
      await _apiService.postApi(AppUrl.uploadExamScore(examId), {
        'scoredMarks': score,
      });
    } catch (_) {}
    return getExams('system');
  }

  @override
  Future<List<ExpenseItem>> getExpenses(String userId) async {
    try {
      final res = await _apiService.getApi(AppUrl.expenses);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          ExpenseStatus status = ExpenseStatus.pending;
          if (item['status'] == 'approved') status = ExpenseStatus.approved;
          if (item['status'] == 'rejected') status = ExpenseStatus.rejected;
          return ExpenseItem(
            id: item['id'].toString(),
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            amount: (item['amount'] ?? 0.0).toDouble(),
            category: ExpenseCategory.supplies,
            date: DateTime.tryParse(item['date'] ?? '') ?? DateTime.now(),
            status: status,
            submittedBy: item['submittedBy'] ?? 'Staff',
            approvedBy: item['approvedBy'],
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackExpenses();
  }

  @override
  Future<List<ExpenseItem>> addExpense(ExpenseItem expense) async {
    try {
      await _apiService.postApi(
        AppUrl.expenses,
        {
          'title': expense.title,
          'description': expense.description,
          'amount': expense.amount,
          'category': expense.category.name,
        },
      );
    } catch (_) {}
    return getExpenses('');
  }

  @override
  Future<List<ExpenseItem>> approveExpense(String userId, String expenseId) async {
    try {
      await _apiService.patchApi(AppUrl.approveExpense(expenseId), {});
    } catch (_) {}
    return getExpenses(userId);
  }

  @override
  Future<List<PayrollRecord>> getPayroll(String userId) async {
    try {
      final res = await _apiService.getApi(AppUrl.payroll);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          return PayrollRecord(
            id: item['id'].toString(),
            employeeName: item['employeeName'] ?? '',
            designation: item['designation'] ?? '',
            grossSalary: (item['grossSalary'] ?? 0.0).toDouble(),
            deductions: (item['deductions'] ?? 0.0).toDouble(),
            netPay: (item['netPay'] ?? 0.0).toDouble(),
            payDate: DateTime.tryParse(item['payDate'] ?? '') ?? DateTime.now(),
            month: item['month'] ?? 'June 2026',
            status: PayrollStatus.processed,
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackPayroll();
  }

  @override
  Future<List<LeaveRecord>> getLeaves(String userId) async {
    try {
      final res = await _apiService.getApi(AppUrl.leaves);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          LeaveStatus status = LeaveStatus.pending;
          if (item['status'] == 'approved') status = LeaveStatus.approved;
          if (item['status'] == 'rejected') status = LeaveStatus.rejected;
          return LeaveRecord(
            id: item['id'].toString(),
            employeeName: item['employeeName'] ?? '',
            designation: item['designation'] ?? '',
            reason: item['reason'] ?? '',
            fromDate: DateTime.tryParse(item['fromDate'] ?? '') ?? DateTime.now(),
            toDate: DateTime.tryParse(item['toDate'] ?? '') ?? DateTime.now(),
            status: status,
            appliedOn: item['appliedOn'] ?? 'Today',
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackLeaves();
  }

  @override
  Future<List<LeaveRecord>> applyLeave(LeaveRecord leave) async {
    try {
      await _apiService.postApi(
        AppUrl.leaves,
        {
          'reason': leave.reason,
          'fromDate': leave.fromDate.toString(),
          'toDate': leave.toDate.toString(),
        },
      );
    } catch (_) {}
    return getLeaves('');
  }

  @override
  Future<List<LeaveRecord>> approveLeave(String userId, String leaveId) async {
    try {
      await _apiService.patchApi(AppUrl.approveLeave(leaveId), {});
    } catch (_) {}
    return getLeaves(userId);
  }

  @override
  Future<List<LeaveRecord>> rejectLeave(String userId, String leaveId) async {
    try {
      await _apiService.patchApi(AppUrl.rejectLeave(leaveId), {});
    } catch (_) {}
    return getLeaves(userId);
  }

  @override
  Future<List<NoticeItem>> getNotices() async {
    try {
      final res = await _apiService.getApi(AppUrl.notices);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          NoticeCategory cat = NoticeCategory.regular;
          if (item['category'] == 'urgent') cat = NoticeCategory.urgent;
          if (item['category'] == 'informational') cat = NoticeCategory.informational;
          return NoticeItem(
            id: item['id'].toString(),
            title: item['title'] ?? '',
            content: item['content'] ?? '',
            date: DateTime.tryParse(item['date'] ?? '') ?? DateTime.now(),
            category: cat,
          );
        }).toList();
      }
    } catch (_) {}
    return _fallbackNotices();
  }

  @override
  Future<List<ChatChannel>> getChatChannels(String userId) async {
    return [
      ChatChannel(
        id: 'ch_1',
        name: 'Ms. Priya (Maths Teacher)',
        lastMessage: 'Rohan is performing exceptionally well in algebra classes.',
        time: '2:30 PM',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        messages: [
          Message(
            id: 'm1_1',
            senderId: 'teacher_1',
            senderName: 'Ms. Priya',
            content: 'Hello, Rohan scored 95/100 in the weekly Math quiz.',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
      )
    ];
  }

  @override
  Future<List<ChatChannel>> sendMessage(String userId, String channelId, String text) async {
    return getChatChannels(userId);
  }

  // Fallbacks
  List<AttendanceRecord> _fallbackAttendance() {
    return List.generate(20, (i) {
      return AttendanceRecord(
        date: DateTime.now().subtract(Duration(days: i)),
        status: i % 7 == 0 ? AttendanceStatus.holiday : (i == 5 ? AttendanceStatus.absent : AttendanceStatus.present),
      );
    });
  }

  List<HomeworkItem> _fallbackHomework() {
    return [
      HomeworkItem(
        id: 'hw_1',
        subject: 'Mathematics',
        title: 'Quadratic Equations',
        description: 'Complete questions 1 to 10 from exercises 4.2.',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        status: HomeworkStatus.pending,
        className: 'Class 10-A',
      ),
      HomeworkItem(
        id: 'hw_2',
        subject: 'Science',
        title: 'Solar System Project',
        description: 'Build a three-dimensional model of the solar system.',
        dueDate: DateTime.now().add(const Duration(days: 4)),
        status: HomeworkStatus.pending,
        className: 'Class 10-A',
      ),
    ];
  }

  List<FeeRecord> _fallbackFees() {
    return [
      FeeRecord(
        id: 'fee_1',
        title: 'Term 1 Tuition Fees',
        amount: 12450.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: FeeStatus.unpaid,
      ),
      FeeRecord(
        id: 'fee_2',
        title: 'Transport Fees (May)',
        amount: 3450.0,
        dueDate: DateTime.now().subtract(const Duration(days: 8)),
        status: FeeStatus.paid,
        paymentDate: DateTime.now().subtract(const Duration(days: 10)),
        transactionId: 'TXN-982348271A',
      ),
    ];
  }

  List<TimetableSlot> _fallbackTimetable() {
    return [
      TimetableSlot(id: '1', dayOfWeek: 'Mon', subject: 'Mathematics', startTime: '09:00 AM', endTime: '09:45 AM', teacherName: 'Ms. Priya', classroom: 'Room 12'),
      TimetableSlot(id: '2', dayOfWeek: 'Mon', subject: 'English', startTime: '09:45 AM', endTime: '10:30 AM', teacherName: 'Mr. Sharma', classroom: 'Room 12'),
    ];
  }

  List<ExamItem> _fallbackExams() {
    return [
      ExamItem(
        id: 'exam_1',
        subject: 'Mathematics',
        title: 'Term 1 Midterm Examination',
        description: 'Algebra & Geometry chapters.',
        date: DateTime.now().add(const Duration(days: 5)),
        startTime: '09:00 AM',
        endTime: '11:30 AM',
        room: 'Room 12',
        maxMarks: 100,
        status: ExamStatus.upcoming,
        className: 'Class 10-A',
      ),
      ExamItem(
        id: 'exam_5',
        subject: 'Mathematics',
        title: 'Weekly Math Quiz',
        description: 'Weekly math assessment.',
        date: DateTime.now().subtract(const Duration(days: 4)),
        startTime: '10:00 AM',
        endTime: '10:45 AM',
        room: 'Room 12',
        maxMarks: 25,
        scoredMarks: 24,
        status: ExamStatus.completed,
        className: 'Class 10-A',
      ),
    ];
  }

  List<ExpenseItem> _fallbackExpenses() {
    return [
      ExpenseItem(
        id: 'exp_1',
        title: 'Library Books Purchase',
        description: 'Purchase of reference books',
        amount: 5400.0,
        category: ExpenseCategory.supplies,
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: ExpenseStatus.pending,
        submittedBy: 'Ms. Priya (Maths Teacher)',
      ),
    ];
  }

  List<PayrollRecord> _fallbackPayroll() {
    return [
      PayrollRecord(
        id: 'pay_1',
        employeeName: 'Rajesh Kumar',
        designation: 'Accountant',
        grossSalary: 48500.0,
        deductions: 6200.0,
        netPay: 42300.0,
        payDate: DateTime.now(),
        month: 'June 2026',
        status: PayrollStatus.processed,
      ),
    ];
  }

  List<LeaveRecord> _fallbackLeaves() {
    return [
      LeaveRecord(
        id: 'lev_1',
        employeeName: 'Ms. Priya Sharma',
        designation: 'Maths Teacher',
        reason: 'Medical appointment',
        fromDate: DateTime.now().add(const Duration(days: 2)),
        toDate: DateTime.now().add(const Duration(days: 2)),
        status: LeaveStatus.pending,
        appliedOn: 'Yesterday',
      ),
    ];
  }

  List<NoticeItem> _fallbackNotices() {
    return [
      NoticeItem(
        id: 'not_1',
        title: 'Summer Vacation Schedule',
        content: 'The school will remain closed for summer vacation from 1st June to 14th June.',
        date: DateTime.now().subtract(const Duration(days: 1)),
        category: NoticeCategory.urgent,
      ),
    ];
  }
}
