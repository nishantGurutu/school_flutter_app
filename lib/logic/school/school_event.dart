import 'package:school_desk_app/data/models/school_models.dart';

abstract class SchoolEvent {
  const SchoolEvent();
}

class LoadSchoolData extends SchoolEvent {
  final String userId;
  const LoadSchoolData(this.userId);
}

class SubmitHomeworkRequested extends SchoolEvent {
  final String userId;
  final String homeworkId;
  const SubmitHomeworkRequested({required this.userId, required this.homeworkId});
}

class PayFeeRequested extends SchoolEvent {
  final String userId;
  final String feeId;
  const PayFeeRequested({required this.userId, required this.feeId});
}

class SendMessageRequested extends SchoolEvent {
  final String userId;
  final String channelId;
  final String text;
  const SendMessageRequested({required this.userId, required this.channelId, required this.text});
}

class AddExpenseRequested extends SchoolEvent {
  final String title;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final String submittedBy;
  const AddExpenseRequested({
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.submittedBy,
  });
}

class ApproveExpenseRequested extends SchoolEvent {
  final String userId;
  final String expenseId;
  const ApproveExpenseRequested({required this.userId, required this.expenseId});
}

class ApplyLeaveRequested extends SchoolEvent {
  final String employeeName;
  final String designation;
  final String reason;
  final DateTime fromDate;
  final DateTime toDate;
  const ApplyLeaveRequested({
    required this.employeeName,
    required this.designation,
    required this.reason,
    required this.fromDate,
    required this.toDate,
  });
}

class ApproveLeaveRequested extends SchoolEvent {
  final String userId;
  final String leaveId;
  const ApproveLeaveRequested({required this.userId, required this.leaveId});
}

class RejectLeaveRequested extends SchoolEvent {
  final String userId;
  final String leaveId;
  const RejectLeaveRequested({required this.userId, required this.leaveId});
}

class ReceiveMockReply extends SchoolEvent {
  final String channelId;
  final String replyText;
  const ReceiveMockReply({required this.channelId, required this.replyText});
}

class MarkAttendanceRequested extends SchoolEvent {
  final AttendanceRecord record;
  const MarkAttendanceRequested(this.record);
}

class FetchAttendanceStatsRequested extends SchoolEvent {
  const FetchAttendanceStatsRequested();
}

class CreateExamRequested extends SchoolEvent {
  final ExamItem exam;
  const CreateExamRequested(this.exam);
}

class UploadExamScoreRequested extends SchoolEvent {
  final String examId;
  final double score;
  const UploadExamScoreRequested({required this.examId, required this.score});
}

