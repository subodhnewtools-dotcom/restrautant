import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_card_widget.dart';
import '../providers/messages_providers.dart';
import '../widgets/message_card_widget.dart';
import 'message_editor_screen.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider);

    return Scaffold(
      appBar: buildAppBar(context, title: 'Quick Messages'),
      body: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.message,
              title: 'No Messages',
              message: 'Create message templates to quickly share with customers',
              actionLabel: 'Create Message',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessageEditorScreen()),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return MessageCardWidget(
                title: message.title,
                body: message.body,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MessageEditorScreen(messageId: message.id),
                  ),
                ),
                onDelete: () => _confirmDelete(context, ref, message.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorCardWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(messagesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessageEditorScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String messageId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(messagesRepositoryProvider).deleteMessage(messageId);
              if (context.mounted) Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
