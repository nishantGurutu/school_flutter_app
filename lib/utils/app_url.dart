import '../services/runtime_environment.dart';

class AppUrl {
  static String get baseUrl => RuntimeEnvironment.baseUrl;

  // Auth Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get logout => '$baseUrl/auth/logout';

  // Mobile App Dynamic Endpoints
  static String get profileMe => '$baseUrl/mobile/profile/me';
  static String get attendance => '$baseUrl/mobile/attendance';
  static String get holidays => '$baseUrl/mobile/holidays';
  static String get markAttendance => '$baseUrl/mobile/attendance/mark';
  static String get checkIn => '$baseUrl/mobile/attendance/check-in';
  static String get checkOut => '$baseUrl/mobile/attendance/check-out';
  static String get attendanceStats => '$baseUrl/mobile/attendance/stats';
  static String get homework => '$baseUrl/mobile/homework';
  static String submitHomework(String id) =>
      '$baseUrl/mobile/homework/submit/$id';
  static String get fees => '$baseUrl/mobile/fees';
  static String payFee(String id) => '$baseUrl/mobile/fees/pay/$id';
  static String get timetable => '$baseUrl/mobile/timetable';
  static String get exams => '$baseUrl/mobile/exams';
  static String get createExam => '$baseUrl/mobile/exams';
  static String uploadExamScore(String id) => '$baseUrl/mobile/exams/$id/score';
  static String get expenses => '$baseUrl/mobile/expenses';
  static String approveExpense(String id) =>
      '$baseUrl/mobile/expenses/$id/approve';
  static String get payroll => '$baseUrl/mobile/payroll';
  static String get leaves => '$baseUrl/mobile/leaves';
  static String approveLeave(String id) => '$baseUrl/mobile/leaves/$id/approve';
  static String rejectLeave(String id) => '$baseUrl/mobile/leaves/$id/reject';
  static String get notices => '$baseUrl/mobile/notices';
  static String get homeDashboard => '$baseUrl/mobile/dashboard/home';
  static String homeDashboardWithStudent(String admissionNo) =>
      '$baseUrl/mobile/dashboard/home?admissionNo=${Uri.encodeComponent(admissionNo)}';

  // School Photo Gallery Endpoints (Dynamic from Admin Dashboard)
  static String get gallery => '$baseUrl/gallery';
  static String get activeGallery => '$baseUrl/gallery/active';

  // Certificates Endpoints (Dynamic from Admin Dashboard & Backend PDF Generator)
  static String get certificates => '$baseUrl/certificates';
  static String certificatePdf(dynamic id) => '$baseUrl/certificates/$id/pdf';
  static String certificateDownload(dynamic id) =>
      '$baseUrl/certificates/$id/download';

  // Curriculum & Study Notes
  static String subjectCurriculum(String subjectId) =>
      '$baseUrl/mobile/subjects/$subjectId/curriculum';
  static String chapterNotes(String chapterId) =>
      '$baseUrl/mobile/chapters/$chapterId/notes';
  static String topicNotes(String topicId) =>
      '$baseUrl/mobile/topics/$topicId/notes';

  // eSchool Teacher Flow (Classes, Lessons, Assignments ID-wise)
  static String get teacherClasses => '$baseUrl/mobile/teacher/classes';
  static String classStudents(String className, {String? section}) {
    String url =
        '$baseUrl/mobile/classes/${Uri.encodeComponent(className)}/students';
    if (section != null && section.isNotEmpty) {
      url += '?section=${Uri.encodeComponent(section)}';
    }
    return url;
  }

  static String teacherLessons({String? className, int? subjectId}) {
    List<String> q = [];
    if (className != null && className.isNotEmpty) {
      q.add('className=${Uri.encodeComponent(className)}');
    }
    if (subjectId != null) {
      q.add('subjectId=$subjectId');
    }
    return '$baseUrl/mobile/teacher/lessons${q.isNotEmpty ? '?${q.join('&')}' : ''}';
  }

  static String get createTeacherLesson => '$baseUrl/mobile/teacher/lessons';
  static String addLessonTopic(String lessonId) =>
      '$baseUrl/mobile/teacher/lessons/$lessonId/topics';
  static String deleteLesson(String lessonId) =>
      '$baseUrl/mobile/teacher/lessons/$lessonId';
  static String teacherAssignments({String? className, String? subject}) {
    List<String> q = [];
    if (className != null && className.isNotEmpty) {
      q.add('className=${Uri.encodeComponent(className)}');
    }
    if (subject != null && subject.isNotEmpty) {
      q.add('subject=${Uri.encodeComponent(subject)}');
    }
    return '$baseUrl/mobile/teacher/assignments${q.isNotEmpty ? '?${q.join('&')}' : ''}';
  }

  static String get createTeacherAssignment =>
      '$baseUrl/mobile/teacher/assignments';
  static String assignmentSubmissions(String assignmentId) =>
      '$baseUrl/mobile/teacher/assignments/$assignmentId/submissions';
  static String reviewSubmission(String assignmentId, String submissionId) =>
      '$baseUrl/mobile/teacher/assignments/$assignmentId/submissions/$submissionId/review';

  // eSchool Student & Parent Flow (Assignments ID-wise & Submissions)
  static String studentAssignments({String? admissionNo}) =>
      admissionNo != null && admissionNo.isNotEmpty
      ? '$baseUrl/mobile/student/assignments?admissionNo=${Uri.encodeComponent(admissionNo)}'
      : '$baseUrl/mobile/student/assignments';
  static String submitStudentAssignment(String assignmentId) =>
      '$baseUrl/mobile/student/assignments/$assignmentId/submit';

  static String get transportBase => '$baseUrl/v1/transport';

  static String transportDriverDuty({String? email}) =>
      '$transportBase/driver/my-duty${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportStartTrip({String? email}) =>
      '$transportBase/trips/start${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportLiveLocation(dynamic tripId, {String? email}) =>
      '$transportBase/trips/$tripId/locations/live${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportBatchGps(dynamic tripId, {String? email}) =>
      '$transportBase/trips/$tripId/locations:batch${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportStopEvents(
    dynamic tripId,
    dynamic stopId, {
    String? email,
  }) =>
      '$transportBase/trips/$tripId/stops/$stopId/events${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportIncidents(dynamic tripId, {String? email}) =>
      '$transportBase/trips/$tripId/incidents${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportEndTrip(dynamic tripId, {String? email}) =>
      '$transportBase/trips/$tripId/end${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportLiveTracking({String? schoolId}) =>
      '$transportBase/tracking/live${schoolId != null && schoolId.isNotEmpty ? '?schoolId=${Uri.encodeComponent(schoolId)}' : ''}';

  static String transportTripPlayback(dynamic tripId) =>
      '$transportBase/tracking/trips/$tripId/playback';

  static String transportParentChild(dynamic studentId, {String? email}) =>
      '$transportBase/parent/children/$studentId/transport${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportStudentMyTransport({String? email}) =>
      '$transportBase/student/my-transport${email != null && email.isNotEmpty ? '?email=${Uri.encodeComponent(email)}' : ''}';

  static String transportDriverDailyDetails(
    dynamic driverId, {
    String? schoolId,
  }) =>
      '$transportBase/drivers/$driverId/daily-details${schoolId != null && schoolId.isNotEmpty ? '?schoolId=${Uri.encodeComponent(schoolId)}' : ''}';
}
