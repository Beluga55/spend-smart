import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/providers/group_expense_provider.dart';
import 'package:mobile_expense_tracker/core/services/group_sync_service.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class GroupBalancesScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupBalancesScreen({super.key, required this.group});

  @override
  ConsumerState<GroupBalancesScreen> createState() =>
      _GroupBalancesScreenState();
}

class _GroupBalancesScreenState extends ConsumerState<GroupBalancesScreen> {
  final Set<String> _settling = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final balances = ref.watch(groupBalancesProvider(widget.group.id));
    final members = ref.watch(groupMembersProvider(widget.group.id));
    final currentUserId = SupabaseService.client.auth.currentUser?.id;
    final currentUserBalance = balances[currentUserId ?? ''] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.balances), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          final userId = member.userId ?? '';
          final balance = balances[userId] ?? 0;
          final isCurrentUser = userId == currentUserId;
          final isSettling = _settling.contains(userId);

          Color balanceColor;
          String balanceLabel;
          IconData balanceIcon;
          final theme = Theme.of(context);
          if (balance == 0) {
            balanceColor = theme.colorScheme.onSurfaceVariant;
            balanceLabel = l10n.settledUp;
            balanceIcon = Icons.check_circle_outline;
          } else if (balance > 0) {
            balanceColor = theme.colorScheme.primary;
            balanceLabel = '${l10n.isOwed} \$${balance.toStringAsFixed(2)}';
            balanceIcon = Icons.arrow_downward_rounded;
          } else {
            balanceColor = theme.colorScheme.error;
            balanceLabel = '${l10n.owes} \$${balance.abs().toStringAsFixed(2)}';
            balanceIcon = Icons.arrow_upward_rounded;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isCurrentUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondaryContainer,
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: isCurrentUser
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName +
                              (isCurrentUser ? ' (${l10n.you})' : ''),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(balanceIcon, size: 14, color: balanceColor),
                            const SizedBox(width: 4),
                            Text(
                              balanceLabel,
                              style: TextStyle(
                                color: balanceColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (balance < 0 && !isCurrentUser && currentUserBalance > 0)
                    isSettling
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : FilledButton.tonal(
                            onPressed: () =>
                                _settleMemberSplits(context, userId),
                            child: Text(
                              l10n.markAsSettled,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _settleMemberSplits(BuildContext context, String userId) async {
    setState(() => _settling.add(userId));

    final expenses = ref.read(groupExpensesProvider(widget.group.id));
    final splitBox = ref.read(groupExpenseSplitBoxProvider);
    const sync = GroupSyncService();
    double totalSettled = 0;

    for (final expense in expenses) {
      final splits = splitBox.values
          .where(
            (s) =>
                s.groupExpenseId == expense.id &&
                s.userId == userId &&
                !s.isSettled,
          )
          .toList();

      for (final split in splits) {
        totalSettled += split.amount;
        await ref
            .read(groupExpenseSplitsProvider(expense.id).notifier)
            .settleSplit(split.id);
        final updated = splitBox.get(split.id);
        if (updated != null) {
          await sync.pushSplit(updated);
        }
      }
    }

    // Record Income for the creditor (current user gets money back)
    if (totalSettled > 0) {
      final now = DateTime.now();
      final income = Income(
        id: const Uuid().v4(),
        amount: totalSettled,
        source: 'Group Settlement',
        date: now,
        note: '[Group Settlement] ${widget.group.name}',
        createdAt: now,
      );
      await Hive.box<Income>('incomes').put(income.id, income);
    }

    setState(() => _settling.remove(userId));

    if (context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settlementRecorded),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
