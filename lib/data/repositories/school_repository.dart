import '../models/school_models.dart';
import '../models/chat_models.dart';
import '../models/home_dashboard_model.dart';
import '../models/curriculum_model.dart';
import '../models/certificate_model.dart';

abstract class SchoolRepository {
  Future<HomeDashboardResponse?> getHomeDashboard({String? admissionNo});
  Future<SubjectCurriculumModel?> getSubjectCurriculum(String subjectId);
  Future<TopicNotesResponseModel?> getChapterNotes(String chapterId);
  Future<TopicNotesResponseModel?> getTopicNotes(String topicId);
  Future<List<AttendanceRecord>> getAttendance(String userId, {String? type, String? date, String? className});
  Future<List<HolidayModel>> getHolidays();
  Future<List<AttendanceRecord>> markAttendance(AttendanceRecord record);
  Future<List<AttendanceRecord>> checkIn({required String userId, required String name, String? className, String? role});
  Future<List<AttendanceRecord>> checkOut({required String userId, required String name, String? className, String? role});
  Future<AttendanceStats> getAttendanceStats();
  Future<List<HomeworkItem>> getHomework(String userId, {String? className});
  Future<List<HomeworkItem>> submitHomework(String userId, String homeworkId);
  
  Future<List<FeeRecord>> getFees(String userId);
  Future<List<FeeRecord>> payFees(String userId, String feeId);
  
  Future<List<TimetableSlot>> getTimetable(String userId, {String? className, String? day});
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
  Future<List<DashboardGalleryAlbum>> getGalleryAlbums();
  Future<List<CertificateModel>> getCertificates({String? admissionNo});
  
  Future<List<ChatChannel>> getChatChannels(String userId);
  Future<List<ChatChannel>> sendMessage(String userId, String channelId, String text);

  // eSchool Teacher Flow (Classes, Lessons, Assignments ID-wise)
  Future<List<TeacherClassModel>> getTeacherClasses();
  Future<List<StudentInClassModel>> getClassStudents(String className, {String? section});
  Future<List<TeacherLessonModel>> getTeacherLessons({String? className, int? subjectId});
  Future<TeacherLessonModel?> createTeacherLesson({
    required String className,
    required String chapterNumber,
    required String chapterTitle,
    String? description,
    int? subjectId,
  });
  Future<TeacherTopicModel?> addLessonTopic({
    required String lessonId,
    required String title,
    String? description,
    String? difficulty,
    int? estimatedMinutes,
  });
  Future<bool> deleteLesson(String lessonId);
  Future<List<HomeworkItem>> getTeacherAssignments({String? className, String? subject});
  Future<HomeworkItem?> createTeacherAssignment({
    required String title,
    required String description,
    required String subject,
    required String className,
    String? section,
    required String dueDate,
    int points = 100,
    dynamic targetStudentId,
    String? fileAttachmentUrl,
  });
  Future<List<AssignmentSubmissionItem>> getAssignmentSubmissions(String assignmentId);
  Future<bool> reviewSubmission({
    required String assignmentId,
    required dynamic submissionId,
    required String status,
    int? points,
    String? feedback,
  });

  // eSchool Student & Parent Assignments
  Future<List<HomeworkItem>> getStudentAssignments({String? admissionNo});
  Future<bool> submitStudentAssignmentWork({
    required String assignmentId,
    String? submissionText,
    String? fileUrl,
  });
}

