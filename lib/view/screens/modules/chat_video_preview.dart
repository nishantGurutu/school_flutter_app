import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../../../data/network/network_api_services.dart';
import '../../../utils/app_url.dart';

class ChatVideoPreview extends StatefulWidget {
  final Map<String, dynamic> file;
  final NetworkApiService api;
  const ChatVideoPreview({super.key, required this.file, required this.api});
  @override
  State<ChatVideoPreview> createState() => _ChatVideoPreviewState();
}

class _ChatVideoPreviewState extends State<ChatVideoPreview> {
  VideoPlayerController? player;
  File? local;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final bytes = widget.file['localBytes'] is Uint8List
          ? widget.file['localBytes'] as Uint8List
          : await widget.api.getBytes(
              '${AppUrl.baseUrl}/chat/attachments/${widget.file['id']}',
            );
      if (!mounted) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/chat-${widget.file['id']}-${DateTime.now().microsecondsSinceEpoch}.mp4',
      );
      local = file;
      await file.writeAsBytes(bytes);
      if (!mounted) {
        await file.delete();
        return;
      }
      final controller = VideoPlayerController.file(file);
      player = controller;
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(update);
      setState(() {});
      await controller.play();
    } catch (e) {
      if (mounted) {
        setState(
          () => error =
              'Unable to play this video on this device. ${e.toString()}',
        );
      }
    }
  }

  void update() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final old = player;
    old?.removeListener(update);
    final file = local;
    Future<void>(() async {
      try {
        await old?.dispose();
        if (file != null && await file.exists()) await file.delete();
      } catch (_) {
        /* Best-effort temporary preview cleanup. */
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.black,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error!, style: const TextStyle(color: Colors.white)),
          )
        else if (player?.value.isInitialized != true)
          const Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          )
        else ...[
          AspectRatio(
            aspectRatio: player!.value.aspectRatio,
            child: VideoPlayer(player!),
          ),
          VideoProgressIndicator(player!, allowScrubbing: true),
          IconButton(
            onPressed: () =>
                player!.value.isPlaying ? player!.pause() : player!.play(),
            icon: Icon(
              player!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            widget.file['name'],
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    ),
  );
}
