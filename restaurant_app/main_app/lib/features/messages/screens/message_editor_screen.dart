import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_bar_widget.dart';
import '../providers/messages_providers.dart';
import '../models/message_template_model.dart';

class MessageEditorScreen extends ConsumerStatefulWidget {
  final String? messageId;

  const MessageEditorScreen({super.key, this.messageId});

  @override
  ConsumerState<MessageEditorScreen> createState() => _MessageEditorScreenState();
}

class _MessageEditorScreenState extends ConsumerState<MessageEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  bool _isLoading = false;

  final List<String> _variables = [
    '{customer_name}',
    '{total_amount}',
    '{restaurant_name}',
    '{date}',
    '{time}',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();

    if (widget.messageId != null) {
      _loadMessage();
    }
  }

  void _loadMessage() {
    final message = ref.read(messagesRepositoryProvider).getMessageById(widget.messageId!);
    if (message != null) {
      _titleController.text = message.title;
      _bodyController.text = message.body;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _saveMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final message = MessageTemplateModel(
        id: widget.messageId,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );

      await ref.read(messagesRepositoryProvider).saveMessage(message);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.messageId == null ? 'Message created' : 'Message updated')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _insertVariable(String variable) {
    final cursorPosition = _bodyController.selection.baseOffset;
    final text = _bodyController.text;
    final newText = text.substring(0, cursorPosition) + variable + text.substring(cursorPosition);
    
    _bodyController.text = newText;
    _bodyController.selection = TextSelection.fromPosition(
      TextPosition(offset: cursorPosition + variable.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: widget.messageId == null ? 'New Message' : 'Edit Message',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Variables Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _variables.map((variable) {
                return ActionChip(
                  label: Text(variable),
                  onPressed: () => _insertVariable(variable),
                  avatar: const Icon(Icons.variable_insert, size: 18),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Body Field
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                prefixIcon: Icon(Icons.message),
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter message body';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Preview Card
            const Text(
              'Preview:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.isEmpty ? 'Message Title' : _titleController.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bodyController.text.isEmpty 
                          ? 'Your message will appear here. Use the variable chips above to insert dynamic content.'
                          : _bodyController.text,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveMessage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Message'),
            ),
          ],
        ),
      ),
    );
  }
}
