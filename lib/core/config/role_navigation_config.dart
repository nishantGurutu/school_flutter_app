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
            label: 'Notices',
            icon: Icons.campaign_outlined,
            color: AppColors.secondary,
            route: RoutesName.notice,
          ),
        ];

      case UserRole.parent:
        return const [
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
            label: 'Classes',
            icon: Icons.class_rounded,
            color: Color(0xFF4F46E5),
            route: RoutesName.classes,
          ),
          QuickAccessAction(
            label: 'Assignment',
            icon: Icons.assignment_rounded,
            color: Color(0xFF0284C7),
            route: RoutesName.homework,
          ),
          QuickAccessAction(
            label: 'Announcement',
            icon: Icons.campaign_rounded,
            color: Color(0xFFD97706),
            route: RoutesName.notice,
          ),
          QuickAccessAction(
            label: 'Lesson',
            icon: Icons.menu_book_rounded,
            color: Color(0xFF059669),
            route: RoutesName.lesson,
          ),
          QuickAccessAction(
            label: 'Topics',
            icon: Icons.format_list_bulleted_rounded,
            color: Color(0xFF7C3AED),
            route: RoutesName.topics,
          ),
          QuickAccessAction(
            label: 'Attendance',
            icon: Icons.fact_check_rounded,
            color: Color(0xFF16A34A),
            route: RoutesName.attendance,
          ),
          QuickAccessAction(
            label: 'Student Leaves',
            icon: Icons.approval_rounded,
            color: Color(0xFFDB2777),
            route: RoutesName.leave,
            arguments: 'student_leaves',
          ),
          QuickAccessAction(
            label: 'Add Result',
            icon: Icons.post_add_rounded,
            color: Color(0xFFEA580C),
            route: RoutesName.exam,
            arguments: 1,
          ),
          QuickAccessAction(
            label: 'Manage Leave',
            icon: Icons.time_to_leave_rounded,
            color: Color(0xFFDC2626),
            route: RoutesName.leave,
            arguments: 'manage_leave',
          ),
          QuickAccessAction(
            label: 'Academic Calendar',
            icon: Icons.calendar_month_rounded,
            color: Color(0xFF2563EB),
            route: RoutesName.academicCalendar,
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
    }
  }

  static List<DrawerMenuItem> getDrawerItems(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const [
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
          DrawerMenuItem(icon: Icons.class_rounded, label: 'Classes', route: RoutesName.classes),
          DrawerMenuItem(icon: Icons.assignment_outlined, label: 'Assignment', route: RoutesName.homework),
          DrawerMenuItem(icon: Icons.campaign_outlined, label: 'Announcement', route: RoutesName.notice),
          DrawerMenuItem(icon: Icons.menu_book_rounded, label: 'Lesson', route: RoutesName.lesson),
          DrawerMenuItem(icon: Icons.format_list_bulleted_rounded, label: 'Topics', route: RoutesName.topics),
          DrawerMenuItem(icon: Icons.fact_check_rounded, label: 'Attendance', route: RoutesName.attendance),
          DrawerMenuItem(icon: Icons.approval_rounded, label: 'Student Leaves', route: RoutesName.leave, arguments: 'student_leaves'),
          DrawerMenuItem(icon: Icons.post_add_rounded, label: 'Add Result', route: RoutesName.exam, arguments: 1),
          DrawerMenuItem(icon: Icons.time_to_leave_rounded, label: 'Manage Leave', route: RoutesName.leave, arguments: 'manage_leave'),
          DrawerMenuItem(icon: Icons.calendar_month_rounded, label: 'Academic Calendar', route: RoutesName.academicCalendar),
          DrawerMenuItem(icon: Icons.schedule_rounded, label: 'Schedule / Timetable', route: RoutesName.timetable),
          DrawerMenuItem(icon: Icons.chat_bubble_outline_rounded, label: 'Student Messages', route: RoutesName.chat),
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
    }
  }
}
