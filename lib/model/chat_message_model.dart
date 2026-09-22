class ChatMessage {
  final String text;
  final bool isSent;
  final String time;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.isSent,
    required this.time,
    this.isRead = false,
    this.imageUrl,
  });
}
