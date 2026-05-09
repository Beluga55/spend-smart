import 'package:flutter/material.dart';
import 'package:mobile_expense_tracker/core/models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showLoading;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.showLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (showLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isUser
                              ? colorScheme.onPrimary.withAlpha(180)
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (message.action != null)
              _buildActionCard(context, message.action!),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, ChatAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData icon;
    String label;
    Color color;

    switch (action.type) {
      case 'create_expense':
        icon = Icons.remove_circle_outline;
        label = 'Expense created';
        color = Colors.red;
        break;
      case 'create_income':
        icon = Icons.add_circle_outline;
        label = 'Income created';
        color = Colors.green;
        break;
      case 'create_category':
        icon = Icons.folder_open;
        label = 'Category created';
        color = Colors.blue;
        break;
      default:
        icon = Icons.info_outline;
        label = 'Action';
        color = colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(top: 6, left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
