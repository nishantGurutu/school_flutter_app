import 'chat_attachment_picker.dart';
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
  final Map<String, Completer<String?>> _pendingSends = {};
  final Map<String, Map<String, dynamic>> _queue = {};
  final Set<String> _uploading = {};
  final Map<String, ChatPickedAttachment> _files = {};
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
        _queue.remove(message['clientId']);
        _files.remove(message['clientId']);
        final pending = _pendingSends[message['clientId']];
        if (pending != null && !pending.isCompleted) pending.complete(null);
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
      flushPending();
      if (_socketBase != AppUrl.baseUrl || _socket?.isActive != true) {
        unawaited(_connect());
      }
    });
    _reauth = Timer.periodic(const Duration(minutes: 20), (_) {
      unawaited(_connect());
    });
    changed();
  }

  void _connectionLost() {
    connected = false;
    for (final pending in _pendingSends.values) {
      if (!pending.isCompleted) pending.complete('__retry__');
    }
    changed();
  }

  Future<void> _connect() async {
    _connectionLost();
    _socket?.deactivate();
    if (_disposed) return;
    _socketBase = AppUrl.baseUrl;
    final headers = <String, String>{};
    late StompClient client;
    client = StompClient(
      config: StompConfig(
        url: '${_socketBase!.replaceFirst(RegExp('^http'), 'ws')}/chat/ws',
        stompConnectHeaders: headers,
        reconnectDelay: const Duration(seconds: 2),
        connectionTimeout: const Duration(seconds: 10),
        beforeConnect: () async {
          try {
            await api.getApi('${AppUrl.baseUrl}/chat/rooms');
            if (_disposed || !identical(_socket, client)) {
              client.deactivate();
              return;
            }
            headers['Authorization'] =
                'Bearer ${await StorageHelper.getAccessToken()}';
          } catch (e) {
            if (!identical(_socket, client)) return;
            error = e.toString().contains('static resource')
                ? 'Chat API is missing on ${AppUrl.baseUrl}. Start the updated Spring Boot backend on this saved server and tap Retry.'
                : e.toString();
            client.deactivate();
            connected = false;
            changed();
          }
        },
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: (_) {
          if (_disposed || !identical(_socket, client)) return;
          connected = true;
          client.subscribe(
            destination: '/user/queue/chat',
            callback: (frame) {
              if (_disposed || !identical(_socket, client)) return;
              if (frame.body != null) {
                handleSocketEvent(
                  Map<String, dynamic>.from(jsonDecode(frame.body!)),
                );
              }
            },
          );
          flushPending();
          unawaited(sync());
          changed();
        },
        onWebSocketDone: () {
          if (!identical(_socket, client)) return;
          _connectionLost();
        },
        onWebSocketError: (_) {
          if (!identical(_socket, client)) return;
          _connectionLost();
        },
        onStompError: (_) {
          if (!identical(_socket, client)) return;
          _connectionLost();
          client.deactivate();
        },
      ),
    );
    _socket = client;
    client.activate();
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
        _queue.remove(message['clientId']);
        _files.remove(message['clientId']);
        final confirmed = _pendingSends[message['clientId']];
        if (confirmed != null && !confirmed.isCompleted) {
          confirmed.complete(null);
        }
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
      pending.complete(null);
    }
    if (type == 'send-error' && pending != null && !pending.isCompleted) {
      pending.complete(event['error']?.toString() ?? 'Message rejected');
    }
    _backgroundSync();
  }

  bool get _ready =>
      connected &&
      (socketSend != null ||
          (_socket?.connected == true && _socketBase == AppUrl.baseUrl));

  void resume() {
    visible = true;
    unawaited(sync());
    if (!_ready && socketSend == null) unawaited(_connect());
    flushPending();
  }

  void flushPending() {
    if (_disposed) return;
    for (final command in List<Map<String, dynamic>>.from(_queue.values)) {
      final id = command['clientId'] as String;
      final local = _outgoing['${command['roomId']}:$id'];
      if (local == null ||
          local['localState'] == 'failed' ||
          _uploading.contains(id) ||
          _pendingSends.containsKey(id)) {
        continue;
      }
      if (command['baseUrl'] != AppUrl.baseUrl) {
        local['localState'] = 'failed';
        local['sendError'] =
            'API environment changed. Return to the original environment to retry.';
        changed();
        continue;
      }
      if (_files.containsKey(id) && command['attachmentId'] == null) {
        unawaited(_uploadQueued(command, local));
      } else if (_ready) {
        unawaited(_sendQueued(command, local));
      }
    }
  }

  void queueAttachment(
    String text,
    String clientId,
    ChatPickedAttachment file,
  ) {
    final room = selectedRoom;
    if (room == null) return;
    _files[clientId] = file;
    final mime = file.mimeType == 'application/octet-stream'
        ? _guessMime(file.name)
        : file.mimeType;
    _stage(room, text, clientId, null, {
      'id': 'local-$clientId',
      'name': file.name,
      'type': mime,
      'size': file.bytes.length,
      'localBytes': file.bytes,
    });
    flushPending();
  }

  String _guessMime(String name) {
    final ext = name.toLowerCase().split('.').last;
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      _ => 'application/octet-stream',
    };
  }

  Map<String, dynamic> _stage(
    String room,
    String text,
    String id,
    String? attachmentId,
    Map<String, dynamic>? attachment,
  ) {
    final local = _outgoing.putIfAbsent(
      '$room:$id',
      () => {
        'id': --_temporaryId,
        'roomId': room,
        'clientId': id,
        'senderId': _senderId ?? 'local',
        'senderName': _senderName,
        'text': text,
        'sentAt': DateTime.now().toUtc().toIso8601String(),
        'attachment': ?attachment,
        'attachmentId': ?attachmentId,
      },
    );
    local['localState'] = 'queued';
    _queue.putIfAbsent(
      id,
      () => {
        'roomId': room,
        'clientId': id,
        'text': text,
        'attachmentId': attachmentId,
        'baseUrl': AppUrl.baseUrl,
        'senderId': _senderId,
      },
    );
    if (room == selectedRoom) _merge([local]);
    changed();
    return local;
  }

  Future<bool> _sameAccount(Map<String, dynamic> command) async {
    if (socketSend != null) return true;
    return (await StorageHelper.getUserSession())?.id == command['senderId'];
  }

  Future<void> _uploadQueued(
    Map<String, dynamic> command,
    Map<String, dynamic> local,
  ) async {
    final id = command['clientId'] as String;
    if (!_uploading.add(id)) return;
    final file = _files[id];
    if (file == null) {
      _uploading.remove(id);
      return;
    }
    local['localState'] = 'uploading';
    local['uploadProgress'] = 0.0;
    changed();
    try {
      if (!await _sameAccount(command) || _disposed) {
        local['localState'] = 'failed';
        local['sendError'] = 'Sign in with the original account to retry.';
        changed();
        return;
      }
      if (command['baseUrl'] != AppUrl.baseUrl) {
        local['localState'] = 'failed';
        local['sendError'] =
            'API environment changed. Return to the original environment to retry.';
        changed();
        return;
      }
      final saved = await upload(
        file.name,
        file.bytes,
        roomId: command['roomId'],
        onProgress: (value) {
          local['uploadProgress'] = value;
          changed();
        },
      );
      if (_disposed) return;
      command['attachmentId'] = saved['id'];
      local['attachmentId'] = saved['id'];
      local['attachment'] = {...saved, 'localBytes': file.bytes};
      local['localState'] = 'queued';
      changed();
    } catch (e) {
      if (!_disposed) {
        local['localState'] = 'failed';
        local['sendError'] = e.toString();
        changed();
      }
    } finally {
      _uploading.remove(id);
    }
    if (!_disposed && local['localState'] != 'failed') flushPending();
  }

  Future<void> _sendQueued(
    Map<String, dynamic> command,
    Map<String, dynamic> local,
  ) async {
    final id = command['clientId'] as String;
    if (_disposed || !_ready || _pendingSends.containsKey(id)) return;
    final completer = Completer<String?>();
    _pendingSends[id] = completer;
    local['localState'] = 'sending';
    changed();
    try {
      if (!await _sameAccount(command) || _disposed) {
        local['localState'] = 'failed';
        local['sendError'] = 'Sign in with the original account to retry.';
        changed();
        return;
      }
      if (!_ready || command['baseUrl'] != AppUrl.baseUrl) {
        local['localState'] = 'queued';
        changed();
        return;
      }
      final body = jsonEncode({
        'roomId': command['roomId'],
        'text': command['text'],
        'clientId': id,
        'attachmentId': ?command['attachmentId'],
      });
      if (socketSend != null) {
        socketSend!('/app/chat.send', body);
      } else {
        _socket!.send(destination: '/app/chat.send', body: body);
      }
      final rejection = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => '__retry__',
      );
      if (_disposed || !_queue.containsKey(id)) return;
      if (rejection == null) {
        _queue.remove(id);
        _files.remove(id);
        local.remove('localState');
      } else if (rejection == '__retry__') {
        local['localState'] = 'queued';
      } else {
        local['localState'] = 'failed';
        local['sendError'] = rejection;
      }
      changed();
    } catch (e) {
      // A socket can close between the readiness check and send. Keep the message queued.
      if (!_disposed && _queue.containsKey(id)) {
        local['localState'] = 'queued';
        local['sendError'] = 'Waiting for connection';
        changed();
      }
    } finally {
      _pendingSends.remove(id);
    }
  }

  Future<void> send(
    String text,
    String clientId,
    String? attachmentId, {
    Map<String, dynamic>? attachment,
  }) async {
    final room = selectedRoom;
    if (room == null) return;
    final local = _stage(room, text, clientId, attachmentId, attachment);
    if (_ready) {
      await _sendQueued(_queue[clientId]!, local);
    }
    // Disconnected sends are queued; reconnect callbacks flush them without throwing.
  }

  Future<void> retry(Map<String, dynamic> message) async {
    message['localState'] = 'queued';
    message.remove('sendError');
    changed();
    flushPending();
  }

  Future<Map<String, dynamic>> upload(
    String name,
    List<int> bytes, {
    String? roomId,
    ValueChanged<double>? onProgress,
  }) async {
    if (bytes.length > 25 * 1024 * 1024) {
      throw StateError('Maximum file size is 25 MB');
    }
    return Map<String, dynamic>.from(
      await api.postMultipart(
        '${AppUrl.baseUrl}/chat/rooms/${roomId ?? selectedRoom}/attachments',
        FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: name),
        }),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call((sent / total).clamp(0, 1));
        },
      ),
    );
  }

  String status(Map<String, dynamic> message) {
    if (message['localState'] == 'uploading') {
      return 'Uploading ${((message['uploadProgress'] as num? ?? 0) * 100).round()}%';
    }
    if (message['localState'] == 'queued') return 'Waiting for connection';
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
        pending.complete('__retry__');
      }
    }
    super.dispose();
  }
}
