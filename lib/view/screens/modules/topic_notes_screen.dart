import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/curriculum_model.dart';
import '../../../data/repositories/api_school_repository.dart';
import '../../../utils/app_url.dart';

Uri? resolveNoteUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null) return null;
  final resolved = Uri.parse(AppUrl.baseUrl).resolveUri(uri);
  return ['http', 'https'].contains(resolved.scheme) && resolved.host.isNotEmpty ? resolved : null;
}

Future<void> openNoteAttachment(BuildContext context, String? url, {bool download = false}) async {
  final uri = resolveNoteUrl(url);
  try {
    if (uri == null) throw StateError('Attachment unavailable');
    final target = download ? uri.replace(queryParameters: {...uri.queryParameters, 'attachment': 'true'}) : uri;
    if (!await launchUrl(target, mode: LaunchMode.externalApplication)) throw StateError('Unable to open attachment');
  } catch (_) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open attachment. Check your connection and try again.')));
  }
}

class TopicNotesScreen extends StatefulWidget {
  final ApiSchoolRepository? repository;
  final String? topicId, topicTitle, chapterId, chapterTitle, chapterNumber;
  final String subjectName;
  final List<StudyNoteModel>? preloadedNotes;
  const TopicNotesScreen({super.key, this.repository, this.topicId, this.topicTitle, this.chapterId, this.chapterTitle, this.chapterNumber, required this.subjectName, this.preloadedNotes});
  @override
  State<TopicNotesScreen> createState() => _TopicNotesScreenState();
}

class _TopicNotesScreenState extends State<TopicNotesScreen> {
  late final ApiSchoolRepository _repository;
  TopicNotesResponseModel? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _repository = widget.repository ?? ApiSchoolRepository(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final TopicNotesResponseModel? data;
      // Topic ID takes priority: chapter metadata must never load unrelated chapter notes.
      if (widget.topicId?.isNotEmpty == true) {
        data = await _repository.getTopicNotes(widget.topicId!);
      } else if (widget.chapterId?.isNotEmpty == true) {
        data = await _repository.getChapterNotes(widget.chapterId!);
      } else {
        throw StateError('Topic is missing');
      }
      if (data == null) throw StateError('Empty response');
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Unable to load notes. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _data?.topicTitle ?? widget.topicTitle ?? widget.chapterTitle ?? 'Notes';
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [IconButton(tooltip: 'Refresh notes', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), TextButton(onPressed: _load, child: const Text('Retry'))]))
        : RefreshIndicator(onRefresh: _load, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16),
          children: [
            Text([_data?.subjectName.isNotEmpty == true ? _data!.subjectName : widget.subjectName, _data?.chapterTitle ?? widget.chapterTitle ?? ''].where((s) => s.isNotEmpty).join(' / '), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (_data?.topicDescription?.isNotEmpty == true) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_data!.topicDescription!)),
            const SizedBox(height: 16),
            Text('Study notes (${_data?.notes.length ?? 0})', style: Theme.of(context).textTheme.titleMedium),
            if (_data?.notes.isEmpty != false) const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Column(children: [Icon(Icons.menu_book_outlined, size: 48), SizedBox(height: 12), Text('No notes published for this topic yet.')]))
            else ..._data!.notes.map((note) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(note.title, style: Theme.of(context).textTheme.titleMedium),
              if (note.description?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 8), child: Text(note.description!)),
              const SizedBox(height: 8),
              Text('By ${note.teacherName} • ${note.uploadedDate}'),
              if (note.fileName?.isNotEmpty == true) Text('${note.fileName} • ${note.fileSizeFormatted}'),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (note.isPreviewable) FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InAppNoteReaderScreen(note: note, topicTitle: title, subjectName: widget.subjectName))), icon: const Icon(Icons.menu_book), label: const Text('Read notes')),
                if (note.isDownloadable && resolveNoteUrl(note.fileUrl) != null) OutlinedButton.icon(onPressed: () => openNoteAttachment(context, note.fileUrl, download: true), icon: const Icon(Icons.download), label: const Text('Download attachment')),
              ]),
            ]))))
          ],
        )),
    );
  }
}

class InAppNoteReaderScreen extends StatefulWidget {
  final StudyNoteModel note;
  final String topicTitle, subjectName;
  const InAppNoteReaderScreen({super.key, required this.note, required this.topicTitle, required this.subjectName});
  @override
  State<InAppNoteReaderScreen> createState() => _InAppNoteReaderScreenState();
}

class _InAppNoteReaderScreenState extends State<InAppNoteReaderScreen> {
  bool _dark = false;
  double _fontSize = 16;
  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final foreground = _dark ? Colors.white : Colors.black87;
    final attachment = resolveNoteUrl(note.fileUrl);
    final image = note.fileType.toUpperCase() == 'IMAGE' || RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(attachment?.path ?? '');
    return Scaffold(
      backgroundColor: _dark ? const Color(0xff152033) : Colors.white,
      appBar: AppBar(title: Text(note.title), actions: [
        IconButton(tooltip: 'Reading theme', onPressed: () => setState(() => _dark = !_dark), icon: const Icon(Icons.contrast)),
        IconButton(tooltip: 'Text size', onPressed: () => setState(() => _fontSize = _fontSize >= 24 ? 14 : _fontSize + 2), icon: const Icon(Icons.text_fields)),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${widget.subjectName} / ${widget.topicTitle}', style: TextStyle(color: foreground)),
        const SizedBox(height: 12),
        SelectableText(note.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: foreground)),
        if (note.description?.isNotEmpty == true) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: SelectableText(note.description!, style: TextStyle(color: foreground, fontSize: _fontSize))),
        if (note.contentHtml?.trim().isNotEmpty == true) Html(data: note.contentHtml!, style: {'body': Style(color: foreground, fontSize: FontSize(_fontSize))}, onLinkTap: (url, _, _) => openNoteAttachment(context, url)),
        if (image && attachment != null) Image.network(attachment.toString(), errorBuilder: (_, _, _) => Text('Image could not load. Use Open attachment to retry.', style: TextStyle(color: foreground))),
        if (attachment != null) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: FilledButton.icon(onPressed: () => openNoteAttachment(context, note.fileUrl), icon: const Icon(Icons.open_in_new), label: Text('Open ${note.fileName ?? 'attachment'}'))),
        if (note.contentHtml?.trim().isNotEmpty != true && note.description?.trim().isNotEmpty != true && attachment == null) Text('This note has no content or attachment yet.', style: TextStyle(color: foreground)),
      ])),
    );
  }
}

