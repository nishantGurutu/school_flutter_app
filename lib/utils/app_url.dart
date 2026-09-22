class AppUrl {
  static const String baseUrl = 'http://192.168.31.225:8080/api';
  // static const String baseUrl = 'http://localhost:8080/api';

  // Auth Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String refresh = '$baseUrl/auth/refresh';
  static const String logout = '$baseUrl/auth/logout';

  // Mobile App Dynamic Endpoints
  static const String profileMe = '$baseUrl/mobile/profile/me';
  static const String attendance = '$baseUrl/mobile/attendance';
  static const String markAttendance = '$baseUrl/mobile/attendance/mark';
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
}
