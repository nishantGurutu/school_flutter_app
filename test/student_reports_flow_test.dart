import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/data/models/student_report_model.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';
import 'package:school_desk_app/data/repositories/student_reports_repository.dart';
import 'package:school_desk_app/view/widgets/student_reports_dialog.dart';

class ReportsApi extends NetworkApiService {
  String? url;
  bool fail = false;
  List<Map<String, dynamic>> reports = [
    {
      'id': 7,
      'title': 'Term report',
      'term': 'Term 1',
      'studentName': 'Student',
      'fileName': 'report.pdf',
      'fileUrl': '/api/student-reports/7/pdf',
      'createdAt': '2026-10-28T10:00:00',
    },
  ];
  @override
  Future<dynamic> getApi(String url) async {
    this.url = url;
    if (fail) throw StateError('Offline');
    return reports;
  }
}

void main() {
  test(
    'Uses authenticated report list and preserves protected PDF URL',
    () async {
      final api = ReportsApi();
      final repo = StudentReportsRepository(api: api);
      final reports = await repo.getReports();
      expect(api.url, endsWith('/student-reports'));
      expect(reports.single.fileUrl, '/api/student-reports/7/pdf');
      await repo.getReports(admissionNo: 'ADM/1');
      expect(api.url, endsWith('?admissionNo=ADM%2F1'));
    },
  );

  testWidgets(
    'Report dialog retries, shows server report and refresh clears removed reports',
    (tester) async {
      final api = ReportsApi()..fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudentReportsDialog(
              repository: StudentReportsRepository(api: api),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to load reports. Please try again.'),
        findsOneWidget,
      );
      api.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Term report'), findsOneWidget);
      api.reports = [];
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(
        find.text('No reports have been published for you yet.'),
        findsOneWidget,
      );
      expect(find.text('Term report'), findsNothing);
    },
  );

  testWidgets('Tapping a report returns the actual selected report', (
    tester,
  ) async {
    StudentReportModel? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showDialog<StudentReportModel>(
                  context: context,
                  builder: (_) => StudentReportsDialog(
                    repository: StudentReportsRepository(api: ReportsApi()),
                  ),
                );
              },
              child: const Text('Reports'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Term report'));
    await tester.pumpAndSettle();
    expect(selected?.id, '7');
    expect(selected?.fileUrl, '/api/student-reports/7/pdf');
  });
}
