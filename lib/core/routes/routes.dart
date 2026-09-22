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
import '../../data/models/chat_models.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.splash:
        return _fadeRoute(const SplashScreen());

      case RoutesName.login:
        return _slideUpRoute(LoginScreen());

      case RoutesName.dashboard:
        return _fadeRoute(const DashboardShell());

      case RoutesName.attendance:
        return _slideLeftRoute(const AttendanceScreen());

      case RoutesName.exam:
        final initialTab = settings.arguments is int ? settings.arguments as int : 0;
        return _slideLeftRoute(ExamScreen(initialTab: initialTab));

      case RoutesName.homework:
        return _slideLeftRoute(const HomeworkScreen());

      case RoutesName.fees:
        return _slideLeftRoute(const FeesScreen());

      case RoutesName.timetable:
        return _slideLeftRoute(const TimetableScreen());

      case RoutesName.notice:
        return _slideLeftRoute(const NoticeScreen());

      case RoutesName.chat:
        return _slideLeftRoute(const ChatScreen());

      case RoutesName.chatDetail:
        final args = settings.arguments as ChatChannel;
        return _slideLeftRoute(ChatDetailScreen(channel: args));

      case RoutesName.expense:
        return _slideLeftRoute(const ExpenseScreen());

      case RoutesName.payroll:
        return _slideLeftRoute(const PayrollScreen());

      case RoutesName.leave:
        return _slideLeftRoute(const LeaveScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not defined')),
          ),
        );
    }
  }

  // Slide transition from the right
  static PageRouteBuilder _slideLeftRoute(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // Slide transition from the bottom (ideal for Login)
  static PageRouteBuilder _slideUpRoute(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Fade transition for seamless flow
  static PageRouteBuilder _fadeRoute(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
