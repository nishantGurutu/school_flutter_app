class ChatItem {
  final String name;
  final String message;
  final String timeLabel;
  final String? imageUrl;
  final bool isVerified;
  final int? unreadCount;

  const ChatItem({
    required this.name,
    required this.message,
    required this.timeLabel,
    this.imageUrl,
    this.isVerified = false,
    this.unreadCount,
  });
}
