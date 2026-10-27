import 'package:flutter/material.dart';
import '../../data/models/student_teacher_model.dart';
import '../../data/repositories/student_teachers_repository.dart';

class StudentTeachersDialog extends StatefulWidget {
  final String? admissionNo;
  final StudentTeachersRepository? repository;
  const StudentTeachersDialog({super.key, this.admissionNo, this.repository});
  static void show(BuildContext context, {String? admissionNo}) {
    showDialog<void>(
      context: context,
      builder: (_) => StudentTeachersDialog(admissionNo: admissionNo),
    );
  }

  @override
  State<StudentTeachersDialog> createState() => _StudentTeachersDialogState();
}

class _StudentTeachersDialogState extends State<StudentTeachersDialog> {
  late final StudentTeachersRepository _repository =
      widget.repository ?? StudentTeachersRepository();
  late Future<List<StudentTeacherModel>> _teachers;
  @override
  void initState() {
    super.initState();
    _teachers = _repository.getTeachers(admissionNo: widget.admissionNo);
  }

  void _refresh() => setState(() {
    _teachers = _repository.getTeachers(admissionNo: widget.admissionNo);
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('My Teachers'),
    content: SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .6,
        ),
        child: FutureBuilder<List<StudentTeacherModel>>(
          future: _teachers,
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
                  const Text('Unable to load teachers. Please try again.'),
                  TextButton(onPressed: _refresh, child: const Text('Retry')),
                ],
              );
            }
            final teachers = snapshot.data ?? [];
            if (teachers.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No teachers are assigned to your class yet.'),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: teachers.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.school_outlined),
                  ),
                  title: Text(teacher.name.isEmpty ? 'Teacher' : teacher.name),
                  subtitle: Text(
                    [
                      teacher.subject,
                      teacher.designation,
                      teacher.email,
                      teacher.phone,
                    ].where((text) => text.isNotEmpty).join('\n'),
                  ),
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
