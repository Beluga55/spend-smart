import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/chat_provider.dart';

class SuggestedPrompts extends ConsumerWidget {
  const SuggestedPrompts({super.key});

  static final List<String> _prompts = [
    'How much did I spend this month?',
    'What\'s my biggest expense?',
    r'Add $10 lunch, $5 coffee, $20 groceries',
    'Create a new category called Travel',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _prompts.map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  prompt,
                  style: TextStyle(fontSize: 13, color: colorScheme.primary),
                ),
                backgroundColor: colorScheme.primary.withAlpha(15),
                side: BorderSide(color: colorScheme.primary.withAlpha(40)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () {
                  ref.read(chatProvider.notifier).sendMessage(prompt);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
