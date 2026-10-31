import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:school_desk_app/services/chat_attachment_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/services/school_chat_service.dart';
import 'package:school_desk_app/view/screens/modules/school_chat_screen.dart';

class FakeChat extends SchoolChatService {
  FakeChat({super.socketSend});
  String? sent;
  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  @override
  Future<void> start() async {
    contacts = [
      {'id': 2, 'name': 'Parent One', 'role': 'PARENT'},
    ];
    rooms = [
      {
        'id': 'room',
        'name': 'Class teacher',
        'lastMessage': 'Welcome',
        'groupChat': false,
        'unreadCount': 1,
        'members': [
          {'id': 1, 'readThrough': 1, 'deliveredThrough': 1},
          {'id': 2, 'readThrough': 1, 'deliveredThrough': 1},
        ],
      },
    ];
    changed();
  }

  @override
  Future<void> select(String? id) async {
    selectedRoom = id;
    messages = [];
    changed();
  }

  @override
  Future<void> sync() async {}
  @override
  Future<void> send(
    String text,
    String clientId,
    String? attachmentId, {
    Map<String, dynamic>? attachment,
  }) async {
    sent = text;
    messages = [
      {
        'id': 1,
        'senderId': 1,
        'senderName': 'Teacher',
        'text': text,
        'sentAt': '2026-10-29T10:00:00Z',
      },
    ];
    changed();
  }
}

class PendingChat extends SchoolChatService {
  PendingChat() : super(socketSend: (_, _) {}) {
    connected = true;
  }
  @override
  Future<void> start() async {
    rooms = [
      {
        'id': 'pending-room',
        'name': 'Instant chat',
        'lastMessage': '',
        'groupChat': false,
        'unreadCount': 0,
        'members': [
          {'id': 1, 'readThrough': 0, 'deliveredThrough': 0},
          {'id': 2, 'readThrough': 0, 'deliveredThrough': 0},
        ],
      },
    ];
    changed();
  }

  @override
  Future<void> select(String? id) async {
    selectedRoom = id;
    changed();
  }

  @override
  Future<void> sync() async {}
}

class HistoryChat extends FakeChat {
  final int count;
  HistoryChat(this.count);
  @override
  Future<void> select(String? id) async {
    selectedRoom = id;
    messages = List.generate(
      count,
      (i) => {
        'id': i + 1,
        'clientId': 'history-$i',
        'senderId': 2,
        'senderName': 'Parent',
        'text': 'History $i',
        'sentAt': '2026-10-30T10:00:00Z',
      },
    );
    changed();
  }
}

class AttachmentChat extends FakeChat {
  AttachmentChat() : super(socketSend: (_, _) {}) {
    connected = true;
  }
  Completer<Map<String, dynamic>>? uploadResult;
  int uploads = 0;
  bool rejectUpload = false;
  String? sentAttachment;
  @override
  Future<Map<String, dynamic>> upload(
    String name,
    List<int> bytes, {
    String? roomId,
    ValueChanged<double>? onProgress,
  }) async {
    uploads++;
    if (uploadResult != null) return uploadResult!.future;
    expect(roomId, 'room');
    expect(bytes, isNotEmpty);
    onProgress?.call(0.5);
    if (rejectUpload) throw StateError('Upload unavailable; retry');
    return {
      'id': 'uploaded-file',
      'name': name,
      'type': 'text/plain',
      'size': bytes.length,
    };
  }

  @override
  Future<void> send(
    String text,
    String clientId,
    String? attachmentId, {
    Map<String, dynamic>? attachment,
  }) async {
    sentAttachment = attachmentId;
    await super.send(text, clientId, attachmentId, attachment: attachment);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'accessToken': 'test',
      'userId': '1',
      'role': 'TEACHER',
      'name': 'Teacher',
      'email': 'teacher@test.local',
    }),
  );
  testWidgets('leaving and reopening chat preserves the session service', (
    tester,
  ) async {
    final chat = FakeChat();
    await tester.pumpWidget(MaterialApp(home: SchoolChatScreen(service: chat)));
    await tester.pumpAndSettle();
    expect(chat.visible, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(chat.disposed, isFalse);
    expect(chat.visible, isFalse);
    await tester.pumpWidget(MaterialApp(home: SchoolChatScreen(service: chat)));
    await tester.pumpAndSettle();
    expect(find.text('Class teacher'), findsOneWidget);
    expect(chat.visible, isTrue);
    await tester.pumpWidget(const SizedBox());
    chat.dispose();
  });

  testWidgets(
    'chat list opens conversation and sends a real draft with visible receipt',
    (tester) async {
      final chat = FakeChat();
      await tester.pumpWidget(
        MaterialApp(home: SchoolChatScreen(service: chat)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Class teacher'), findsOneWidget);
      await tester.tap(find.text('Class teacher'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Hello parent');
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(chat.sent, 'Hello parent');
      expect(find.text('Hello parent'), findsOneWidget);
      expect(find.byTooltip('Read'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'group creation button enables after contacts and group name are entered',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SchoolChatScreen(service: FakeChat())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('New conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Group conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Parent One'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Grade 7 parents',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'emoji picker inserts emoji into bottom composer on phone layout',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final chat = FakeChat();
      await tester.pumpWidget(
        MaterialApp(home: SchoolChatScreen(service: chat)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class teacher'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Emoji'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😀'));
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '😀');
      expect(find.byTooltip('Attach photo, video or file'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'slow ACK never blocks composer: two messages display before confirmation',
    (tester) async {
      final chat = PendingChat();
      await tester.pumpWidget(
        MaterialApp(home: SchoolChatScreen(service: chat)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Instant chat'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'First instant message');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(find.text('First instant message'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Send',
              ),
            )
            .onPressed,
        isNotNull,
      );
      await tester.enterText(find.byType(TextField), 'Second instant message');
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      expect(find.text('Second instant message'), findsOneWidget);
      expect(chat.messages.length, 2);
      expect(chat.status(chat.messages.first), 'Sending');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'short conversation starts at bottom in chronological order above composer',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: SchoolChatScreen(service: HistoryChat(2))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class teacher'));
      await tester.pumpAndSettle();
      final first = tester.getRect(find.text('History 0')),
          latest = tester.getRect(find.text('History 1')),
          composer = tester.getRect(find.byType(TextField));
      expect(first.top, lessThan(latest.top));
      expect(latest.bottom, greaterThan(600));
      expect(composer.top - latest.bottom, lessThan(90));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'long conversation opens at latest and incoming message does not force older reader down',
    (tester) async {
      final chat = HistoryChat(70);
      await tester.pumpWidget(
        MaterialApp(home: SchoolChatScreen(service: chat)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class teacher'));
      await tester.pumpAndSettle();
      expect(find.text('History 69'), findsOneWidget);
      expect(find.text('History 0'), findsNothing);
      final list = find.byType(ListView);
      await tester.drag(list, const Offset(0, 500));
      await tester.pumpAndSettle();
      final controller = tester.widget<ListView>(list).controller!;
      expect(controller.offset, greaterThan(180));
      chat.messages.add({
        'id': 71,
        'senderId': 2,
        'senderName': 'Parent',
        'text': 'New while reading',
        'sentAt': '2026-10-30T10:01:00Z',
      });
      chat.changed();
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(180));
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'selected file previews before upload then submits attachment-only message',
    (tester) async {
      final chat = AttachmentChat();
      FileType? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: SchoolChatScreen(
            service: chat,
            attachmentPicker: (type) async {
              chosen = type;
              return ChatPickedAttachment(
                name: 'homework.txt',
                bytes: Uint8List.fromList([65, 66]),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class teacher'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Attach photo, video or file'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Document / file'));
      await tester.pumpAndSettle();
      expect(chosen, FileType.any);
      expect(find.text('homework.txt'), findsOneWidget);
      expect(chat.uploads, 0);
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(chat.uploads, 1);
      expect(chat.messages.single['attachmentId'], 'uploaded-file');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'failed upload retains media in bubble and retries without blocking composer',
    (tester) async {
      final chat = AttachmentChat()..rejectUpload = true;
      await tester.pumpWidget(
        MaterialApp(
          home: SchoolChatScreen(
            service: chat,
            attachmentPicker: (_) async => ChatPickedAttachment(
              name: 'retry.txt',
              bytes: Uint8List.fromList([65]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Class teacher'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Keep my caption');
      await tester.tap(find.byTooltip('Attach photo, video or file'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Send'));
      await tester.pumpAndSettle();
      expect(find.text('retry.txt'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Keep my caption'), findsOneWidget);
      expect(find.text('Retry send'), findsOneWidget);
      expect(chat.sentAttachment, isNull);
      chat.rejectUpload = false;
      await tester.tap(find.text('Retry send'));
      await tester.pumpAndSettle();
      expect(chat.messages.single['attachmentId'], 'uploaded-file');
      expect(chat.uploads, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('media upload displays immediately and composer stays usable', (
    tester,
  ) async {
    final chat = AttachmentChat()
      ..uploadResult = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(
      MaterialApp(
        home: SchoolChatScreen(
          service: chat,
          attachmentPicker: (_) async => ChatPickedAttachment(
            name: 'document.pdf',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class teacher'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Attach photo, video or file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Document / file'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'PDF caption');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    expect(find.text('document.pdf'), findsOneWidget);
    expect(find.text('PDF caption'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Send',
            ),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      find.descendant(
        of: find.byTooltip('Send'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    chat.connected = false;
    chat.uploadResult!.complete({
      'id': 'uploaded',
      'name': 'document.pdf',
      'type': 'application/pdf',
      'size': 3,
    });
    await tester.pump();
    expect(chat.messages.single['localState'], 'queued');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
