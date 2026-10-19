import '../../view/widgets/linked_child_scope.dart';
import '../../view/screens/modules/portal_screen.dart';

import 'package:flutter/material.dart';

import 'routes_name.dart';
import '../../view/screens/splash_screen.dart';
import '../../view/screens/login_screen.dart';
import '../../view/screens/dashboard/dashboard_shell.dart';
import '../../view/screens/modules/attendance_screen.dart';
import '../../view/screens/modules/exam_screen.dart';
import '../../view/screens/modules/homework_screen.dart';
import '../../view/screens/modules/fees_screen.dart';
import '../../view/screens/modules/timetable_screen.dart';
import '../../view/screens/modules/notice_screen.dart';
import '../../view/screens/modules/chat_screen.dart';
import '../../view/screens/modules/chat_detail_screen.dart';
import '../../view/screens/modules/expense_screen.dart';
import '../../view/screens/modules/payroll_screen.dart';
import '../../view/screens/modules/leave_screen.dart';
import '../../view/screens/modules/classes_screen.dart';
import '../../view/screens/modules/lesson_screen.dart';
import '../../view/screens/modules/topics_screen.dart';
import '../../view/screens/modules/academic_calendar_screen.dart';
import '../../view/screens/modules/transport/active_trip_screen.dart';
import '../../view/screens/modules/transport/parent_transport_screen.dart';
import '../../view/screens/modules/transport/student_transport_screen.dart';
import '../../data/models/chat_models.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/portal/diary':
      case '/portal/certificates':
      case '/portal/report':
      case '/portal/notifications':
      case '/portal/onlineExams':
        return _slideLeftRoute(
          PortalScreen(module: settings.name!.split('/').last),
          settings,
        );
      case RoutesName.splash:
        return _fadeRoute(const SplashScreen(), settings);

      case RoutesName.login:
        return _slideUpRoute(LoginScreen(), settings);

      case RoutesName.dashboard:
        return _fadeRoute(const DashboardShell(), settings);

      case RoutesName.attendance:
        return _slideLeftRoute(
          LinkedChildScope(
            builder: (admission) => AttendanceScreen(admissionNo: admission),
          ),
          settings,
        );

      case RoutesName.exam:
        final initialTab = settings.arguments is int
            ? settings.arguments as int
            : 0;
        return _slideLeftRoute(
          LinkedChildScope(
            builder: (admission) =>
                ExamScreen(initialTab: initialTab, admissionNo: admission),
          ),
          settings,
        );

      case RoutesName.homework:
        return _slideLeftRoute(
          LinkedChildScope(
            builder: (admission) => HomeworkScreen(admissionNo: admission),
          ),
          settings,
        );

      case RoutesName.fees:
        return _slideLeftRoute(
          LinkedChildScope(
            builder: (admission) => FeesScreen(admissionNo: admission),
          ),
          settings,
        );

      case RoutesName.timetable:
        return _slideLeftRoute(
          LinkedChildScope(
            builder: (admission) => TimetableScreen(admissionNo: admission),
          ),
          settings,
        );

      case RoutesName.notice:
        return _slideLeftRoute(const NoticeScreen(), settings);

      case RoutesName.chat:
        return _slideLeftRoute(const ChatScreen(), settings);

      case RoutesName.chatDetail:
        final args = settings.arguments as ChatChannel;
        return _slideLeftRoute(ChatDetailScreen(channel: args), settings);

      case RoutesName.expense:
        return _slideLeftRoute(const ExpenseScreen(), settings);

      case RoutesName.payroll:
        return _slideLeftRoute(const PayrollScreen(), settings);

      case RoutesName.leave:
        final filter = settings.arguments?.toString();
        return _slideLeftRoute(LeaveScreen(initialFilter: filter), settings);

      case RoutesName.classes:
        return _slideLeftRoute(const ClassesScreen(), settings);

      case RoutesName.lesson:
        return _slideLeftRoute(const LessonScreen(), settings);

      case RoutesName.topics:
        return _slideLeftRoute(const TopicsScreen(), settings);

      case RoutesName.academicCalendar:
        return _slideLeftRoute(const AcademicCalendarScreen(), settings);

      case RoutesName.activeTrip:
        final args = settings.arguments as Map<String, dynamic>?;
        return _slideLeftRoute(ActiveTripScreen(initialData: args), settings);

      case RoutesName.parentTransport:
        final studentId = settings.arguments is int
            ? settings.arguments as int
            : null;
        return _slideLeftRoute(
          ParentTransportScreen(studentId: studentId),
          settings,
        );

      case RoutesName.studentTransport:
        return _slideLeftRoute(const StudentTransportScreen(), settings);

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not defined'))),
        );
    }
  }

  // Slide transition from the right
  static PageRouteBuilder _slideLeftRoute(
    Widget child, [
    RouteSettings? settings,
  ]) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // Slide transition from the bottom (ideal for Login)
  static PageRouteBuilder _slideUpRoute(
    Widget child, [
    RouteSettings? settings,
  ]) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Fade transition for seamless flow
  static PageRouteBuilder _fadeRoute(Widget child, [RouteSettings? settings]) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
