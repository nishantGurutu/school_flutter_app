import 'package:flutter/material.dart';
import 'school_chat_screen.dart';

/// Existing routes and inline dashboard tabs retain their public widget name.
class ChatScreen extends StatelessWidget {
  final bool isInline;
  const ChatScreen({super.key, this.isInline = false});
  @override
  Widget build(BuildContext context) => SchoolChatScreen(isInline: isInline);
}
