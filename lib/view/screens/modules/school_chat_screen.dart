import 'dart:async';
import 'dart:typed_data';
import 'chat_video_preview.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/school_chat_service.dart';
import '../../../services/storage/local_storage.dart';
import '../../../utils/app_url.dart';

class SchoolChatScreen extends StatefulWidget {
  final bool isInline;
  final SchoolChatService? service;
  const SchoolChatScreen({super.key, this.isInline = false, this.service});
  @override
  State<SchoolChatScreen> createState() => _SchoolChatScreenState();
}

class _SchoolChatScreenState extends State<SchoolChatScreen>
    with WidgetsBindingObserver {
  late final SchoolChatService chat;
  final text = TextEditingController(), scroll = ScrollController();
  Map<String, dynamic>? attachment;
  String? myId, role;
  bool busy = false, showEmoji = false;
  final focus = FocusNode();
  final previews = <String, Future<Uint8List>>{};
  String search = '';
  static const emoji = [
    '😀',
    '😃',
    '😊',
    '😂',
    '🤣',
    '😍',
    '🥰',
    '😎',
    '🤔',
    '😢',
    '😭',
    '😡',
    '🥳',
    '🙏',
    '👍',
    '👎',
    '👏',
    '🙌',
    '🤝',
    '💪',
    '❤️',
    '💙',
    '💚',
    '💯',
    '✅',
    '🎉',
    '🎂',
    '🌟',
    '🔥',
    '📚',
    '✏️',
    '🏫',
    '🚌',
    '📅',
    '📎',
    '👋',
    '🤗',
    '😴',
    '💐',
    '☀️',
    '🌙',
    '🍎',
    '⚽',
    '🏆',
    '💡',
    '📢',
    '🙋',
    '🙂',
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    chat = widget.service ?? SchoolChatService();
    chat.addListener(update);
    initialize();
  }

  Future<void> initialize() async {
    final user = await StorageHelper.getUserSession();
    myId = user?.id;
    role = user?.userType;
    if (user != null) chat.setIdentity(user.id, user.name);
    await chat.start();
  }

  void update() {
    if (!mounted) return;
    setState(() {});
    if (scroll.hasClients &&
        scroll.position.maxScrollExtent - scroll.offset < 180) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    chat.visible = state == AppLifecycleState.resumed;
    if (chat.visible) chat.sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    chat.removeListener(update);
    chat.dispose();
    text.dispose();
    scroll.dispose();
    focus.dispose();
    super.dispose();
  }

  void failure(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> create() async {
    var name = '';
    final ids = <int>{};
    var group = false;
    final allowedGroup = [
      'ADMIN',
      'MASTER_ADMIN',
      'SUPER_ADMIN',
      'PRINCIPAL',
      'TEACHER',
    ].contains(role);
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('New conversation'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allowedGroup)
                  CheckboxListTile(
                    title: const Text('Group conversation'),
                    value: group,
                    onChanged: (value) => setLocal(() {
                      group = value!;
                      ids.clear();
                    }),
                  ),
                if (group)
                  TextField(
                    onChanged: (value) => setLocal(() => name = value),
                    maxLength: 120,
                    decoration: const InputDecoration(labelText: 'Group name'),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: chat.contacts
                        .map(
                          (c) => CheckboxListTile(
                            title: Text(c['name']),
                            subtitle: Text(c['role']),
                            value: ids.contains(c['id']),
                            onChanged: (value) => setLocal(() {
                              if (!group) ids.clear();
                              if (value!) {
                                ids.add((c['id'] as num).toInt());
                              } else {
                                ids.remove(c['id']);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (chat.contacts.isEmpty)
                  const Text('No authorized contacts available.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: ids.isEmpty || (group && name.trim().isEmpty)
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
    final title = name;
    if (submit == true) {
      try {
        await chat.create(title, group, ids.toList());
      } catch (e) {
        failure(e);
      }
    }
  }

  void send() {
    if (busy || (text.text.trim().isEmpty && attachment == null)) return;
    final content = text.text, file = attachment;
    final clientId =
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    text.clear();
    setState(() {
      attachment = null;
    });
    unawaited(
      chat.send(content, clientId, file?['id'], attachment: file).catchError((
        Object e,
      ) {
        failure(e);
      }),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  void insertEmoji(String value) {
    final selection = text.selection;
    final start = selection.isValid ? selection.start : text.text.length;
    final end = selection.isValid ? selection.end : text.text.length;
    text.value = TextEditingValue(
      text: text.text.replaceRange(start, end, value),
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

  Future<void> upload() async {
    if (busy) return;
    final type = await showModalBottomSheet<FileType>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 16,
            children: [
              for (final option in [
                (FileType.image, Icons.photo_library, 'Photos'),
                (FileType.video, Icons.videocam, 'Video'),
                (FileType.any, Icons.insert_drive_file, 'Document / file'),
              ])
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, option.$1),
                  icon: Icon(option.$2),
                  label: Text(option.$3),
                ),
            ],
          ),
        ),
      ),
    );
    if (type == null || !mounted) return;
    final originalRoom = chat.selectedRoom;
    try {
      final file = await FilePicker.pickFile(type: type);
      if (file == null || !mounted || chat.selectedRoom != originalRoom) return;
      final size = await file.length();
      if (size == null || size > 25 * 1024 * 1024) {
        throw StateError('Choose a file up to 25 MB');
      }
      setState(() => busy = true);
      final result = await chat.upload(file.name, await file.readAsBytes());
      if (mounted && chat.selectedRoom == originalRoom) {
        setState(() => attachment = result);
      }
    } catch (e) {
      failure(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> download(Map<String, dynamic> file) async {
    try {
      if ((file['type'] as String).startsWith('video/')) {
        await showDialog<void>(
          context: context,
          builder: (_) => ChatVideoPreview(file: file, api: chat.api),
        );
        return;
      }
      final bytes = await chat.api.getBytes(
        '${AppUrl.baseUrl}/chat/attachments/${file['id']}',
      );
      if (!mounted) return;
      if ((file['type'] as String).startsWith('image/')) {
        await showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: InteractiveViewer(child: Image.memory(bytes))),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      } else {
        await FilePicker.saveFile(
          fileName: file['name'],
          bytes: bytes,
          mimeType: file['type'],
        );
      }
    } catch (e) {
      failure(e);
    }
  }

  Widget media(Map<String, dynamic> file) {
    final type = file['type'] as String;
    final isImage = type.startsWith('image/'),
        isVideo = type.startsWith('video/');
    return InkWell(
      onTap: () => download(file),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 270),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<Uint8List>(
                  future: previews.putIfAbsent(
                    file['id'],
                    () => chat.api.getBytes(
                      '${AppUrl.baseUrl}/chat/attachments/${file['id']}',
                    ),
                  ),
                  builder: (_, snapshot) => snapshot.hasData
                      ? Image.memory(
                          snapshot.data!,
                          height: 170,
                          width: 250,
                          fit: BoxFit.cover,
                        )
                      : SizedBox(
                          height: 100,
                          width: 220,
                          child: Center(
                            child: snapshot.hasError
                                ? const Icon(Icons.broken_image_outlined)
                                : const CircularProgressIndicator(),
                          ),
                        ),
                ),
              ),
            if (isVideo)
              Container(
                height: 140,
                width: 250,
                decoration: BoxDecoration(
                  color: const Color(0xff234d4e),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 58,
                    color: Colors.white,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isImage
                      ? Icons.image_outlined
                      : isVideo
                      ? Icons.videocam_outlined
                      : Icons.description_outlined,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    file['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '${((file['size'] as num? ?? 0) / 1024).toStringAsFixed(0)} KB · ${isVideo
                  ? 'Tap to play'
                  : isImage
                  ? 'Tap to view'
                  : 'Tap to save'}',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget composer() => Material(
    color: const Color(0xfff0f2f5),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachment != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: Color(0xff008069)),
                    Expanded(
                      child: Text(
                        attachment!['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => attachment = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Emoji',
                          onPressed: () {
                            focus.unfocus();
                            setState(() => showEmoji = !showEmoji);
                          },
                          icon: Icon(
                            showEmoji
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                            color: const Color(0xff667781),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: text,
                            focusNode: focus,
                            onTap: () => setState(() => showEmoji = false),
                            maxLength: 4000,
                            minLines: 1,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Message',
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Attach photo, video or file',
                          onPressed: busy ? null : upload,
                          icon: const Icon(
                            Icons.attach_file,
                            color: Color(0xff667781),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xff008069),
                    ),
                    onPressed: busy ? null : send,
                    tooltip: 'Send',
                    icon: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (showEmoji)
              SizedBox(
                height: 220,
                child: GridView.count(
                  crossAxisCount: 8,
                  children: emoji
                      .map(
                        (value) => InkWell(
                          onTap: () => insertEmoji(value),
                          child: Center(
                            child: Text(
                              value,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  void backToList() {
    chat.select(null);
    text.clear();
    setState(() {
      attachment = null;
      showEmoji = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = chat.room;
    final filtered = chat.rooms
        .where(
          (r) =>
              r['name'].toString().toLowerCase().contains(search.toLowerCase()),
        )
        .toList();
    return PopScope(
      canPop: chat.selectedRoom == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (showEmoji) {
            setState(() => showEmoji = false);
          } else {
            backToList();
          }
        }
      },
      child: Scaffold(
        backgroundColor: active == null
            ? Colors.white
            : const Color(0xffefeae2),
        appBar: AppBar(
          backgroundColor: const Color(0xff075e54),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                active?['name'] ?? 'School Messages',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                chat.connected ? 'Connected' : 'Connecting…',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          leading: chat.selectedRoom != null
              ? IconButton(
                  onPressed: busy ? null : backToList,
                  icon: const Icon(Icons.arrow_back),
                )
              : widget.isInline
              ? const SizedBox.shrink()
              : null,
          actions: [
            IconButton(
              onPressed: chat.sync,
              tooltip: 'Sync messages',
              icon: const Icon(Icons.sync),
            ),
            IconButton(
              onPressed: create,
              tooltip: 'New conversation',
              icon: const Icon(Icons.add_comment_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            if (chat.error != null)
              MaterialBanner(
                content: Text(
                  chat.error!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      chat.error = null;
                      chat.sync();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            if (active == null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (value) => setState(() => search = value),
                  decoration: InputDecoration(
                    hintText: 'Search conversations',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xfff0f2f5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: active == null
                  ? filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.forum_outlined,
                                  size: 60,
                                  color: Color(0xff008069),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Start a conversation with your school.',
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: create,
                                  icon: const Icon(Icons.add_comment_outlined),
                                  label: const Text('New chat'),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            children: filtered
                                .map(
                                  (r) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xffdfe5e7),
                                      child: Icon(
                                        r['groupChat'] == true
                                            ? Icons.groups
                                            : Icons.person,
                                        color: const Color(0xff667781),
                                      ),
                                    ),
                                    title: Text(
                                      r['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      r['lastMessage'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: (r['unreadCount'] as num) > 0
                                        ? Badge(
                                            backgroundColor: const Color(
                                              0xff25d366,
                                            ),
                                            label: Text('${r['unreadCount']}'),
                                          )
                                        : null,
                                    onTap: () {
                                      chat.select(r['id']);
                                    },
                                  ),
                                )
                                .toList(),
                          )
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, i) {
                        final m = chat.messages[i];
                        final mine = '${m['senderId']}' == myId;
                        final status = chat.status(m);
                        final date = DateTime.tryParse(m['sentAt'])?.toLocal();
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .82,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.fromLTRB(10, 8, 8, 5),
                            decoration: BoxDecoration(
                              color: mine
                                  ? const Color(0xffd9fdd3)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x10000000),
                                  offset: Offset(0, 1),
                                  blurRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!mine)
                                  Text(
                                    m['senderName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Color(0xff008069),
                                    ),
                                  ),
                                if (m['attachment'] != null)
                                  media(
                                    Map<String, dynamic>.from(m['attachment']),
                                  ),
                                if ((m['text'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: SelectableText(
                                      m['text'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xff111b21),
                                      ),
                                    ),
                                  ),
                                if (status.startsWith('Failed'))
                                  TextButton.icon(
                                    onPressed: () {
                                      unawaited(
                                        chat.retry(m).catchError((Object e) {
                                          failure(e);
                                        }),
                                      );
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry send'),
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      date == null
                                          ? ''
                                          : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xff667781),
                                      ),
                                    ),
                                    if (mine) ...[
                                      const SizedBox(width: 5),
                                      Semantics(
                                        label: status,
                                        child: Tooltip(
                                          message: status,
                                          child: Icon(
                                            status == 'Sending'
                                                ? Icons.access_time
                                                : status.startsWith('Failed')
                                                ? Icons.error_outline
                                                : status == 'Sent'
                                                ? Icons.check
                                                : Icons.done_all,
                                            size: 16,
                                            color: status == 'Read'
                                                ? const Color(0xff53bdeb)
                                                : const Color(0xff667781),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (active != null) composer(),
          ],
        ),
      ),
    );
  }
}
