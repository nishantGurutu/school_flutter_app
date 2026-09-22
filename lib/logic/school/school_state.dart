import '../../data/models/school_models.dart';
import '../../data/models/chat_models.dart';

class SchoolState {
  final bool isLoading;
  final List<AttendanceRecord> attendance;
  final List<HomeworkItem> homework;
  final List<FeeRecord> fees;
  final List<TimetableSlot> timetable;
  final List<ExamItem> exams;
  final List<ExpenseItem> expenses;
  final List<NoticeItem> notices;
  final List<PayrollRecord> payroll;
  final List<LeaveRecord> leaves;
  final List<ChatChannel> chatChannels;
  final AttendanceStats? attendanceStats;
  final String? errorMessage;
  final bool isActionInProgress;
  final String? actionSuccessMessage;

  const SchoolState({
    this.isLoading = false,
    this.attendance = const [],
    this.homework = const [],
    this.fees = const [],
    this.timetable = const [],
    this.exams = const [],
    this.expenses = const [],
    this.notices = const [],
    this.payroll = const [],
    this.leaves = const [],
    this.chatChannels = const [],
    this.attendanceStats,
    this.errorMessage,
    this.isActionInProgress = false,
    this.actionSuccessMessage,
  });

  SchoolState copyWith({
    bool? isLoading,
    List<AttendanceRecord>? attendance,
    List<HomeworkItem>? homework,
    List<FeeRecord>? fees,
    List<TimetableSlot>? timetable,
    List<ExamItem>? exams,
    List<ExpenseItem>? expenses,
    List<NoticeItem>? notices,
    List<PayrollRecord>? payroll,
    List<LeaveRecord>? leaves,
    List<ChatChannel>? chatChannels,
    AttendanceStats? attendanceStats,
    String? errorMessage,
    bool? isActionInProgress,
    String? actionSuccessMessage,
  }) {
    return SchoolState(
      isLoading: isLoading ?? this.isLoading,
      attendance: attendance ?? this.attendance,
      homework: homework ?? this.homework,
      fees: fees ?? this.fees,
      timetable: timetable ?? this.timetable,
      exams: exams ?? this.exams,
      expenses: expenses ?? this.expenses,
      notices: notices ?? this.notices,
      payroll: payroll ?? this.payroll,
      leaves: leaves ?? this.leaves,
      chatChannels: chatChannels ?? this.chatChannels,
      attendanceStats: attendanceStats ?? this.attendanceStats,
      errorMessage: errorMessage ?? this.errorMessage,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      actionSuccessMessage: actionSuccessMessage ?? this.actionSuccessMessage,
    );
  }

  // Get total unpaid fees amount
  double get totalUnpaidFees {
    return fees
        .where((f) => f.status == FeeStatus.unpaid)
        .fold(0.0, (sum, f) => sum + f.amount);
  }

  // Get attendance rates
  double get attendancePercentage {
    final activeRecords = attendance.where((r) => r.status != AttendanceStatus.holiday).toList();
    if (activeRecords.isEmpty) return 100.0;
    final presentCount = activeRecords.where((r) => r.status == AttendanceStatus.present).length;
    return (presentCount / activeRecords.length) * 100.0;
  }
}
