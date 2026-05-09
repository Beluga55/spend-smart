import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/models/chat_message.dart';
import 'package:mobile_expense_tracker/core/providers/chat_provider.dart';
import 'package:mobile_expense_tracker/features/chat/widgets/chat_input_bar.dart';
import 'package:mobile_expense_tracker/features/chat/widgets/chat_message_bubble.dart';
import 'package:mobile_expense_tracker/features/chat/widgets/suggested_prompts.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final messages = ref.watch(chatProvider);
    final isLoading = ref.watch(chatLoadingProvider);
    final hasMessages = messages.isNotEmpty;

    ref.listen(chatProvider, (previous, next) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiChat),
        centerTitle: true,
        actions: [
          if (hasMessages)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.chatClearTitle,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.chatClearTitle),
                    content: Text(l10n.chatClearConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(chatProvider.notifier).clearChat();
                          Navigator.pop(context);
                        },
                        child: Text(l10n.chatClear),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: hasMessages
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isLast = index == messages.length - 1;
                      return ChatMessageBubble(
                        message: msg,
                        showLoading: isLast && msg.role == ChatRole.user && isLoading,
                      );
                    },
                  )
                : _buildEmptyState(),
          ),
          if (!hasMessages) const SuggestedPrompts(),
          ChatInputBar(
            onSend: (text) => ref.read(chatProvider.notifier).sendMessage(text),
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.chatWelcomeTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l10n.chatWelcomeSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
