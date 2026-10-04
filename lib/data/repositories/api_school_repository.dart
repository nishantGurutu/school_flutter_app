import 'package:flutter/foundation.dart';
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
    if (res == null) return [];
    if (res is List) return res;
    if (res is Map) {
      if (res['data'] is List) return res['data'];
      if (res['content'] is List) return res['content'];
      if (res['items'] is List) return res['items'];
      if (res['result'] is List) return res['result'];
      if (res['holidays'] is List) return res['holidays'];
      if (res['records'] is List) return res['records'];
    }
    return [];
  }

  List<AttendanceRecord>? _cachedAttendance;
  List<HolidayModel>? _cachedHolidays;

  @override
  Future<List<HolidayModel>> getHolidays() async {
    try {
      final res = await _apiService.getApi(AppUrl.holidays);
      if (res == null) {
        _cachedHolidays = [];
        return [];
      }
      final rawList = _extractList(res);
      _cachedHolidays = rawList
          .where((item) => item != null && item is Map)
          .map((item) => HolidayModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return _cachedHolidays!;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching holidays from API: $e');
      }
      return _cachedHolidays ?? [];
    }
  }

  @override
  Future<List<AttendanceRecord>> getAttendance(String userId, {String? type, String? date, String? className}) async {
    List<AttendanceRecord> records = [];
    try {
      String url = AppUrl.attendance;
      List<String> queryParams = [];
      if (type != null && type.trim().isNotEmpty) queryParams.add('type=${Uri.encodeComponent(type.trim())}');
      if (date != null && date.trim().isNotEmpty) queryParams.add('date=${Uri.encodeComponent(date.trim())}');
      if (className != null && className.trim().isNotEmpty) queryParams.add('className=${Uri.encodeComponent(className.trim())}');
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final res = await _apiService.getApi(url);
      if (res != null) {
        final rawList = _extractList(res);
        if (rawList.isNotEmpty) {
          records = rawList
              .where((item) => item != null && item is Map)
              .map((item) => AttendanceRecord.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching attendance from API: $e');
      }
    }

    // Merge in holidays so holiday dates reflect status: AttendanceStatus.holiday
    try {
      final holidays = await getHolidays();
      if (holidays.isEmpty) {
        _cachedAttendance = records;
        return records;
      }

      final List<AttendanceRecord> merged = [];
      final Set<String> processedKeys = {};

      for (final r in records) {
        final key = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
        processedKeys.add(key);

        HolidayModel? matchingHoliday;
        for (final h in holidays) {
          if (h.coversDate(r.date)) {
            matchingHoliday = h;
            break;
          }
        }

        if (matchingHoliday != null) {
          merged.add(r.copyWith(
            status: AttendanceStatus.holiday,
            notes: matchingHoliday.title,
          ));
        } else {
          merged.add(r);
        }
      }

      // Add holiday dates that weren't already recorded
      for (final h in holidays) {
        try {
          final start = DateTime.parse(h.date);
          final end = (h.endDate != null && h.endDate!.isNotEmpty) ? DateTime.parse(h.endDate!) : start;
          DateTime cur = start;
          while (!cur.isAfter(end)) {
            final key = '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
            if (!processedKeys.contains(key)) {
              processedKeys.add(key);
              merged.add(AttendanceRecord(
                id: 'hol_${h.id}_$key',
                date: cur,
                status: AttendanceStatus.holiday,
                notes: h.title,
              ));
            }
            cur = cur.add(const Duration(days: 1));
          }
        } catch (_) {}
      }

      _cachedAttendance = merged;
      return merged;
    } catch (_) {
      _cachedAttendance = records;
      return records;
    }
  }

  @override
  Future<List<AttendanceRecord>> markAttendance(AttendanceRecord record) async {
    try {
      final payload = record.toJson();
      await _apiService.postApi(AppUrl.markAttendance, payload);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking attendance: $e');
      }
    }
    return getAttendance(record.userId ?? '');
  }

  @override
  Future<List<AttendanceRecord>> checkIn({required String userId, required String name, String? className, String? role}) async {
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    try {
      await _apiService.postApi(AppUrl.checkIn, {
        'userId': userId,
        'name': name,
        'className': className,
        'role': role,
        'checkInTime': timeStr,
        'timestamp': now.toIso8601String(),
        'status': 'present',
        'attendanceType': role ?? 'student',
      });
    } catch (e) {
      try {
        await _apiService.postApi(AppUrl.markAttendance, {
          'userId': userId,
          'name': name,
          'className': className,
          'role': role,
          'checkInTime': timeStr,
          'status': 'present',
          'attendanceType': role ?? 'student',
        });
      } catch (_) {
        rethrow;
      }
    }

    final currentList = await getAttendance(userId);
    final today = DateTime.now();
    final index = currentList.indexWhere((r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day);

    if (index != -1) {
      currentList[index] = currentList[index].copyWith(
        status: AttendanceStatus.present,
        checkInTime: timeStr,
        name: name,
        className: className,
        userId: userId,
      );
    } else {
      currentList.insert(0, AttendanceRecord(
        id: 'att_${now.millisecondsSinceEpoch}',
        userId: userId,
        date: today,
        status: AttendanceStatus.present,
        name: name,
        className: className,
        attendanceType: role,
        checkInTime: timeStr,
        notes: 'Checked in via App Banner',
      ));
    }
    _cachedAttendance = List.from(currentList);
    return List<AttendanceRecord>.from(_cachedAttendance!);
  }

  @override
  Future<List<AttendanceRecord>> checkOut({required String userId, required String name, String? className, String? role}) async {
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    try {
      await _apiService.postApi(AppUrl.checkOut, {
        'userId': userId,
        'name': name,
        'className': className,
        'role': role,
        'checkOutTime': timeStr,
        'timestamp': now.toIso8601String(),
        'status': 'present',
        'attendanceType': role ?? 'student',
      });
    } catch (e) {
      try {
        await _apiService.postApi(AppUrl.markAttendance, {
          'userId': userId,
          'name': name,
          'className': className,
          'role': role,
          'checkOutTime': timeStr,
          'status': 'present',
          'attendanceType': role ?? 'student',
        });
      } catch (_) {
        rethrow;
      }
    }

    final currentList = await getAttendance(userId);
    final today = DateTime.now();
    final index = currentList.indexWhere((r) => r.date.year == today.year && r.date.month == today.month && r.date.day == today.day);

    if (index != -1) {
      currentList[index] = currentList[index].copyWith(
        checkOutTime: timeStr,
      );
    } else {
      currentList.insert(0, AttendanceRecord(
        id: 'att_${now.millisecondsSinceEpoch}',
        userId: userId,
        date: today,
        status: AttendanceStatus.present,
        name: name,
        className: className,
        attendanceType: role,
        checkInTime: timeStr,
        checkOutTime: timeStr,
        notes: 'Checked out via App Banner',
      ));
    }
    _cachedAttendance = List.from(currentList);
    return List<AttendanceRecord>.from(_cachedAttendance!);
  }

  @override
  Future<AttendanceStats> getAttendanceStats() async {
    try {
      final res = await _apiService.getApi(AppUrl.attendanceStats);
      if (res != null && res is Map) {
        return AttendanceStats.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching attendance stats from API: $e');
      }
    }
    return AttendanceStats.empty();
  }

  @override
  Future<List<HomeworkItem>> getHomework(String userId, {String? className}) async {
    try {
      String url = AppUrl.homework;
      if (className != null && className.trim().isNotEmpty) {
        url += '?className=${Uri.encodeComponent(className.trim())}';
      }
      final res = await _apiService.getApi(url);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          return HomeworkItem(
            id: (item['id'] ?? item['dbId'] ?? '').toString(),
            subject: item['subject'] ?? 'Subject',
            title: item['title'] ?? 'Title',
            description: item['description'] ?? '',
            dueDate: DateTime.tryParse(item['dueDate'] ?? item['due_date'] ?? '') ?? DateTime.now(),
            status: item['status'] == 'submitted' ? HomeworkStatus.submitted : HomeworkStatus.pending,
            className: item['className'] ?? item['class_name'] ?? (className ?? ''),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching homework from API: $e');
      }
      return [];
    }
  }

  @override
  Future<List<HomeworkItem>> submitHomework(String userId, String homeworkId) async {
    try {
      await _apiService.postApi(AppUrl.submitHomework(homeworkId), {});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting homework: $e');
      }
    }
    return getHomework(userId);
  }

  @override
  Future<List<FeeRecord>> getFees(String userId) async {
    try {
      String url = AppUrl.fees;
      if (userId.trim().isNotEmpty) {
        url += '?userId=${Uri.encodeComponent(userId.trim())}';
      }
      final res = await _apiService.getApi(url);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          return FeeRecord(
            id: (item['id'] ?? item['dbId'] ?? '').toString(),
            title: item['title'] ?? 'School Fee',
            amount: (item['amount'] ?? 0.0).toDouble(),
            dueDate: DateTime.tryParse(item['dueDate'] ?? item['due_date'] ?? '') ?? DateTime.now(),
            status: (item['status'] ?? '').toString().toLowerCase() == 'paid' ? FeeStatus.paid : FeeStatus.unpaid,
            paymentDate: item['paymentDate'] != null ? DateTime.tryParse(item['paymentDate'].toString()) : null,
            transactionId: item['transactionId']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching fees from API: $e');
      }
      return [];
    }
  }

  @override
  Future<List<FeeRecord>> payFees(String userId, String feeId) async {
    try {
      await _apiService.postApi(AppUrl.payFee(feeId), {});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error paying fee: $e');
      }
    }
    return getFees(userId);
  }

  @override
  Future<List<TimetableSlot>> getTimetable(String userId, {String? className, String? day}) async {
    try {
      String url = AppUrl.timetable;
      final queryParams = <String, String>{};
      if (className != null && className.trim().isNotEmpty) {
        queryParams['className'] = className.trim();
      }
      if (day != null && day.trim().isNotEmpty) {
        queryParams['day'] = day.trim();
      }
      if (queryParams.isNotEmpty) {
        final qs = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$qs';
      }
      final res = await _apiService.getApi(url);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          return TimetableSlot(
            id: (item['id'] ?? item['dbId'] ?? '').toString(),
            dayOfWeek: item['dayOfWeek'] ?? (day ?? 'Mon'),
            subject: item['subject'] ?? '',
            startTime: item['startTime'] ?? '',
            endTime: item['endTime'] ?? '',
            teacherName: item['teacherName'] ?? '',
            classroom: item['classroom'] ?? '',
            className: item['className']?.toString(),
            section: item['section']?.toString(),
            periodName: item['periodName']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching timetable from API: $e');
      }
      return [];
    }
  }

  @override
  Future<List<ExamItem>> getExams(String userId, {String? className}) async {
    try {
      String url = AppUrl.exams;
      if (className != null && className.trim().isNotEmpty) {
        url += '?className=${Uri.encodeComponent(className.trim())}';
      }
      final res = await _apiService.getApi(url);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          ExamStatus status = ExamStatus.upcoming;
          final statStr = (item['status'] ?? '').toString().toLowerCase();
          if (statStr == 'completed') status = ExamStatus.completed;
          if (statStr == 'ongoing') status = ExamStatus.ongoing;
          return ExamItem(
            id: (item['id'] ?? item['dbId'] ?? '').toString(),
            subject: item['subject'] ?? '',
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            date: DateTime.tryParse(item['date'] ?? item['examDate'] ?? '') ?? DateTime.now(),
            startTime: item['startTime'] ?? item['start_time'] ?? '',
            endTime: item['endTime'] ?? item['end_time'] ?? '',
            room: item['room'] ?? item['roomNo'] ?? '',
            maxMarks: (item['maxMarks'] ?? item['max_marks'] ?? 100.0).toDouble(),
            scoredMarks: item['scoredMarks'] != null
                ? (item['scoredMarks']).toDouble()
                : (item['scored_marks'] != null ? (item['scored_marks']).toDouble() : null),
            status: status,
            className: item['className'] ?? item['class_name'] ?? (className ?? ''),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching exams from API: $e');
      }
      return [];
    }
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating exam: $e');
      }
    }
    return getExams('system', className: exam.className);
  }

  @override
  Future<List<ExamItem>> uploadExamScore(String examId, double score) async {
    try {
      await _apiService.postApi(AppUrl.uploadExamScore(examId), {
        'scoredMarks': score,
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading exam score: $e');
      }
    }
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
          final statStr = (item['status'] ?? '').toString().toLowerCase();
          if (statStr == 'approved') status = ExpenseStatus.approved;
          if (statStr == 'rejected') status = ExpenseStatus.rejected;

          ExpenseCategory category = ExpenseCategory.supplies;
          final catStr = (item['category'] ?? '').toString().toLowerCase();
          if (catStr.contains('maintenance')) {
            category = ExpenseCategory.maintenance;
          } else if (catStr.contains('transport')) {
            category = ExpenseCategory.transport;
          } else if (catStr.contains('util')) {
            category = ExpenseCategory.utilities;
          } else if (catStr.contains('suppl')) {
            category = ExpenseCategory.supplies;
          } else {
            category = ExpenseCategory.other;
          }

          return ExpenseItem(
            id: (item['id'] ?? item['dbId'] ?? '').toString(),
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            amount: (item['amount'] ?? 0.0).toDouble(),
            category: category,
            date: DateTime.tryParse(item['date'] ?? item['createdAt'] ?? '') ?? DateTime.now(),
            status: status,
            submittedBy: item['submittedBy'] ?? 'Staff',
            approvedBy: item['approvedBy']?.toString(),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching expenses from API: $e');
      }
      return [];
    }
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding expense: $e');
      }
    }
    return getExpenses('');
  }

  @override
  Future<List<ExpenseItem>> approveExpense(String userId, String expenseId) async {
    try {
      await _apiService.patchApi(AppUrl.approveExpense(expenseId), {});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error approving expense: $e');
      }
    }
    return getExpenses(userId);
  }

  @override
  Future<List<PayrollRecord>> getPayroll(String userId) async {
    try {
      String url = AppUrl.payroll;
      if (userId.trim().isNotEmpty) {
        url += '?userId=${Uri.encodeComponent(userId.trim())}';
      }
      final res = await _apiService.getApi(url);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          PayrollStatus status = PayrollStatus.processed;
          final statStr = (item['status'] ?? '').toString().toLowerCase();
          if (statStr == 'pending') status = PayrollStatus.pending;
          if (statStr == 'cancelled') status = PayrollStatus.cancelled;

          return PayrollRecord(
            id: (item['id'] ?? item['dbId'] ?? '').toString(),
            employeeName: item['employeeName'] ?? '',
            designation: item['designation'] ?? '',
            grossSalary: (item['grossSalary'] ?? 0.0).toDouble(),
            deductions: (item['deductions'] ?? 0.0).toDouble(),
            netPay: (item['netPay'] ?? 0.0).toDouble(),
            payDate: DateTime.tryParse(item['payDate'] ?? '') ?? DateTime.now(),
            month: item['month'] ?? '',
            status: status,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching payroll from API: $e');
      }
      return [];
    }
  }

  @override
  Future<List<LeaveRecord>> getLeaves(String userId) async {
    try {
      String url = AppUrl.leaves;
      if (userId.trim().isNotEmpty) {
        url += '?userId=${Uri.encodeComponent(userId.trim())}';
      }
      final res = await _apiService.getApi(url);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          LeaveStatus status = LeaveStatus.pending;
          final statStr = (item['status'] ?? '').toString().toLowerCase();
          if (statStr == 'approved') status = LeaveStatus.approved;
          if (statStr == 'rejected') status = LeaveStatus.rejected;
          return LeaveRecord(
            id: (item['id'] ?? item['dbId'] ?? '').toString(),
            employeeName: item['employeeName'] ?? '',
            designation: item['designation'] ?? '',
            reason: item['reason'] ?? '',
            fromDate: DateTime.tryParse(item['fromDate'] ?? '') ?? DateTime.now(),
            toDate: DateTime.tryParse(item['toDate'] ?? '') ?? DateTime.now(),
            status: status,
            appliedOn: item['appliedOn'] ?? '',
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching leaves from API: $e');
      }
      return [];
    }
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
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error applying leave: $e');
      }
    }
    return getLeaves('');
  }

  @override
  Future<List<LeaveRecord>> approveLeave(String userId, String leaveId) async {
    try {
      await _apiService.patchApi(AppUrl.approveLeave(leaveId), {});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error approving leave: $e');
      }
    }
    return getLeaves(userId);
  }

  @override
  Future<List<LeaveRecord>> rejectLeave(String userId, String leaveId) async {
    try {
      await _apiService.patchApi(AppUrl.rejectLeave(leaveId), {});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rejecting leave: $e');
      }
    }
    return getLeaves(userId);
  }

  @override
  Future<List<NoticeItem>> getNotices() async {
    try {
      final res = await _apiService.getApi(AppUrl.notices);
      final rawList = _extractList(res);
      if (rawList.isNotEmpty) {
        return rawList.map((item) {
          final catStr = (item['category'] ?? '').toString().toLowerCase();
          NoticeCategory cat = NoticeCategory.regular;
          if (catStr.contains('urgent')) {
            cat = NoticeCategory.urgent;
          } else if (catStr.contains('info') || catStr.contains('academic')) {
            cat = NoticeCategory.informational;
          } else {
            cat = NoticeCategory.regular;
          }

          DateTime noticeDate = DateTime.now();
          if (item['date'] != null && item['date'].toString().trim().isNotEmpty) {
            noticeDate = DateTime.tryParse(item['date'].toString()) ?? noticeDate;
          } else if (item['createdAt'] != null && item['createdAt'].toString().trim().isNotEmpty) {
            noticeDate = DateTime.tryParse(item['createdAt'].toString()) ?? noticeDate;
          }

          return NoticeItem(
            id: (item['id'] ?? item['dbId'] ?? '').toString(),
            title: (item['title'] ?? '').toString(),
            content: (item['content'] ?? item['title'] ?? '').toString(),
            date: noticeDate,
            category: cat,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching notices from API: $e');
      }
      return [];
    }
  }

  @override
  Future<List<ChatChannel>> getChatChannels(String userId) async {
    return [];
  }

  @override
  Future<List<ChatChannel>> sendMessage(String userId, String channelId, String text) async {
    return [];
  }
}
