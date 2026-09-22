import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_desk_app/data/models/school_models.dart';
import '../../core/di/locator.dart';
import '../../data/repositories/school_repository.dart';
import '../../data/models/chat_models.dart';
import 'school_event.dart';
import 'school_state.dart';

class SchoolBloc extends Bloc<SchoolEvent, SchoolState> {
  final SchoolRepository _schoolRepository = getIt<SchoolRepository>();

  SchoolBloc() : super(const SchoolState()) {
    on<LoadSchoolData>(_onLoadSchoolData);
    on<MarkAttendanceRequested>(_onMarkAttendanceRequested);
    on<FetchAttendanceStatsRequested>(_onFetchAttendanceStatsRequested);
    on<SubmitHomeworkRequested>(_onSubmitHomeworkRequested);
    on<PayFeeRequested>(_onPayFeeRequested);
    on<SendMessageRequested>(_onSendMessageRequested);
    on<ReceiveMockReply>(_onReceiveMockReply);
    on<AddExpenseRequested>(_onAddExpenseRequested);
    on<ApproveExpenseRequested>(_onApproveExpenseRequested);
    on<ApplyLeaveRequested>(_onApplyLeaveRequested);
    on<ApproveLeaveRequested>(_onApproveLeaveRequested);
    on<RejectLeaveRequested>(_onRejectLeaveRequested);
    on<CreateExamRequested>(_onCreateExamRequested);
    on<UploadExamScoreRequested>(_onUploadExamScoreRequested);
  }

  Future<void> _onLoadSchoolData(
    LoadSchoolData event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final results = await Future.wait([
        _schoolRepository.getAttendance(event.userId),
        _schoolRepository.getHomework(event.userId),
        _schoolRepository.getFees(event.userId),
        _schoolRepository.getTimetable(event.userId),
        _schoolRepository.getExams(event.userId),
        _schoolRepository.getExpenses(event.userId),
        _schoolRepository.getNotices(),
        _schoolRepository.getChatChannels(event.userId),
        _schoolRepository.getPayroll(event.userId),
        _schoolRepository.getLeaves(event.userId),
        _schoolRepository.getAttendanceStats(),
      ]);

      emit(
        state.copyWith(
          isLoading: false,
          attendance: results[0] as List<AttendanceRecord>,
          homework: results[1] as List<HomeworkItem>,
          fees: results[2] as List<FeeRecord>,
          timetable: results[3] as List<TimetableSlot>,
          exams: results[4] as List<ExamItem>,
          expenses: results[5] as List<ExpenseItem>,
          notices: results[6] as List<NoticeItem>,
          chatChannels: results[7] as List<ChatChannel>,
          payroll: results[8] as List<PayrollRecord>,
          leaves: results[9] as List<LeaveRecord>,
          attendanceStats: results[10] as AttendanceStats,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load school workspace: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSubmitHomeworkRequested(
    SubmitHomeworkRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));

    try {
      final updatedHomework = await _schoolRepository.submitHomework(
        event.userId,
        event.homeworkId,
      );
      emit(
        state.copyWith(
          isActionInProgress: false,
          homework: updatedHomework,
          actionSuccessMessage: 'Homework submitted successfully!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: 'Failed to submit homework.',
        ),
      );
    }
  }

  Future<void> _onPayFeeRequested(
    PayFeeRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));

    try {
      final updatedFees = await _schoolRepository.payFees(
        event.userId,
        event.feeId,
      );
      emit(
        state.copyWith(
          isActionInProgress: false,
          fees: updatedFees,
          actionSuccessMessage:
              'Fee payment of ₹12,450 completed successfully!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: 'Payment processing failed.',
        ),
      );
    }
  }

  Future<void> _onAddExpenseRequested(
    AddExpenseRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));
    try {
      final expense = ExpenseItem(
        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
        title: event.title,
        description: event.description,
        amount: event.amount,
        category: event.category,
        date: DateTime.now(),
        status: ExpenseStatus.pending,
        submittedBy: event.submittedBy,
      );
      final updatedExpenses = await _schoolRepository.addExpense(expense);
      emit(
        state.copyWith(
          isActionInProgress: false,
          expenses: updatedExpenses,
          actionSuccessMessage: 'Expense added successfully!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: 'Failed to add expense.',
        ),
      );
    }
  }

  Future<void> _onApproveExpenseRequested(
    ApproveExpenseRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));
    try {
      final updatedExpenses = await _schoolRepository.approveExpense(
        event.userId,
        event.expenseId,
      );
      emit(
        state.copyWith(
          isActionInProgress: false,
          expenses: updatedExpenses,
          actionSuccessMessage: 'Expense approved successfully!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: 'Failed to approve expense.',
        ),
      );
    }
  }

  Future<void> _onApplyLeaveRequested(
    ApplyLeaveRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));
    try {
      final leave = LeaveRecord(
        id: 'lev_${DateTime.now().millisecondsSinceEpoch}',
        employeeName: event.employeeName,
        designation: event.designation,
        reason: event.reason,
        fromDate: event.fromDate,
        toDate: event.toDate,
        status: LeaveStatus.pending,
        appliedOn: _formatDate(DateTime.now()),
      );
      final updated = await _schoolRepository.applyLeave(leave);
      emit(state.copyWith(isActionInProgress: false, leaves: updated, actionSuccessMessage: 'Leave applied!'));
    } catch (e) {
      emit(state.copyWith(isActionInProgress: false, errorMessage: 'Failed to apply leave.'));
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _onApproveLeaveRequested(
    ApproveLeaveRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));
    try {
      final updated = await _schoolRepository.approveLeave(event.userId, event.leaveId);
      emit(state.copyWith(isActionInProgress: false, leaves: updated, actionSuccessMessage: 'Leave approved!'));
    } catch (e) {
      emit(state.copyWith(isActionInProgress: false, errorMessage: 'Failed to approve leave.'));
    }
  }

  Future<void> _onRejectLeaveRequested(
    RejectLeaveRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));
    try {
      final updated = await _schoolRepository.rejectLeave(event.userId, event.leaveId);
      emit(state.copyWith(isActionInProgress: false, leaves: updated, actionSuccessMessage: 'Leave rejected.'));
    } catch (e) {
      emit(state.copyWith(isActionInProgress: false, errorMessage: 'Failed to reject leave.'));
    }
  }

  Future<void> _onSendMessageRequested(
    SendMessageRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final updatedChannels = await _schoolRepository.sendMessage(
        event.userId,
        event.channelId,
        event.text,
      );
      emit(state.copyWith(chatChannels: updatedChannels));

      // Trigger automatic reply after a short delay for interactive wow factor
      final String replyText = _getMockReplyText(event.channelId, event.text);

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!isClosed) {
          add(
            ReceiveMockReply(channelId: event.channelId, replyText: replyText),
          );
        }
      });
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to send message.'));
    }
  }

  void _onReceiveMockReply(ReceiveMockReply event, Emitter<SchoolState> emit) {
    final channelIndex = state.chatChannels.indexWhere(
      (ch) => ch.id == event.channelId,
    );
    if (channelIndex != -1) {
      final channel = state.chatChannels[channelIndex];
      final messages = List<Message>.from(channel.messages);

      messages.add(
        Message(
          id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'contact',
          senderName: channel.name.split(' ').first,
          content: event.replyText,
          timestamp: DateTime.now(),
        ),
      );

      final updatedChannels = List<ChatChannel>.from(state.chatChannels);
      updatedChannels[channelIndex] = channel.copyWith(
        messages: messages,
        lastMessage: event.replyText,
        time: 'Just now',
      );

      emit(state.copyWith(chatChannels: updatedChannels));
    }
  }

  String _getMockReplyText(String channelId, String userMessage) {
    final lower = userMessage.toLowerCase();

    if (channelId == 'ch_1') {
      // Ms. Priya (Maths Teacher)
      if (lower.contains('homework') || lower.contains('submit')) {
        return 'Thank you for updating me. I will review Rohan\'s algebra exercises today.';
      } else if (lower.contains('marks') || lower.contains('score')) {
        return 'Yes, Rohan scored very well. Keep up the encouragement at home!';
      }
      return 'Hello Anita! Thanks for your message. I will check this and get back to you soon.';
    } else if (channelId == 'ch_2') {
      // Rajesh Sharma (Driver)
      if (lower.contains('where') ||
          lower.contains('bus') ||
          lower.contains('reach')) {
        return 'We have crossed the main crossroads. We should reach Rohan\'s stop in 5 minutes.';
      }
      return 'Okay, noted. Thank you.';
    } else {
      // Transport Manager / Others
      return 'Thank you for contacting school transport desk. We have received your query and will update you.';
    }
  }

  Future<void> _onMarkAttendanceRequested(
    MarkAttendanceRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));
    try {
      final updatedAttendance = await _schoolRepository.markAttendance(event.record);
      final updatedStats = await _schoolRepository.getAttendanceStats();
      emit(
        state.copyWith(
          isActionInProgress: false,
          attendance: updatedAttendance,
          attendanceStats: updatedStats,
          actionSuccessMessage: 'Attendance marked successfully as ${event.record.status.name.toUpperCase()}!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: 'Failed to mark attendance: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onFetchAttendanceStatsRequested(
    FetchAttendanceStatsRequested event,
    Emitter<SchoolState> emit,
  ) async {
    try {
      final stats = await _schoolRepository.getAttendanceStats();
      emit(state.copyWith(attendanceStats: stats));
    } catch (_) {}
  }

  Future<void> _onCreateExamRequested(
    CreateExamRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));
    try {
      final updatedExams = await _schoolRepository.createExam(event.exam);
      emit(
        state.copyWith(
          isActionInProgress: false,
          exams: updatedExams,
          actionSuccessMessage: 'Exam "${event.exam.title}" scheduled successfully!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: 'Failed to create exam.',
        ),
      );
    }
  }

  Future<void> _onUploadExamScoreRequested(
    UploadExamScoreRequested event,
    Emitter<SchoolState> emit,
  ) async {
    emit(state.copyWith(isActionInProgress: true, actionSuccessMessage: null));
    try {
      final updatedExams = await _schoolRepository.uploadExamScore(
        event.examId,
        event.score,
      );
      emit(
        state.copyWith(
          isActionInProgress: false,
          exams: updatedExams,
          actionSuccessMessage: 'Exam score uploaded successfully!',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isActionInProgress: false,
          errorMessage: 'Failed to upload exam score.',
        ),
      );
    }
  }
}
