import 'package:flutter/material.dart';
import '../../data/models/student_report_model.dart';
import '../../data/repositories/student_reports_repository.dart';
import '../../utils/app_url.dart';
import 'study_note_pdf_preview.dart';

class StudentReportsDialog extends StatefulWidget {
  final String? admissionNo;
  final StudentReportsRepository? repository;
  const StudentReportsDialog({super.key, this.admissionNo, this.repository});
  static Future<void> show(BuildContext context, {String? admissionNo}) async {
    final report = await showDialog<StudentReportModel>(
      context: context,
      builder: (_) => StudentReportsDialog(admissionNo: admissionNo),
    );
    if (report == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StudentReportScreen(report: report),
      ),
    );
  }

  @override
  State<StudentReportsDialog> createState() => _StudentReportsDialogState();
}

class _StudentReportsDialogState extends State<StudentReportsDialog> {
  late final StudentReportsRepository _repository =
      widget.repository ?? StudentReportsRepository();
  late Future<List<StudentReportModel>> _reports;
  @override
  void initState() {
    super.initState();
    _reports = _repository.getReports(admissionNo: widget.admissionNo);
  }

  void _refresh() => setState(() {
    _reports = _repository.getReports(admissionNo: widget.admissionNo);
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('My Reports'),
    content: SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .55,
        ),
        child: FutureBuilder<List<StudentReportModel>>(
          future: _reports,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load reports. Please try again.'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              );
            }
            final reports = snapshot.data ?? [];
            if (reports.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No reports have been published for you yet.'),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: reports.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final report = reports[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Text(report.title),
                  subtitle: Text(
                    [
                      report.term,
                      report.date,
                      report.fileName,
                    ].where((value) => value.isNotEmpty).join('\n'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, report),
                );
              },
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: _refresh, child: const Text('Refresh')),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

class StudentReportScreen extends StatelessWidget {
  final StudentReportModel report;
  const StudentReportScreen({super.key, required this.report});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(report.title)),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            [
              report.studentName,
              report.term,
              report.description,
            ].where((value) => value.isNotEmpty).join('\n'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: StudyNotePdfPreview(
            uri: Uri.parse(AppUrl.baseUrl).resolve(report.fileUrl),
            fileName: report.fileName.isEmpty
                ? 'Student-report.pdf'
                : report.fileName,
          ),
        ),
      ],
    ),
  );
}
