class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });
}

class ChatChannel {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final List<Message> messages;

  const ChatChannel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    required this.messages,
  });

  ChatChannel copyWith({
    String? id,
    String? name,
    String? lastMessage,
    String? time,
    String? avatarUrl,
    List<Message>? messages,
  }) {
    return ChatChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      messages: messages ?? this.messages,
    );
  }
}
