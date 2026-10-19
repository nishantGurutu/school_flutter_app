import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../data/network/network_api_services.dart';
import '../../utils/app_url.dart';

class AssignmentAttachmentPicker extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<bool>? onUploadingChanged;
  const AssignmentAttachmentPicker({super.key, required this.controller, this.onUploadingChanged});
  @override
  State<AssignmentAttachmentPicker> createState() => _AssignmentAttachmentPickerState();
}
class _AssignmentAttachmentPickerState extends State<AssignmentAttachmentPicker> {
  bool _uploading = false;
  String? _error;
  Future<void> _pick() async {
    final file = await FilePicker.pickFile();
    if (file == null || !mounted) return;
    widget.onUploadingChanged?.call(true);
    setState(() { _uploading = true; _error = null; });
    try {
      final length = await file.length();
      if (length == null || length == 0 || length > 20 * 1024 * 1024) throw Exception('Choose a nonempty file up to 20 MB.');
      final bytes = await file.readAsBytes();
      final form = FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: file.name)});
      final result = await NetworkApiService().postApi('${AppUrl.baseUrl}/files/upload', form);
      if (result is! Map || result['fileUrl'] == null) throw Exception('Upload response did not contain a file URL.');
      if (mounted) {
        widget.controller.text = Uri.parse(AppUrl.baseUrl).resolve(result['fileUrl'].toString()).toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${file.name} uploaded')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'File was not uploaded. Check the file size and connection, then retry.');
    } finally {
      if (mounted) { setState(() => _uploading = false); widget.onUploadingChanged?.call(false); }
    }
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    TextButton.icon(onPressed: _uploading ? null : _pick, icon: _uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.attach_file), label: Text(_uploading ? 'Uploading attachment…' : 'Choose & upload file')),
    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
  ]);
}
