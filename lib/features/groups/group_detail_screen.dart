import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/providers/group_expense_provider.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/group_expense_modal.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/group_balances_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class GroupDetailScreen extends ConsumerWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expenses = ref.watch(groupExpensesProvider(group.id));
    final members = ref.watch(groupMembersProvider(group.id));
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final dividerColor = Theme.of(context).colorScheme.outline;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupBalancesScreen(group: group),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.members,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${members.length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.expenses,
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expenses.length}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Text(
                      'No group expenses yet',
                      style: TextStyle(color: textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expense.description,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    expense.date.toString().split(' ')[0],
                                    style: TextStyle(color: textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${expense.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'group_expense_fab',
        onPressed: () => _showAddExpenseModal(context, group.id),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, String groupId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupExpenseModal(groupId: groupId),
    );
  }
}
