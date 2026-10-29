import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_desk_app/services/school_chat_service.dart';
import 'package:school_desk_app/data/network/network_api_services.dart';

class ChatApi extends NetworkApiService {
  final reads = <int>[];
  final writes = <Map<String, dynamic>>[];
  final first = List.generate(
    100,
    (i) => {'id': i + 1, 'senderId': 2, 'text': 'message $i'},
  );
  @override
  Future<dynamic> getApi(String url) async {
    if (url.endsWith('/contacts')) return <Map<String, dynamic>>[];
    if (url.endsWith('/rooms')) {
      return [
        {
          'id': 'room',
          'name': 'Class',
          'members': [
            {'id': 1, 'readThrough': 101, 'deliveredThrough': 101},
            {'id': 2, 'readThrough': 100, 'deliveredThrough': 101},
          ],
        },
      ];
    }
    final after = int.parse(Uri.parse(url).queryParameters['after']!);
    reads.add(after);
    if (after == 0) return {'messages': first, 'hasMore': true};
    if (after == 100) {
      return {
        'messages': [
          {'id': 101, 'senderId': 2, 'text': 'last'},
        ],
        'hasMore': false,
      };
    }
    return {'messages': [], 'hasMore': false};
  }

  @override
  Future<dynamic> postApi(String url, dynamic data) async {
    writes.add(Map<String, dynamic>.from(data));
    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'reconnect drains all cursor pages, deduplicates and acknowledges visible messages',
    () async {
      final api = ChatApi();
      final service = SchoolChatService(api: api);
      await service.select('room');
      expect(api.reads, [0, 100]);
      expect(service.messages.length, 101);
      expect(api.writes.last, {'through': 101, 'read': true});
      await service.sync();
      expect(api.reads.last, 101);
      expect(service.messages.length, 101);
      service.visible = false;
      await service.sync();
      expect(api.writes.last['read'], false);
      expect(service.status({'id': 100, 'senderId': 1}), 'Read');
      expect(service.status({'id': 101, 'senderId': 1}), 'Delivered');
      expect(service.status({'id': 102, 'senderId': 1}), 'Sent');
      service.dispose();
    },
  );

  test(
    'WebSocket send waits for server ACK and retains stable retry id with attachment',
    () async {
      final api = ChatApi();
      late SchoolChatService chat;
      Map<String, dynamic>? sent;
      chat = SchoolChatService(
        api: api,
        socketSend: (destination, body) {
          expect(destination, '/app/chat.send');
          sent = Map<String, dynamic>.from(jsonDecode(body));
          chat.handleSocketEvent({
            'type': 'ack',
            'roomId': 'room',
            'clientId': sent!['clientId'],
            'message': {'id': 102, 'senderId': 1, 'text': 'Hello'},
          });
        },
      );
      await chat.select('room');
      chat.setIdentity('1', 'Teacher');
      chat.connected = true;
      await chat.send('Hello', 'stable-retry-id', 'attachment');
      expect(sent, {
        'roomId': 'room',
        'text': 'Hello',
        'clientId': 'stable-retry-id',
        'attachmentId': 'attachment',
      });
      expect(chat.messages.any((m) => m['id'] == 102), true);
      chat.dispose();
    },
  );
  test(
    'WebSocket rejects unauthorized send without falling back to REST',
    () async {
      late SchoolChatService chat;
      chat = SchoolChatService(
        api: ChatApi(),
        socketSend: (_, body) {
          final data = jsonDecode(body);
          chat.handleSocketEvent({
            'type': 'send-error',
            'clientId': data['clientId'],
            'error': 'Chat access denied',
          });
        },
      );
      await chat.select('room');
      chat.setIdentity('1', 'Teacher');
      chat.connected = true;
      await expectLater(chat.send('Hello', 'rejected', null), throwsStateError);
      chat.dispose();
    },
  );
  test('disconnected chat keeps send unconfirmed for retry', () async {
    final chat = SchoolChatService(api: ChatApi());
    await chat.select('room');
    await expectLater(chat.send('Draft', 'offline', null), throwsStateError);
    chat.dispose();
  });
  test(
    'message payload renders synchronously without waiting for history and merges once',
    () async {
      final api = ChatApi();
      final service = SchoolChatService(api: api);
      service.setIdentity('1', 'Teacher');
      await service.select('room');
      final calls = api.reads.length;
      final message = {
        'id': 102,
        'clientId': 'incoming-102',
        'senderId': 2,
        'senderName': 'Admin',
        'text': 'Immediate socket content',
        'sentAt': '2026-10-30T00:00:00Z',
      };
      service.handleSocketEvent({
        'type': 'message',
        'roomId': 'room',
        'message': message,
      });
      expect(service.messages.last['text'], 'Immediate socket content');
      expect(api.reads.length, calls);
      service.handleSocketEvent({
        'type': 'message',
        'roomId': 'room',
        'message': message,
      });
      expect(service.messages.where((m) => m['id'] == 102).length, 1);
      service.handleSocketEvent({
        'type': 'receipt',
        'roomId': 'room',
        'userId': 2,
        'readThrough': 102,
        'deliveredThrough': 102,
      });
      expect(service.status({'id': 102, 'senderId': 1}), 'Read');
      service.handleSocketEvent({
        'type': 'receipt',
        'roomId': 'room',
        'userId': 2,
        'readThrough': 100,
        'deliveredThrough': 100,
      });
      expect(service.status({'id': 102, 'senderId': 1}), 'Read');
      service.dispose();
    },
  );
  test(
    'own committed broadcast replaces pending bubble and confirms send before ACK/history',
    () async {
      late SchoolChatService service;
      Map<String, dynamic>? command;
      service = SchoolChatService(
        api: ChatApi(),
        socketSend: (_, body) {
          command = Map<String, dynamic>.from(jsonDecode(body));
        },
      );
      service.setIdentity('1', 'Teacher');
      await service.select('room');
      service.connected = true;
      final sending = service.send('Instant', 'same-client', null);
      expect(service.messages.last['localState'], 'sending');
      expect(command!['clientId'], 'same-client');
      final persisted = {
        'id': 102,
        'clientId': 'same-client',
        'senderId': 1,
        'text': 'Instant',
        'sentAt': '2026-10-30T00:00:00Z',
      };
      service.handleSocketEvent({
        'type': 'message',
        'roomId': 'room',
        'message': persisted,
      });
      await sending;
      service.handleSocketEvent({
        'type': 'ack',
        'roomId': 'room',
        'clientId': 'same-client',
        'message': persisted,
      });
      expect(
        service.messages.where((m) => m['clientId'] == 'same-client').length,
        1,
      );
      expect(service.messages.last['localState'], isNull);
      service.dispose();
    },
  );
}
