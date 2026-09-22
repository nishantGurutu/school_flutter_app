import '../models/school_models.dart';
import '../models/chat_models.dart';

abstract class SchoolRepository {
  Future<List<AttendanceRecord>> getAttendance(String userId, {String? type, String? date, String? className});
  Future<List<AttendanceRecord>> markAttendance(AttendanceRecord record);
  Future<AttendanceStats> getAttendanceStats();
  Future<List<HomeworkItem>> getHomework(String userId, {String? className});
  Future<List<HomeworkItem>> submitHomework(String userId, String homeworkId);
  
  Future<List<FeeRecord>> getFees(String userId);
  Future<List<FeeRecord>> payFees(String userId, String feeId);
  
  Future<List<TimetableSlot>> getTimetable(String userId, {String? className});
  Future<List<ExamItem>> getExams(String userId, {String? className});
  Future<List<ExamItem>> createExam(ExamItem exam);
  Future<List<ExamItem>> uploadExamScore(String examId, double score);
  Future<List<ExpenseItem>> getExpenses(String userId);
  Future<List<ExpenseItem>> addExpense(ExpenseItem expense);
  Future<List<ExpenseItem>> approveExpense(String userId, String expenseId);
  Future<List<PayrollRecord>> getPayroll(String userId);
  Future<List<LeaveRecord>> getLeaves(String userId);
  Future<List<LeaveRecord>> applyLeave(LeaveRecord leave);
  Future<List<LeaveRecord>> approveLeave(String userId, String leaveId);
  Future<List<LeaveRecord>> rejectLeave(String userId, String leaveId);
  Future<List<NoticeItem>> getNotices();
  
  Future<List<ChatChannel>> getChatChannels(String userId);
  Future<List<ChatChannel>> sendMessage(String userId, String channelId, String text);
}
