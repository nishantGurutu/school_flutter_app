import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/user_model.dart';
import 'package:school_desk_app/logic/auth/auth_bloc.dart';
import 'package:school_desk_app/logic/auth/auth_event.dart';
import 'package:school_desk_app/logic/auth/auth_state.dart';
import 'package:school_desk_app/logic/school/school_bloc.dart';
import 'package:school_desk_app/logic/school/school_event.dart';
import 'package:school_desk_app/logic/school/school_state.dart';
import 'package:school_desk_app/view/screens/modules/exam_screen.dart';

class RoleAuthBloc extends Cubit<AuthState> implements AuthBloc {
  RoleAuthBloc(UserRole role)
    : super(
        AuthState(
          user: UserModel(
            id: '1',
            name: 'User',
            email: 'user@test.local',
            role: role,
            avatarUrl: '',
            details: '',
          ),
        ),
      );
  @override
  void add(AuthEvent event) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmptyExamBloc extends Cubit<SchoolState> implements SchoolBloc {
  EmptyExamBloc() : super(const SchoolState());
  @override
  void add(SchoolEvent event) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final role in UserRole.values) {
    testWidgets('Exam Add is teacher-only for ${role.name}', (tester) async {
      final auth = RoleAuthBloc(role);
      final school = EmptyExamBloc();
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: auth),
            BlocProvider<SchoolBloc>.value(value: school),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => const MaterialApp(home: ExamScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Schedule New Exam'),
        role == UserRole.teacher ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Schedule Exam'),
        role == UserRole.teacher ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
      await auth.close();
      await school.close();
    });
  }
}
