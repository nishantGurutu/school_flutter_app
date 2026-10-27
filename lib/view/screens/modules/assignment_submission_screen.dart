import 'package:flutter/material.dart';
import '../../../data/models/school_models.dart';
import '../../../data/repositories/api_school_repository.dart';
import 'topic_notes_screen.dart' show openNoteAttachment;

class AssignmentSubmissionScreen extends StatefulWidget {
  final HomeworkItem assignment;
  final ApiSchoolRepository repository;
  final bool readOnly;
  const AssignmentSubmissionScreen({
    super.key,
    required this.assignment,
    required this.repository,
    this.readOnly = false,
  });
  @override
  State<AssignmentSubmissionScreen> createState() =>
      _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState
    extends State<AssignmentSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _answer = TextEditingController(
    text: widget.assignment.submissionText,
  );
  late final TextEditingController _link = TextEditingController(
    text: widget.assignment.submissionFileUrl,
  );
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _answer.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || widget.readOnly || !_formKey.currentState!.validate()) {
      return;
    }
    if (_answer.text.trim().isEmpty && _link.text.trim().isEmpty) {
      setState(() => _error = 'Write your answer or add an attachment link.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.submitStudentAssignmentWork(
        assignmentId: widget.assignment.id,
        submissionText: _answer.text.trim(),
        fileUrl: _link.text.trim(),
      );
      if (!saved) throw StateError('Submission failed. Please try again.');
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Unable to submit work. $error';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.assignment;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.readOnly ? 'Your Submission' : 'Submit Task'),
          automaticallyImplyLeading: !_saving,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${task.subject} • ${task.className}${task.section == null ? '' : ' / ${task.section}'}',
                    ),
                    if (task.assignedBy?.isNotEmpty == true)
                      Text('Assigned by ${task.assignedBy}'),
                    Text(
                      'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                    ),
                    if (task.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(task.description),
                      ),
                    if (task.fileAttachmentUrl?.isNotEmpty == true)
                      TextButton.icon(
                        onPressed: () =>
                            openNoteAttachment(context, task.fileAttachmentUrl),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Open task attachment'),
                      ),
                    if (task.teacherFeedback?.isNotEmpty == true)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Teacher feedback: ${task.teacherFeedback}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _answer,
                      readOnly: widget.readOnly || _saving,
                      minLines: 5,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        labelText: 'Your answer / completed work',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _link,
                      readOnly: widget.readOnly || _saving,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Attachment link (optional)',
                        hintText: 'https://drive.google.com/...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final uri = Uri.tryParse(value.trim());
                        return uri != null &&
                                ['https', 'http'].contains(uri.scheme) &&
                                uri.host.isNotEmpty
                            ? null
                            : 'Enter a valid https:// or http:// link.';
                      },
                    ),
                    if (!widget.readOnly)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'You can submit an answer, a shareable PDF/photo/document link, or both. Make sure your teacher can open the link.',
                        ),
                      ),
                    if (widget.readOnly && task.submittedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Submitted: ${task.submittedAt}'),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!widget.readOnly)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _saving
                              ? 'Submitting...'
                              : task.status == HomeworkStatus.rejected
                              ? 'Resubmit Work'
                              : 'Submit Work',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
