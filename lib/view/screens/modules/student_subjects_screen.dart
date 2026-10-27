import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import 'subject_curriculum_screen.dart';

class StudentSubjectsScreen extends StatefulWidget {
  final bool isInline;
  final String? admissionNo;
  final ApiSchoolRepository? repository;
  const StudentSubjectsScreen({
    super.key,
    this.isInline = false,
    this.admissionNo,
    this.repository,
  });

  @override
  State<StudentSubjectsScreen> createState() => _StudentSubjectsScreenState();
}

class _StudentSubjectsScreenState extends State<StudentSubjectsScreen> {
  late final ApiSchoolRepository _repository =
      widget.repository ?? ApiSchoolRepository();
  late Future<List<DashboardSubject>> _subjects;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _subjects = _repository.getStudentSubjects(admissionNo: widget.admissionNo);
  }

  @override
  void didUpdateWidget(covariant StudentSubjectsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.admissionNo != widget.admissionNo) {
      _query = '';
      _subjects = _repository.getStudentSubjects(
        admissionNo: widget.admissionNo,
      );
    }
  }

  Future<void> _refresh() async {
    final request = _repository.getStudentSubjects(
      admissionNo: widget.admissionNo,
    );
    setState(() {
      _subjects = request;
    });
    try {
      await request;
    } catch (_) {
      /* FutureBuilder displays the retry state. */
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('My Subjects'),
      automaticallyImplyLeading: !widget.isInline,
      actions: [
        IconButton(
          tooltip: 'Refresh subjects',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search subjects',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DashboardSubject>>(
            future: _subjects,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load subjects. Please try again.'),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              final all = snapshot.data ?? [];
              final subjects = all
                  .where(
                    (subject) => '${subject.name} ${subject.code}'
                        .toLowerCase()
                        .contains(_query),
                  )
                  .toList();
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  children: [
                    if (all.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No subjects have been added for your class.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (subjects.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No matching subjects.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ...subjects.map(
                      (subject) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.menu_book_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(subject.name),
                          subtitle: subject.code.isEmpty
                              ? null
                              : Text(subject.code),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => SubjectCurriculumScreen(
                                repository: _repository,
                                subjectId: subject.id.toString(),
                                subjectName: subject.name,
                                subjectCode: subject.code,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
