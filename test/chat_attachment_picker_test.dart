import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:school_desk_app/services/chat_attachment_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ChatAttachmentPicker.channel, null);
  });
  for (final type in [FileType.image, FileType.video, FileType.any]) {
    test(
      'Android ${type.name} selection reads returned content bytes and filename',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(ChatAttachmentPicker.channel, (
              call,
            ) async {
              expect(call.method, 'pick');
              expect(
                call.arguments['kind'],
                type == FileType.image
                    ? 'image'
                    : type == FileType.video
                    ? 'video'
                    : 'any',
              );
              return {
                'name': 'selected.file',
                'bytes': Uint8List.fromList([1, 2, 3]),
                'mimeType': 'application/octet-stream',
              };
            });
        final result = await ChatAttachmentPicker.pick(type);
        expect(result!.name, 'selected.file');
        expect(result.bytes, [1, 2, 3]);
      },
    );
  }
  test('cancelled picker leaves existing draft untouched', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          ChatAttachmentPicker.channel,
          (_) async => null,
        );
    expect(await ChatAttachmentPicker.pick(FileType.any), isNull);
  });
  test('empty and oversized files report errors instead of submitting', () {
    expect(() => ChatAttachmentPicker.validate(0), throwsStateError);
    expect(
      () => ChatAttachmentPicker.validate(ChatAttachmentPicker.maxBytes + 1),
      throwsStateError,
    );
  });
}
