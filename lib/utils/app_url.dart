class AppUrl {
  // static const String baseUrl =
  //     'https://school-springboot-backend.onrender.com/api';
  static const String baseUrl = 'http://192.168.31.210:8080/api';
  // static const String baseUrl = 'http://localhost:8080/api';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String refresh = '$baseUrl/auth/refresh';
  static const String logout = '$baseUrl/auth/logout';

  // Mobile App Dynamic Endpoints
  static const String profileMe = '$baseUrl/mobile/profile/me';
  static const String attendance = '$baseUrl/mobile/attendance';
  static const String holidays = '$baseUrl/mobile/holidays';
  static const String markAttendance = '$baseUrl/mobile/attendance/mark';
  static const String checkIn = '$baseUrl/mobile/attendance/check-in';
  static const String checkOut = '$baseUrl/mobile/attendance/check-out';
  static const String attendanceStats = '$baseUrl/mobile/attendance/stats';
  static const String homework = '$baseUrl/mobile/homework';
  static String submitHomework(String id) =>
      '$baseUrl/mobile/homework/submit/$id';
  static const String fees = '$baseUrl/mobile/fees';
  static String payFee(String id) => '$baseUrl/mobile/fees/pay/$id';
  static const String timetable = '$baseUrl/mobile/timetable';
  static const String exams = '$baseUrl/mobile/exams';
  static const String createExam = '$baseUrl/mobile/exams';
  static String uploadExamScore(String id) => '$baseUrl/mobile/exams/$id/score';
  static const String expenses = '$baseUrl/mobile/expenses';
  static String approveExpense(String id) =>
      '$baseUrl/mobile/expenses/$id/approve';
  static const String payroll = '$baseUrl/mobile/payroll';
  static const String leaves = '$baseUrl/mobile/leaves';
  static String approveLeave(String id) => '$baseUrl/mobile/leaves/$id/approve';
  static String rejectLeave(String id) => '$baseUrl/mobile/leaves/$id/reject';
  static const String notices = '$baseUrl/mobile/notices';
  static const String homeDashboard = '$baseUrl/mobile/dashboard/home';
  static String homeDashboardWithStudent(String admissionNo) =>
      '$baseUrl/mobile/dashboard/home?admissionNo=${Uri.encodeComponent(admissionNo)}';

  // Curriculum & Study Notes
  static String subjectCurriculum(String subjectId) =>
      '$baseUrl/mobile/subjects/$subjectId/curriculum';
  static String chapterNotes(String chapterId) =>
      '$baseUrl/mobile/chapters/$chapterId/notes';
  static String topicNotes(String topicId) =>
      '$baseUrl/mobile/topics/$topicId/notes';

  // eSchool Teacher Flow (Classes, Lessons, Assignments ID-wise)
  static const String teacherClasses = '$baseUrl/mobile/teacher/classes';
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

  static const String createTeacherLesson = '$baseUrl/mobile/teacher/lessons';
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

  static const String createTeacherAssignment =
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

  // ==========================================
  // Transport & Driver Tracking Endpoints
  // ==========================================
  static const String transportBase = '$baseUrl/v1/transport';

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
