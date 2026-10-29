import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/services/school_chat_service.dart';
import 'package:school_desk_app/view/screens/modules/school_chat_screen.dart';

class FakeChat extends SchoolChatService {
  String? sent;
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
}
