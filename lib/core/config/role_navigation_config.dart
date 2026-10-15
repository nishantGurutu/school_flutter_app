import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../routes/routes_name.dart';
import '../theme/app_colors.dart';

class RoleNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String key;

  const RoleNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.key,
  });
}

class QuickAccessAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  final dynamic arguments;

  const QuickAccessAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
    this.arguments,
  });
}

class DrawerMenuItem {
  final IconData icon;
  final String label;
  final String route;
  final dynamic arguments;
  final bool isHeaderDivider;

  const DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.route,
    this.arguments,
    this.isHeaderDivider = false,
  });
}

class RoleNavigationConfig {
  static List<RoleNavItem> getBottomNavItems(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const [
          RoleNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            key: 'home',
          ),
          RoleNavItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Homework',
            key: 'homework',
          ),
          RoleNavItem(
            icon: Icons.quiz_outlined,
            activeIcon: Icons.quiz_rounded,
            label: 'Exams',
            key: 'exams',
          ),
          RoleNavItem(
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign_rounded,
            label: 'Notices',
            key: 'notices',
          ),
          RoleNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            key: 'profile',
          ),
        ];

      case UserRole.parent:
        return const [
          RoleNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            key: 'home',
          ),
          RoleNavItem(
            icon: Icons.account_balance_wallet_outlined,
            activeIcon: Icons.account_balance_wallet_rounded,
            label: 'Fees',
            key: 'fees',
          ),
          RoleNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Attendance',
            key: 'attendance',
          ),
          RoleNavItem(
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign_rounded,
            label: 'Notices',
            key: 'notices',
          ),
          RoleNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            key: 'profile',
          ),
        ];

      case UserRole.teacher:
        return const [
          RoleNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            key: 'home',
          ),
          RoleNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Attendance',
            key: 'attendance',
          ),
          RoleNavItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Homework',
            key: 'homework',
          ),
          RoleNavItem(
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign_rounded,
            label: 'Notices',
            key: 'notices',
          ),
          RoleNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            key: 'profile',
          ),
        ];

      case UserRole.staff:
      case UserRole.admin:
      case UserRole.masterAdmin:
        return const [
          RoleNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
            key: 'home',
          ),
          RoleNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Attendance',
            key: 'attendance',
          ),
          RoleNavItem(
            icon: Icons.event_note_outlined,
            activeIcon: Icons.event_note_rounded,
            label: 'Leaves',
            key: 'leaves',
          ),
          RoleNavItem(
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign_rounded,
            label: 'Notices',
            key: 'notices',
          ),
          RoleNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            key: 'profile',
          ),
        ];

      case UserRole.driver:
        return const [
          RoleNavItem(
            icon: Icons.directions_bus_outlined,
            activeIcon: Icons.directions_bus_rounded,
            label: 'Duty',
            key: 'home',
          ),
          RoleNavItem(
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign_rounded,
            label: 'Notices',
            key: 'notices',
          ),
          RoleNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
            key: 'profile',
          ),
        ];
    }
  }

  static List<QuickAccessAction> getQuickAccessActions(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const [
          QuickAccessAction(
            label: 'Attendance',
            icon: Icons.calendar_month_rounded,
            color: AppColors.success,
            route: RoutesName.attendance,
          ),
          QuickAccessAction(
            label: 'Homework',
            icon: Icons.assignment_outlined,
            color: AppColors.primary,
            route: RoutesName.homework,
          ),
          QuickAccessAction(
            label: 'Exams',
            icon: Icons.quiz_outlined,
            color: AppColors.info,
            route: RoutesName.exam,
          ),
          QuickAccessAction(
            label: 'Time Table',
            icon: Icons.schedule_rounded,
            color: AppColors.secondary,
            route: RoutesName.timetable,
          ),
          QuickAccessAction(
            label: 'Results',
            icon: Icons.grade_outlined,
            color: AppColors.warning,
            route: RoutesName.exam,
            arguments: 1,
          ),
          QuickAccessAction(
            label: 'Fees',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.error,
            route: RoutesName.fees,
          ),
          QuickAccessAction(
            label: 'School Bus',
            icon: Icons.directions_bus_rounded,
            color: Color(0xFF0D9488),
            route: RoutesName.studentTransport,
          ),
        ];

      case UserRole.parent:
        return const [
          QuickAccessAction(
            label: 'Live Bus',
            icon: Icons.directions_bus_rounded,
            color: Color(0xFF0D9488),
            route: RoutesName.parentTransport,
          ),
          QuickAccessAction(
            label: 'Attendance',
            icon: Icons.calendar_month_rounded,
            color: AppColors.success,
            route: RoutesName.attendance,
          ),
          QuickAccessAction(
            label: 'Fees Due',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.error,
            route: RoutesName.fees,
          ),
          QuickAccessAction(
            label: 'Homework',
            icon: Icons.assignment_outlined,
            color: AppColors.primary,
            route: RoutesName.homework,
          ),
          QuickAccessAction(
            label: 'Results',
            icon: Icons.grade_outlined,
            color: AppColors.warning,
            route: RoutesName.exam,
            arguments: 1,
          ),
          QuickAccessAction(
            label: 'Timetable',
            icon: Icons.schedule_rounded,
            color: AppColors.secondary,
            route: RoutesName.timetable,
          ),
          QuickAccessAction(
            label: 'Notices',
            icon: Icons.campaign_outlined,
            color: AppColors.info,
            route: RoutesName.notice,
          ),
        ];

      case UserRole.teacher:
        return const [
          QuickAccessAction(
            label: 'Assignment',
            icon: Icons.assignment_rounded,
            color: Color(0xFF0284C7),
            route: RoutesName.homework,
          ),
          QuickAccessAction(
            label: 'Classes',
            icon: Icons.class_rounded,
            color: Color(0xFF4F46E5),
            route: RoutesName.classes,
          ),
          QuickAccessAction(
            label: 'Lesson',
            icon: Icons.menu_book_rounded,
            color: Color(0xFF059669),
            route: RoutesName.lesson,
          ),
        ];

      case UserRole.staff:
      case UserRole.admin:
      case UserRole.masterAdmin:
        return const [
          QuickAccessAction(
            label: 'Attendance',
            icon: Icons.calendar_month_rounded,
            color: AppColors.success,
            route: RoutesName.attendance,
          ),
          QuickAccessAction(
            label: 'Leave Approv.',
            icon: Icons.assignment_turned_in_outlined,
            color: AppColors.primary,
            route: RoutesName.leave,
          ),
          QuickAccessAction(
            label: 'Expenses',
            icon: Icons.payments_outlined,
            color: AppColors.error,
            route: RoutesName.expense,
          ),
          QuickAccessAction(
            label: 'Payroll',
            icon: Icons.receipt_long_outlined,
            color: AppColors.warning,
            route: RoutesName.payroll,
          ),
          QuickAccessAction(
            label: 'Notices',
            icon: Icons.campaign_outlined,
            color: AppColors.secondary,
            route: RoutesName.notice,
          ),
          QuickAccessAction(
            label: 'Timetable',
            icon: Icons.schedule_rounded,
            color: AppColors.info,
            route: RoutesName.timetable,
          ),
        ];

      case UserRole.driver:
        return const [
          QuickAccessAction(
            label: 'My Duty',
            icon: Icons.directions_bus_rounded,
            color: Color(0xFF0D9488),
            route: RoutesName.dashboard,
          ),
          QuickAccessAction(
            label: 'Active GPS Trip',
            icon: Icons.navigation_rounded,
            color: Color(0xFF10B981),
            route: RoutesName.activeTrip,
          ),
          QuickAccessAction(
            label: 'Notices',
            icon: Icons.campaign_outlined,
            color: AppColors.secondary,
            route: RoutesName.notice,
          ),
        ];
    }
  }

  static List<DrawerMenuItem> getDrawerItems(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const [
          DrawerMenuItem(icon: Icons.directions_bus_rounded, label: 'My School Bus', route: RoutesName.studentTransport),
          DrawerMenuItem(icon: Icons.calendar_month_rounded, label: 'My Attendance', route: RoutesName.attendance),
          DrawerMenuItem(icon: Icons.assignment_outlined, label: 'Homework & Tasks', route: RoutesName.homework),
          DrawerMenuItem(icon: Icons.quiz_outlined, label: 'Exam Schedule & Marks', route: RoutesName.exam),
          DrawerMenuItem(icon: Icons.account_balance_wallet_outlined, label: 'Fees & Invoices', route: RoutesName.fees),
          DrawerMenuItem(icon: Icons.campaign_outlined, label: 'Noticeboard', route: RoutesName.notice),
          DrawerMenuItem(icon: Icons.schedule_rounded, label: 'Class Timetable', route: RoutesName.timetable),
          DrawerMenuItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages / Chats', route: RoutesName.chat),
        ];

      case UserRole.parent:
        return const [
          DrawerMenuItem(icon: Icons.directions_bus_rounded, label: 'Live Bus Tracking', route: RoutesName.parentTransport),
          DrawerMenuItem(icon: Icons.calendar_month_rounded, label: 'Child Attendance', route: RoutesName.attendance),
          DrawerMenuItem(icon: Icons.account_balance_wallet_outlined, label: 'School Fees Payment', route: RoutesName.fees),
          DrawerMenuItem(icon: Icons.assignment_outlined, label: 'Child Homework', route: RoutesName.homework),
          DrawerMenuItem(icon: Icons.grade_outlined, label: 'Exam Results & Report Card', route: RoutesName.exam, arguments: 1),
          DrawerMenuItem(icon: Icons.campaign_outlined, label: 'School Circulars & Notices', route: RoutesName.notice),
          DrawerMenuItem(icon: Icons.schedule_rounded, label: 'Class Timetable', route: RoutesName.timetable),
          DrawerMenuItem(icon: Icons.chat_bubble_outline_rounded, label: 'Contact Teachers', route: RoutesName.chat),
        ];

      case UserRole.teacher:
        return const [
          DrawerMenuItem(icon: Icons.assignment_outlined, label: 'Assignment', route: RoutesName.homework),
          DrawerMenuItem(icon: Icons.class_rounded, label: 'Classes', route: RoutesName.classes),
          DrawerMenuItem(icon: Icons.menu_book_rounded, label: 'Lesson', route: RoutesName.lesson),
          DrawerMenuItem(icon: Icons.schedule_rounded, label: 'Schedule / Timetable', route: RoutesName.timetable),
          DrawerMenuItem(icon: Icons.campaign_outlined, label: 'School Notices', route: RoutesName.notice),
        ];

      case UserRole.staff:
      case UserRole.admin:
      case UserRole.masterAdmin:
        return const [
          DrawerMenuItem(icon: Icons.calendar_month_rounded, label: 'Staff Attendance Master', route: RoutesName.attendance),
          DrawerMenuItem(icon: Icons.assignment_turned_in_outlined, label: 'Leave Approvals', route: RoutesName.leave),
          DrawerMenuItem(icon: Icons.payments_outlined, label: 'Expense Management', route: RoutesName.expense),
          DrawerMenuItem(icon: Icons.receipt_long_outlined, label: 'Salary & Payroll', route: RoutesName.payroll),
          DrawerMenuItem(icon: Icons.campaign_outlined, label: 'Publish & View Notices', route: RoutesName.notice),
          DrawerMenuItem(icon: Icons.schedule_rounded, label: 'Timetable Overview', route: RoutesName.timetable),
        ];

      case UserRole.driver:
        return const [
          DrawerMenuItem(icon: Icons.directions_bus_rounded, label: 'My Duty Schedule', route: RoutesName.dashboard),
          DrawerMenuItem(icon: Icons.navigation_rounded, label: 'Active GPS Tracking Trip', route: RoutesName.activeTrip),
          DrawerMenuItem(icon: Icons.campaign_outlined, label: 'School Notices', route: RoutesName.notice),
        ];
    }
  }
}
