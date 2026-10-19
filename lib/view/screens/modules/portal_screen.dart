import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/network/network_api_services.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../data/models/user_model.dart';
import '../../../utils/app_url.dart';

/// All content comes from the authenticated portal API, scoped to a linked child.
class PortalScreen extends StatefulWidget {
  final String module;
  const PortalScreen({super.key, required this.module});
  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  final _api = NetworkApiService();
  Map<String, dynamic>? _context;
  String? _admission, _error;
  dynamic _data;
  bool _loading = true;
  int _request = 0;
  bool get _manager => _context?['manager'] == true;
  List get _children => _context?['children'] as List? ?? [];
  List get _classes => _context?['classes'] as List? ?? [];
  String get _title => switch (widget.module) {
    'diary' => 'Student diary',
    'certificates' => 'Certificates',
    'report' => 'Report card',
    'notifications' => 'Notifications',
    _ => 'Online exams',
  };
  String get _root => '${AppUrl.baseUrl}/mobile';
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final data = Map<String, dynamic>.from(
        await _api.getApi('$_root/portal/context'),
      );
      if (!mounted) return;
      _context = data;
      if (_children.length == 1) {
        _admission = _children.first['admissionNo'].toString();
      }
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _load() async {
    final generation = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });
    if (widget.module != 'notifications' && !_manager && _admission == null) {
      setState(() => _loading = false);
      return;
    }
    if (_manager &&
        ['certificates', 'report'].contains(widget.module) &&
        _admission == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final path = widget.module == 'onlineExams'
          ? 'online-exams'
          : 'portal/${widget.module}';
      final query = _admission == null
          ? ''
          : '?admissionNo=${Uri.encodeQueryComponent(_admission!)}';
      final data = await _api.getApi('$_root/$path$query');
      if (mounted && generation == _request) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && generation == _request) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _message(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _create() async {
    if (widget.module == 'onlineExams') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OnlineExamEditor(classes: _classes)),
      );
      if (mounted) await _load();
      return;
    }
    final title = TextEditingController(),
        body = TextEditingController(),
        admission = TextEditingController(text: _admission);
    Map? selectedClass = _classes.isEmpty ? null : _classes.first;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(
            widget.module == 'diary'
                ? 'Publish diary entry'
                : 'Issue certificate',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.module == 'diary')
                  DropdownButtonFormField<Map>(
                    initialValue: selectedClass,
                    isExpanded: true,
                    items: _classes
                        .map(
                          (c) => DropdownMenuItem<Map>(
                            value: c,
                            child: Text('${c['name']} ${c['section'] ?? ''}'),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (c) => update(() => selectedClass = c),
                    decoration: const InputDecoration(
                      labelText: 'Class / section',
                    ),
                  ),
                if (widget.module == 'certificates')
                  TextField(
                    controller: admission,
                    decoration: const InputDecoration(
                      labelText: 'Student admission number',
                    ),
                  ),
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: widget.module == 'diary'
                        ? 'Title'
                        : 'Certificate title',
                  ),
                ),
                if (widget.module == 'diary')
                  TextField(
                    controller: body,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Diary entry'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (title.text.trim().isEmpty ||
                          (widget.module == 'diary' &&
                              (body.text.trim().isEmpty ||
                                  selectedClass == null)) ||
                          (widget.module == 'certificates' &&
                              admission.text.trim().isEmpty)) {
                        _message('Complete the required fields');
                        return;
                      }
                      update(() => saving = true);
                      try {
                        await _api.postApi(
                          '$_root/portal/${widget.module}',
                          widget.module == 'diary'
                              ? {
                                  'title': title.text.trim(),
                                  'content': body.text.trim(),
                                  'className': selectedClass!['name'],
                                  'section': selectedClass!['section'],
                                }
                              : {
                                  'certificateName': title.text.trim(),
                                  'admissionNo': admission.text.trim(),
                                },
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          _admission = admission.text.trim().isEmpty
                              ? _admission
                              : admission.text.trim();
                          await _load();
                        }
                      } catch (e) {
                        _message(e);
                        if (ctx.mounted) update(() => saving = false);
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    body.dispose();
    admission.dispose();
  }

  Future<void> _openExam(Map row) async {
    try {
      if (_manager) {
        final results = await _api.getApi(
          '$_root/online-exams/${row['id']}/results',
        ) as List;
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('${row['title']} results'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (results.isEmpty) const Text('No attempts yet.'),
                    ...results.map(
                      (r) => ListTile(
                        title: Text('Student ${r['studentId']}'),
                        subtitle: Text(
                          r['submittedAt'] == null
                              ? 'In progress'
                              : '${r['score']} / ${r['maximum']}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else if (context.read<AuthBloc>().state.user?.role ==
          UserRole.student) {
        final attempt = Map<String, dynamic>.from(
          await _api.postApi('$_root/online-exams/${row['id']}/start', {}),
        );
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineAttemptScreen(
              attempt: attempt,
              title: row['title'].toString(),
            ),
          ),
        );
        if (mounted) await _load();
      }
    } catch (e) {
      _message(e);
    }
  }

  Widget _row(Map row) {
    if (widget.module == 'onlineExams') {
      final attempt = row['attempt'] as Map?;
      return Card(
        child: ListTile(
          title: Text(row['title'].toString()),
          subtitle: Text(
            '${row['subject']} • ${row['durationMinutes']} min\n${row['opensAt']} — ${row['closesAt']}\n${attempt == null
                ? 'No attempt'
                : attempt['submittedAt'] == null
                ? 'In progress'
                : 'Score: ${attempt['score']} / ${attempt['maximum']}'}',
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openExam(row),
        ),
      );
    }
    if (widget.module == 'certificates') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.workspace_premium, size: 48),
              Text(
                row['certificateName']?.toString() ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SelectableText(
                '${row['name']}\nAdmission: ${row['admissionNo']}\nClass: ${row['className']}\n${row['date'] ?? ''}',
              ),
              const SizedBox(height: 16),
              Text('${row['footerLeft'] ?? ''}    ${row['footerRight'] ?? ''}'),
            ],
          ),
        ),
      );
    }
    final unread = widget.module == 'notifications' && row['readAt'] == null;
    return Card(
      child: ListTile(
        leading: unread ? const Icon(Icons.mark_email_unread) : null,
        title: Text(row['title']?.toString() ?? ''),
        subtitle: Text(
          '${row['content'] ?? row['body'] ?? ''}\n${row['postedAt'] ?? row['createdAt'] ?? ''}',
        ),
        onTap: widget.module == 'notifications'
            ? () async {
                try {
                  await _api.postApi(
                    '$_root/portal/notifications/${row['id']}/read',
                    {},
                  );
                  if (mounted) await _load();
                } catch (e) {
                  _message(e);
                }
              }
            : null,
        trailing: widget.module == 'diary' && _manager
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete diary entry?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  try {
                    await _api.deleteApi('$_root/portal/diary/${row['id']}');
                    if (mounted) await _load();
                  } catch (e) {
                    _message(e);
                  }
                },
              )
            : row['fileUrl'] != null
            ? IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: () async {
                  final uri = Uri.tryParse(row['fileUrl'].toString());
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _report(Map report) {
    final student = report['student'] as Map,
        attendance = report['attendance'] as Map;
    final results = report['results'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          student['name'].toString(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SelectableText(
          'Admission: ${student['admissionNo']} • ${student['className']} ${student['section']}',
        ),
        const SizedBox(height: 16),
        Text(
          'Attendance: ${attendance['present']} / ${attendance['total']} (${(attendance['percentage'] as num).toStringAsFixed(1)}%)',
        ),
        const Divider(),
        if (results.isEmpty) const Text('No published results.'),
        ...results.map(
          (r) => ListTile(
            title: Text(
              '${r['exam'] ?? r['examName'] ?? r['subject'] ?? 'Exam'}',
            ),
            subtitle: Text('${r['subject'] ?? ''}'),
            trailing: Text(
              '${r['total'] ?? r['marksObtained'] ?? r['marks'] ?? r['score'] ?? ''} / ${r['maxMarks'] ?? r['totalMarks'] ?? ''}',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_title),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton:
        _manager &&
            ['diary', 'certificates', 'onlineExams'].contains(widget.module)
        ? FloatingActionButton(onPressed: _create, child: const Icon(Icons.add))
        : null,
    body: Column(
      children: [
        if (_children.length > 1 && widget.module != 'notifications')
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _admission,
              decoration: const InputDecoration(labelText: 'Select child'),
              items: _children
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c['admissionNo'].toString(),
                      child: Text(c['name'].toString()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                _admission = v;
                _load();
              },
            ),
          ),
        if (_manager && ['certificates', 'report'].contains(widget.module))
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Student admission number',
                suffixIcon: Icon(Icons.search),
              ),
              onSubmitted: (v) {
                _admission = v.trim();
                _load();
              },
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: _context == null ? _initialize : _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _data == null
              ? const Center(child: Text('Select a student to continue.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: widget.module == 'report'
                        ? [_report(_data as Map)]
                        : (_data as List).isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No records yet.'),
                            ),
                          ]
                        : (_data as List).map((r) => _row(r as Map)).toList(),
                  ),
                ),
        ),
      ],
    ),
  );
}

class OnlineExamEditor extends StatefulWidget {
  final List classes;
  const OnlineExamEditor({super.key, required this.classes});
  @override
  State<OnlineExamEditor> createState() => _OnlineExamEditorState();
}

class _OnlineExamEditorState extends State<OnlineExamEditor> {
  final _title = TextEditingController(),
      _subject = TextEditingController(),
      _duration = TextEditingController(text: '30');
  final List<Map<String, dynamic>> _questions = [];
  Map? _class;
  DateTime _opens = DateTime.now(),
      _closes = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    if (widget.classes.isNotEmpty) _class = widget.classes.first;
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _date(bool opens) async {
    final date = await showDatePicker(
      context: context,
      initialDate: opens ? _opens : _closes,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(opens ? _opens : _closes),
    );
    if (time != null && mounted) {
      setState(() {
        final value = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        if (opens) {
          _opens = value;
        } else {
          _closes = value;
        }
      });
    }
  }

  Future<void> _question() async {
    final prompt = TextEditingController(),
        marks = TextEditingController(text: '1');
    final options = List.generate(4, (_) => TextEditingController());
    int correct = 0;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Add question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: prompt,
                  decoration: const InputDecoration(labelText: 'Question'),
                ),
                ...options.asMap().entries.map(
                  (e) => TextField(
                    controller: e.value,
                    decoration: InputDecoration(
                      labelText: 'Option ${e.key + 1}',
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: correct,
                  items: List.generate(
                    4,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Correct: option ${i + 1}'),
                    ),
                  ),
                  onChanged: (i) => update(() => correct = i!),
                ),
                TextField(
                  controller: marks,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Marks'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (prompt.text.trim().isEmpty ||
                    options.any((c) => c.text.trim().isEmpty) ||
                    (int.tryParse(marks.text) ?? 0) < 1) {
                  return;
                }
                setState(
                  () => _questions.add({
                    'prompt': prompt.text.trim(),
                    'options': options.map((c) => c.text.trim()).toList(),
                    'correctIndex': correct,
                    'marks': int.parse(marks.text),
                  }),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    prompt.dispose();
    marks.dispose();
    for (final c in options) {
      c.dispose();
    }
  }

  Future<void> _save() async {
    if (_class == null ||
        _title.text.trim().isEmpty ||
        _subject.text.trim().isEmpty ||
        _questions.isEmpty ||
        (int.tryParse(_duration.text) ?? 0) < 1 ||
        !_closes.isAfter(_opens)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete exam details and add questions.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await NetworkApiService().postApi(
        '${AppUrl.baseUrl}/mobile/online-exams',
        {
          'title': _title.text.trim(),
          'subject': _subject.text.trim(),
          'className': _class!['name'],
          'section': _class!['section'],
          'durationMinutes': int.parse(_duration.text),
          'opensAt': _opens.toUtc().toIso8601String(),
          'closesAt': _closes.toUtc().toIso8601String(),
          'published': true,
          'questions': _questions,
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create online exam')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<Map>(
          initialValue: _class,
          items: widget.classes
              .map(
                (c) => DropdownMenuItem<Map>(
                  value: c,
                  child: Text('${c['name']} ${c['section'] ?? ''}'),
                ),
              )
              .toList(),
          onChanged: (c) => setState(() => _class = c),
          decoration: const InputDecoration(labelText: 'Class / section'),
        ),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Exam title'),
        ),
        TextField(
          controller: _subject,
          decoration: const InputDecoration(labelText: 'Subject'),
        ),
        TextField(
          controller: _duration,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Duration (minutes)'),
        ),
        ListTile(
          title: const Text('Available from'),
          subtitle: Text(_opens.toString()),
          onTap: () => _date(true),
        ),
        ListTile(
          title: const Text('Closes at'),
          subtitle: Text(_closes.toString()),
          onTap: () => _date(false),
        ),
        ..._questions.asMap().entries.map(
          (e) => ListTile(
            title: Text('${e.key + 1}. ${e.value['prompt']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _questions.removeAt(e.key)),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: _saving ? null : _question,
          child: const Text('Add question'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Publishing…' : 'Publish exam'),
        ),
      ],
    ),
  );
}

class OnlineAttemptScreen extends StatefulWidget {
  final Map<String, dynamic> attempt;
  final String title;
  const OnlineAttemptScreen({
    super.key,
    required this.attempt,
    required this.title,
  });
  @override
  State<OnlineAttemptScreen> createState() => _OnlineAttemptScreenState();
}

class _OnlineAttemptScreenState extends State<OnlineAttemptScreen> {
  late Map<String, dynamic> _attempt;
  final _api = NetworkApiService();
  Timer? _timer;
  late Duration _offset;
  Duration _remaining = Duration.zero;
  bool _busy = false;
  String? _error;
  String get _url =>
      '${AppUrl.baseUrl}/mobile/online-exams/attempts/${_attempt['id']}';
  @override
  void initState() {
    super.initState();
    _attempt = Map.from(widget.attempt);
    _offset = DateTime.parse(_attempt['serverTime']).difference(DateTime.now());
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final remaining = DateTime.parse(_attempt['deadline'])
        .difference(DateTime.now().add(_offset));
    setState(
      () => _remaining = remaining.isNegative ? Duration.zero : remaining,
    );
    if (_remaining == Duration.zero &&
        !_busy &&
        _attempt['submittedAt'] == null) {
      _submit(false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _answer(int index, int value) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = Map<String, dynamic>.from(
        await _api.postApi('$_url/answers', {
          'answers': {'$index': value},
        }),
      );
      if (mounted) setState(() => _attempt = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = 'Answer was not saved. Retry your selection. $e',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit(bool confirm) async {
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submit exam?'),
          content: const Text(
            'You cannot change your answers after submitting.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continue exam'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final result = Map<String, dynamic>.from(
        await _api.postApi('$_url/submit', {}),
      );
      if (mounted) setState(() => _attempt = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      _timer?.cancel();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _attempt['submittedAt'] != null;
    final questions = _attempt['questions'] as List? ?? [];
    final answers = _attempt['answers'] as Map? ?? {};
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              submitted
                  ? 'Submitted'
                  : '${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          if (submitted)
            Text(
              'Score: ${_attempt['score']} / ${_attempt['maximum']}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ...questions.asMap().entries.map((entry) {
            final q = entry.value as Map;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}. ${q['prompt']} (${q['marks']} marks)',
                    ),
                    ...(q['options'] as List).asMap().entries.map(
                      (o) => ListTile(
                        leading: Icon(
                          answers['${entry.key}'] == o.key
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        title: Text(o.value.toString()),
                        onTap: _busy || _remaining == Duration.zero
                            ? null
                            : () => _answer(entry.key, o.key),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (!submitted)
            FilledButton(
              onPressed: _busy ? null : () => _submit(true),
              child: Text(_busy ? 'Saving…' : 'Submit exam'),
            ),
        ],
      ),
    );
  }
}
