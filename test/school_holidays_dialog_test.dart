import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/school_models.dart';
import 'package:school_desk_app/data/models/user_model.dart';
import 'package:school_desk_app/data/repositories/api_school_repository.dart';
import 'package:school_desk_app/view/widgets/school_holidays_dialog.dart';

class HolidaysRepository extends ApiSchoolRepository {
  bool fail = false;
  List<HolidayModel> holidays = [
    const HolidayModel(
      id: '1',
      title: 'Student break',
      date: '2026-11-02',
      endDate: '2026-11-04',
      target: 'STUDENTS',
    ),
    const HolidayModel(
      id: '2',
      title: 'Staff break',
      date: '2026-11-03',
      target: 'STAFF',
    ),
    const HolidayModel(
      id: '3',
      title: 'School break',
      date: '2026-11-01',
      target: 'ALL',
    ),
  ];
  @override
  Future<List<HolidayModel>> getLiveHolidays() async {
    if (fail) throw StateError('Offline');
    return holidays;
  }
}

void main() {
  testWidgets('Student dialog shows dashboard dates and correct targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SchoolHolidaysDialog(
            role: UserRole.student,
            repository: HolidaysRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Student break'), findsOneWidget);
    expect(find.text('School break'), findsOneWidget);
    expect(find.text('Staff break'), findsNothing);
    expect(find.textContaining('2026-11-02 – 2026-11-04'), findsOneWidget);
  });

  testWidgets('Teacher dialog excludes student-only holidays', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SchoolHolidaysDialog(
            role: UserRole.teacher,
            repository: HolidaysRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Staff break'), findsOneWidget);
    expect(find.text('School break'), findsOneWidget);
    expect(find.text('Student break'), findsNothing);
  });

  testWidgets('Retry fetches fresh data and refresh handles deleted holidays', (
    tester,
  ) async {
    final repo = HolidaysRepository()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SchoolHolidaysDialog(role: UserRole.student, repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to load holidays. Please try again.'),
      findsOneWidget,
    );
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Student break'), findsOneWidget);
    repo.holidays = [];
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(
      find.text('No holidays have been added for you yet.'),
      findsOneWidget,
    );
    expect(find.text('Student break'), findsNothing);
  });
}
