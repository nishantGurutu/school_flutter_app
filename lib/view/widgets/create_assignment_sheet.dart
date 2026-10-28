import 'package:flutter/material.dart';
import '../../data/models/school_models.dart';
import '../../data/repositories/api_school_repository.dart';

class CreateAssignmentSheet extends StatefulWidget {
  final ApiSchoolRepository repository;
  final dynamic prefilledStudentId;
  final String? prefilledClass, prefilledSection;
  const CreateAssignmentSheet({
    super.key,
    required this.repository,
    this.prefilledStudentId,
    this.prefilledClass,
    this.prefilledSection,
  });
  @override
  State<CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<CreateAssignmentSheet> {
  final _title = TextEditingController(),
      _description = TextEditingController(),
      _subject = TextEditingController(),
      _points = TextEditingController(text: '100'),
      _attachment = TextEditingController();
  List<TeacherClassModel> _classes = [];
  List<StudentInClassModel> _students = [];
  String? _className, _section, _classError, _studentError, _saveError;
  dynamic _studentId;
  bool _loadingClasses = true, _loadingStudents = false, _saving = false;
  late bool _targeted = widget.prefilledStudentId != null;
  int _studentRequest = 0;
  DateTime _due = DateTime.now().add(const Duration(days: 3));
  List<String> get _classNames =>
      _classes.map((c) => c.className).toSet().toList();
  List<String> get _sections => _classes
      .where((c) => c.className == _className)
      .map((c) => c.section)
      .toSet()
      .toList();
  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _description,
      _subject,
      _points,
      _attachment,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _classError = null;
    });
    try {
      final rows = await widget.repository.getTeacherClasses(
        throwOnError: true,
      );
      if (!mounted) return;
      setState(() {
        _classes = rows.where((c) => c.className.trim().isNotEmpty).toList();
        _className = _classNames.contains(widget.prefilledClass)
            ? widget.prefilledClass
            : _classNames.firstOrNull;
        _section = _sections.contains(widget.prefilledSection)
            ? widget.prefilledSection
            : _sections.firstOrNull;
        _loadingClasses = false;
        if (_classes.isNotEmpty && _subject.text.isEmpty)
          _subject.text = _classes
              .firstWhere((c) => c.className == _className)
              .subject;
      });
      if (_targeted) await _loadStudents(prefilled: widget.prefilledStudentId);
    } catch (error) {
      if (mounted)
        setState(() {
          _classError = error.toString();
          _loadingClasses = false;
        });
    }
  }

  Future<void> _loadStudents({dynamic prefilled}) async {
    final request = ++_studentRequest;
    setState(() {
      _studentId = null;
      _students = [];
      _studentError = null;
      _loadingStudents = false;
    });
    final className = _className, section = _section;
    if (className == null || section == null) return;
    setState(() => _loadingStudents = true);
    try {
      final rows = await widget.repository.getClassStudents(
        className,
        section: section.isEmpty ? null : section,
        throwOnError: true,
      );
      if (!mounted || request != _studentRequest) return;
      setState(() {
        _students = rows;
        _loadingStudents = false;
        _studentId = rows
            .where((s) => s.id.toString() == prefilled?.toString())
            .firstOrNull
            ?.id;
      });
    } catch (error) {
      if (mounted && request == _studentRequest)
        setState(() {
          _loadingStudents = false;
          _studentError = error.toString();
        });
    }
  }

  void _changeClass(String? value) {
    ++_studentRequest;
    setState(() {
      _className = value;
      _section = _sections.firstOrNull;
      _studentId = null;
      _students = [];
      _studentError = null;
      _loadingStudents = false;
    });
    if (_targeted) _loadStudents();
  }

  void _changeSection(String? value) {
    ++_studentRequest;
    setState(() {
      _section = value;
      _studentId = null;
      _students = [];
      _studentError = null;
      _loadingStudents = false;
    });
    if (_targeted) _loadStudents();
  }

  Future<void> _publish() async {
    if (_saving ||
        _loadingClasses ||
        _className == null ||
        _section == null ||
        (_targeted &&
            (_loadingStudents || _studentId == null || _studentError != null)))
      return;
    final points = int.tryParse(_points.text.trim());
    if (_title.text.trim().isEmpty ||
        _subject.text.trim().isEmpty ||
        points == null ||
        points <= 0) {
      setState(() => _saveError = 'Enter title, subject and positive points.');
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final created = await widget.repository.createTeacherAssignment(
        title: _title.text.trim(),
        description: _description.text.trim(),
        subject: _subject.text.trim(),
        className: _className!,
        section: _section!,
        dueDate: _due.toIso8601String().split('T').first,
        points: points,
        targetStudentId: _targeted ? _studentId : null,
        fileAttachmentUrl: _attachment.text.trim(),
      );
      if (created == null)
        throw StateError('Could not publish assignment. Please retry.');
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _saveError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());
  @override
  Widget build(BuildContext context) {
    final blocked =
        _saving ||
        _loadingClasses ||
        _classError != null ||
        _className == null ||
        _section == null;
    return PopScope(
      canPop: !_saving,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create New Assignment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_loadingClasses)
                  const Center(child: CircularProgressIndicator()),
                if (_classError != null) ...[
                  Text(_classError!, key: const Key('assignment-class-error')),
                  TextButton(
                    onPressed: _loadClasses,
                    child: const Text('Retry classes'),
                  ),
                ],
                if (!_loadingClasses && _classError == null && _classes.isEmpty)
                  const Text(
                    'No classes are assigned to this teacher. Ask your administrator to assign a class.',
                  ),
                TextField(
                  controller: _title,
                  decoration: _decoration('Assignment Title'),
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('class-$_className'),
                  initialValue: _className,
                  isExpanded: true,
                  decoration: _decoration('Class'),
                  items: _classNames
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: blocked ? null : _changeClass,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('section-$_className-$_section'),
                  initialValue: _section,
                  isExpanded: true,
                  decoration: _decoration('Section'),
                  items: _sections
                      .map(
                        (section) => DropdownMenuItem(
                          value: section,
                          child: Text(
                            section.isEmpty ? 'All sections' : section,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: blocked ? null : _changeSection,
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Whole Class')),
                    ButtonSegment(value: true, label: Text('Specific Student')),
                  ],
                  selected: {_targeted},
                  onSelectionChanged: blocked
                      ? null
                      : (values) {
                          setState(() {
                            _targeted = values.first;
                            _studentId = null;
                          });
                          if (_targeted) _loadStudents();
                        },
                ),
                if (_targeted) ...[
                  const SizedBox(height: 12),
                  if (_loadingStudents)
                    const Center(child: CircularProgressIndicator()),
                  if (_studentError != null) ...[
                    Text(
                      _studentError!,
                      key: const Key('assignment-student-error'),
                    ),
                    TextButton(
                      onPressed: _loadStudents,
                      child: const Text('Retry students'),
                    ),
                  ],
                  if (!_loadingStudents &&
                      _studentError == null &&
                      _students.isEmpty &&
                      _className != null)
                    const Text(
                      'No students are enrolled in this class and section.',
                    ),
                  DropdownButtonFormField<dynamic>(
                    key: ValueKey(
                      'student-$_className-$_section-$_studentId-${_students.length}',
                    ),
                    initialValue: _studentId,
                    isExpanded: true,
                    decoration: _decoration('Select Student by ID / Name'),
                    items: _students
                        .map(
                          (student) => DropdownMenuItem<dynamic>(
                            value: student.id,
                            child: Text(
                              'ID: #${student.id} • ${student.name} (Roll: ${student.rollNo ?? 'N/A'})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _saving || _loadingStudents || _students.isEmpty
                        ? null
                        : (value) => setState(() => _studentId = value),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _subject,
                  decoration: _decoration('Subject'),
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  decoration: _decoration('Description'),
                  maxLines: 3,
                  enabled: !_saving,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _points,
                  decoration: _decoration('Points'),
                  keyboardType: TextInputType.number,
                  enabled: !_saving,
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _due,
                            firstDate: DateUtils.dateOnly(DateTime.now()),
                            lastDate: DateTime.now().add(
                              const Duration(days: 730),
                            ),
                          );
                          if (date != null && mounted)
                            setState(() => _due = date);
                        },
                  child: Text(
                    'Due date: ${_due.toIso8601String().split('T').first}',
                  ),
                ),
                TextField(
                  controller: _attachment,
                  decoration: _decoration(
                    'Resource / Attachment Link (Optional)',
                  ),
                  enabled: !_saving,
                ),
                if (_saveError != null)
                  Text(_saveError!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      blocked ||
                          (_targeted &&
                              (_loadingStudents ||
                                  _studentId == null ||
                                  _studentError != null))
                      ? null
                      : _publish,
                  child: Text(
                    _saving
                        ? 'Publishing...'
                        : _targeted
                        ? 'Assign to Student ID: #$_studentId'
                        : 'Publish to Class $_className',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
