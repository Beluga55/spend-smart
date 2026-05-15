import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/providers/group_expense_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class GroupBalancesScreen extends ConsumerWidget {
  final Group group;

  const GroupBalancesScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final balances = ref.watch(groupBalancesProvider(group.id));
    final members = ref.watch(groupMembersProvider(group.id));
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final currentUserId = SupabaseService.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.balances)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final balance = balances[member.userId ?? ''] ?? 0;
          final isCurrentUser = member.userId == currentUserId;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName + (isCurrentUser ? ' (You)' : ''),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balance == 0
                            ? 'Settled up'
                            : 'Owes \$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: balance == 0 ? Colors.green : Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (balance > 0 && !isCurrentUser)
                  ElevatedButton(
                    onPressed: () {
                      _settleMemberSplits(context, ref, member.userId ?? '');
                    },
                    child: Text(l10n.markAsSettled),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _settleMemberSplits(BuildContext context, WidgetRef ref, String userId) {
    final expenses = ref.read(groupExpensesProvider(group.id));
    final splitBox = ref.read(groupExpenseSplitBoxProvider);

    for (final expense in expenses) {
      final splits = splitBox.values.where((s) => s.groupExpenseId == expense.id && s.userId == userId && !s.isSettled);
      for (final split in splits) {
        ref.read(groupExpenseSplitsProvider(expense.id).notifier).settleSplit(split.id);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as settled')),
    );
  }
}
