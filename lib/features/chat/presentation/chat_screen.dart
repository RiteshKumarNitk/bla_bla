import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/chat/data/chat_repository.dart';
import 'package:bla_bla/features/chat/domain/message_model.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String title;

  const ChatScreen({super.key, required this.rideId, required this.title});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(chatRepositoryProvider).sendMessage(widget.rideId, content);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = ref.watch(chatStreamProvider(widget.rideId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesStream.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Start the conversation!'));
                }
                  return ListView.builder(
                    reverse: true, // List starts from bottom
                    itemCount: messages.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMine ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isMine ? const Radius.circular(16) : Radius.zero,
            bottomRight: message.isMine ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isMine ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

final chatStreamProvider = StreamProvider.family<List<Message>, String>((ref, rideId) {
  return ref.watch(chatRepositoryProvider).getMessagesStream(rideId);
});
