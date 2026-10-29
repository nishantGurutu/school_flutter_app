import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../data/network/network_api_services.dart';
import 'storage/local_storage.dart';
import '../utils/app_url.dart';

class SchoolChatService extends ChangeNotifier {
  final NetworkApiService api;
  final void Function(String destination, String body)? socketSend;
  final Map<String, Completer<void>> _pendingSends = {};
  SchoolChatService({NetworkApiService? api, this.socketSend})
    : api = api ?? NetworkApiService();
  List<Map<String, dynamic>> rooms = [], contacts = [], messages = [];
  String? selectedRoom, error;
  bool connected = false, _syncing = false, _disposed = false, visible = true;
  int _cursor = 0, _temporaryId = 0;
  String? _senderId;
  String _senderName = 'You';
  final Map<String, Map<String, dynamic>> _outgoing = {};
  Timer? _eventSync;
  void setIdentity(String id, String name) {
    _senderId = id;
    _senderName = name;
  }

  String _key(Map<String, dynamic> message) => message['clientId'] != null
      ? '${message['senderId']}:${message['clientId']}'
      : 'id:${message['id']}';
  void _merge(List<Map<String, dynamic>> incoming) {
    for (final message in incoming) {
      if ((message['id'] as num) > 0 &&
          message['clientId'] != null &&
          message['senderId'].toString() == _senderId) {
        _outgoing.remove('$selectedRoom:${message['clientId']}');
        final pending = _pendingSends[message['clientId']];
        if (pending != null && !pending.isCompleted) pending.complete();
      }
    }
    final merged = <String, Map<String, dynamic>>{};
    for (final message in [...messages, ...incoming]) {
      merged[_key(message)] = message;
    }
    messages = merged.values.toList()
      ..sort((a, b) {
        final x = (a['id'] as num).toInt(), y = (b['id'] as num).toInt();
        if (x > 0 && y > 0) return x.compareTo(y);
        if (x < 0 && y < 0) return y.compareTo(x);
        return x > 0 ? -1 : 1;
      });
  }

  void _backgroundSync() {
    _eventSync?.cancel();
    _eventSync = Timer(const Duration(milliseconds: 150), () {
      unawaited(sync());
    });
  }

  Timer? _poll, _reauth;
  StompClient? _socket;
  String? _socketBase;
  Map<String, dynamic>? get room {
    for (final r in rooms) {
      if (r['id'] == selectedRoom) return r;
    }
    return null;
  }

  void changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    final user = await StorageHelper.getUserSession();
    if (user != null) setIdentity(user.id, user.name);
    await sync();
    try {
      contacts = List<Map<String, dynamic>>.from(
        await api.getApi('${AppUrl.baseUrl}/chat/contacts'),
      );
    } catch (e) {
      error = e.toString().contains('static resource')
          ? 'Chat API is missing on ${AppUrl.baseUrl}. Start the updated Spring Boot backend on this saved server and tap Retry.'
          : e.toString();
    }
    if (_disposed) return;
    await _connect();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(sync());
      if (_socketBase != AppUrl.baseUrl || _socket?.isActive != true) {
        unawaited(_connect());
      }
    });
    _reauth = Timer.periodic(const Duration(minutes: 20), (_) {
      unawaited(_connect());
    });
    changed();
  }

  Future<void> _connect() async {
    _socket?.deactivate();
    if (_disposed) return;
    _socketBase = AppUrl.baseUrl;
    final headers = <String, String>{};
    _socket = StompClient(
      config: StompConfig(
        url: '${_socketBase!.replaceFirst(RegExp('^http'), 'ws')}/chat/ws',
        stompConnectHeaders: headers,
        beforeConnect: () async {
          try {
            await api.getApi('${AppUrl.baseUrl}/chat/rooms');
            headers['Authorization'] =
                'Bearer ${await StorageHelper.getAccessToken()}';
          } catch (e) {
            error = e.toString().contains('static resource')
                ? 'Chat API is missing on ${AppUrl.baseUrl}. Start the updated Spring Boot backend on this saved server and tap Retry.'
                : e.toString();
            _socket?.deactivate();
            connected = false;
            changed();
          }
        },
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: (_) {
          if (_disposed) return;
          connected = true;
          _socket?.subscribe(
            destination: '/user/queue/chat',
            callback: (frame) {
              if (frame.body != null) {
                handleSocketEvent(
                  Map<String, dynamic>.from(jsonDecode(frame.body!)),
                );
              }
            },
          );
          unawaited(sync());
          changed();
        },
        onWebSocketDone: () {
          connected = false;
          changed();
        },
        onWebSocketError: (_) {
          connected = false;
          changed();
        },
        onStompError: (_) {
          connected = false;
          changed();
          _socket?.deactivate();
        },
      ),
    );
    _socket!.activate();
  }

  Future<void> select(String? roomId) async {
    selectedRoom = roomId;
    _cursor = 0;
    messages = _outgoing.values.where((m) => m['roomId'] == roomId).toList();
    error = null;
    changed();
    await sync();
  }

  Future<void> sync() async {
    if (_syncing || _disposed) return;
    _syncing = true;
    try {
      rooms = List<Map<String, dynamic>>.from(
        await api.getApi('${AppUrl.baseUrl}/chat/rooms'),
      );
      if (_disposed) return;
      error = null;
      if (contacts.isEmpty) {
        contacts = List<Map<String, dynamic>>.from(
          await api.getApi('${AppUrl.baseUrl}/chat/contacts'),
        );
      }
      final current = selectedRoom;
      if (current == null) return;
      var after = _cursor, more = true;
      final received = <Map<String, dynamic>>[];
      while (more && selectedRoom == current && !_disposed) {
        final page = await api.getApi(
          '${AppUrl.baseUrl}/chat/rooms/$current/messages?after=$after',
        );
        final batch = List<Map<String, dynamic>>.from(page['messages']);
        received.addAll(batch);
        more = page['hasMore'] == true && batch.isNotEmpty;
        if (batch.isNotEmpty) after = (batch.last['id'] as num).toInt();
      }
      if (selectedRoom != current || _disposed) return;
      _cursor = after;
      _merge(received);
      if (after > 0) {
        await api.postApi('${AppUrl.baseUrl}/chat/rooms/$current/receipts', {
          'through': after,
          'read': visible,
        });
      }
    } catch (e) {
      error = e.toString().contains('static resource')
          ? 'Chat API is missing on ${AppUrl.baseUrl}. Start the updated Spring Boot backend on this saved server and tap Retry.'
          : e.toString();
    } finally {
      _syncing = false;
      changed();
    }
  }

  Future<void> create(String name, bool group, List<int> ids) async {
    final result = await api.postApi('${AppUrl.baseUrl}/chat/rooms', {
      'name': name,
      'groupChat': group,
      'memberIds': ids,
    });
    await select(result['id'] as String);
  }

  void handleSocketEvent(Map<String, dynamic> event) {
    final id = event['clientId']?.toString(), type = event['type'];
    final pending = _pendingSends[id];
    if ((type == 'ack' || type == 'message') && event['message'] is Map) {
      final message = Map<String, dynamic>.from(event['message']);
      if (id != null) message.putIfAbsent('clientId', () => id);
      if (message['senderId'].toString() == _senderId &&
          message['clientId'] != null) {
        _outgoing.remove('${event['roomId']}:${message['clientId']}');
        final confirmed = _pendingSends[message['clientId']];
        if (confirmed != null && !confirmed.isCompleted) confirmed.complete();
      }
      if (event['roomId'] == selectedRoom) {
        _merge([message]);
        changed();
      }
      for (final r in rooms) {
        if (r['id'] == event['roomId']) {
          r['lastMessage'] = message['text'];
        }
      }
    }
    if (type == 'receipt') {
      for (final r in rooms) {
        if (r['id'] != event['roomId']) continue;
        for (final member in (r['members'] as List? ?? [])) {
          if (member['id'].toString() == event['userId'].toString()) {
            for (final field in ['readThrough', 'deliveredThrough']) {
              final value = event[field] as num?;
              if (value != null && value > (member[field] as num? ?? 0)) {
                member[field] = value;
              }
            }
          }
        }
      }
      changed();
      return;
    }
    if (type == 'ack' && pending != null && !pending.isCompleted) {
      pending.complete();
    }
    if (type == 'send-error' && pending != null && !pending.isCompleted) {
      pending.completeError(
        StateError(event['error']?.toString() ?? 'Message rejected'),
      );
    }
    _backgroundSync();
  }

  Future<void> send(
    String text,
    String clientId,
    String? attachmentId, {
    Map<String, dynamic>? attachment,
  }) async {
    final current = selectedRoom;
    if (current == null) return;
    if (_pendingSends.containsKey(clientId)) {
      return _pendingSends[clientId]!.future;
    }
    final local = _outgoing.putIfAbsent(
      '$current:$clientId',
      () => {
        'id': --_temporaryId,
        'roomId': current,
        'clientId': clientId,
        'senderId': _senderId ?? 'local',
        'senderName': _senderName,
        'text': text,
        'sentAt': DateTime.now().toUtc().toIso8601String(),
        'attachment': ?attachment,
        'attachmentId': ?attachmentId,
      },
    );
    local['localState'] = 'sending';
    _merge([local]);
    changed();
    final completer = Completer<void>();
    _pendingSends[clientId] = completer;
    try {
      if (!connected || (_socket == null && socketSend == null)) {
        throw StateError(
          'Chat is reconnecting. Tap the failed message to retry when connected.',
        );
      }
      final body = jsonEncode({
        'roomId': current,
        'text': text,
        'clientId': clientId,
        'attachmentId': ?attachmentId,
      });
      if (socketSend != null) {
        socketSend!('/app/chat.send', body);
      } else {
        _socket!.send(destination: '/app/chat.send', body: body);
      }
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Not confirmed yet. Tap this message to retry.',
          );
        },
      );
    } catch (e) {
      if (_outgoing.containsKey('$current:$clientId')) {
        local['localState'] = 'failed';
        local['sendError'] = e.toString();
        changed();
        rethrow;
      }
    } finally {
      _pendingSends.remove(clientId);
    }
  }

  Future<void> retry(Map<String, dynamic> message) => send(
    message['text'],
    message['clientId'],
    message['attachmentId'],
    attachment: message['attachment'] is Map
        ? Map<String, dynamic>.from(message['attachment'])
        : null,
  );

  Future<Map<String, dynamic>> upload(String name, List<int> bytes) async {
    if (bytes.length > 25 * 1024 * 1024) {
      throw StateError('Maximum file size is 25 MB');
    }
    return Map<String, dynamic>.from(
      await api.postApi(
        '${AppUrl.baseUrl}/chat/rooms/$selectedRoom/attachments',
        FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: name),
        }),
      ),
    );
  }

  String status(Map<String, dynamic> message) {
    if (message['localState'] == 'sending') return 'Sending';
    if (message['localState'] == 'failed') return 'Failed — tap to retry';
    final peers = (room?['members'] as List? ?? [])
        .where((p) => p['id'].toString() != message['senderId'].toString())
        .toList();
    if (peers.isNotEmpty &&
        peers.every(
          (p) => (p['readThrough'] as num) >= (message['id'] as num),
        )) {
      return 'Read';
    }
    if (peers.isNotEmpty &&
        peers.every(
          (p) => (p['deliveredThrough'] as num) >= (message['id'] as num),
        )) {
      return 'Delivered';
    }
    return 'Sent';
  }

  @override
  void dispose() {
    _disposed = true;
    _eventSync?.cancel();
    _poll?.cancel();
    _reauth?.cancel();
    _socket?.deactivate();
    for (final pending in _pendingSends.values) {
      if (!pending.isCompleted) {
        pending.completeError(
          StateError('Chat closed; draft was not confirmed.'),
        );
      }
    }
    super.dispose();
  }
}
