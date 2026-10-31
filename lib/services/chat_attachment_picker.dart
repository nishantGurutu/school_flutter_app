import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class ChatPickedAttachment {
  final String name;
  final Uint8List bytes;
  final String mimeType;
  const ChatPickedAttachment({
    required this.name,
    required this.bytes,
    this.mimeType = 'application/octet-stream',
  });
}

class ChatAttachmentPicker {
  static const maxBytes = 25 * 1024 * 1024;
  static const channel = MethodChannel('school_desk/chat_attachments');
  static Future<ChatPickedAttachment?> pick(FileType type) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final Map<dynamic, dynamic>? data;
      try {
        data = await channel.invokeMapMethod('pick', {
          'kind': type == FileType.image
              ? 'image'
              : type == FileType.video
              ? 'video'
              : 'any',
        });
      } on MissingPluginException {
        throw StateError(
          'Install the updated full APK and reopen the app to enable attachment selection.',
        );
      } on PlatformException catch (e) {
        throw StateError(e.message ?? 'Unable to select a file. Please retry.');
      }
      if (data == null) return null;
      final bytes = data['bytes'] as Uint8List;
      validate(bytes.length);
      return ChatPickedAttachment(
        name: data['name'] as String,
        bytes: bytes,
        mimeType: data['mimeType'] as String? ?? 'application/octet-stream',
      );
    }
    final file = await FilePicker.pickFile(type: type);
    if (file == null) return null;
    final size = await file.length();
    if (size != null && size > maxBytes) {
      throw StateError('Choose a file up to 25 MB.');
    }
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in file.readAsByteStream()) {
      if (buffer.length + chunk.length > maxBytes) {
        throw StateError('Choose a file up to 25 MB.');
      }
      buffer.add(chunk);
    }
    final bytes = buffer.takeBytes();
    validate(bytes.length);
    return ChatPickedAttachment(name: file.name, bytes: bytes);
  }

  static void validate(int length) {
    if (length == 0) throw StateError('The selected file is empty.');
    if (length > maxBytes) throw StateError('Choose a file up to 25 MB.');
  }
}
