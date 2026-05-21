import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/services/group_realtime_service.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/core/providers/group_expense_provider.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/utils/design_utils.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/group_expense_modal.dart';
import 'package:mobile_expense_tracker/features/groups/group_settings_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: l10n.showInviteCode,
            onPressed: () => _showQrDialog(context, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.groupSettings,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GroupSettingsScreen(group: widget.group),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: l10n.expenses),
            Tab(text: l10n.balances),
            Tab(text: l10n.members),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ExpensesTab(group: widget.group),
          _BalancesTab(group: widget.group),
          _MembersTab(group: widget.group),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              heroTag: 'group_expense_fab',
              onPressed: () => _showAddExpenseModal(context, widget.group.id),
              icon: const Icon(Icons.add),
              label: Text(l10n.expenses),
            )
          : null,
    );
  }

  void _showQrDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.showInviteCode, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: widget.group.inviteCode,
                  size: 160,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.group.inviteCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      color: Theme.of(ctx).colorScheme.onSurface,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.group.inviteCode),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.copiedToClipboard),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, String groupId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupExpenseModal(groupId: groupId),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}

class _ExpensesTab extends ConsumerWidget {
  final Group group;
  const _ExpensesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final expenses = ref.watch(groupExpensesProvider(group.id));
    final members = ref.watch(groupMembersProvider(group.id));
    final textSecondary = Theme.of(context).colorScheme.onSurfaceVariant;

    final memberNameMap = {
      for (final m in members) m.userId ?? m.id: m.displayName,
    };

    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: textSecondary),
            const SizedBox(height: 16),
            Text(
              l10n.noGroupExpensesYet,
              style: TextStyle(color: textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final payerName =
            memberNameMap[expense.paidByUserId] ?? expense.paidByUserId;
        return _ExpenseCard(
          expense: expense,
          payerName: payerName,
          l10n: l10n,
          onDelete: () => _confirmDeleteExpense(context, ref, expense),
        );
      },
    );
  }

  void _confirmDeleteExpense(
    BuildContext context,
    WidgetRef ref,
    GroupExpense expense,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteGroupExpense),
        content: Text(l10n.deleteGroupExpenseConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteExpense(context, ref, expense.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(
    BuildContext context,
    WidgetRef ref,
    String expenseId,
  ) async {
    try {
      // Provider deletes from local and syncs to Supabase
      await ref
          .read(groupExpensesProvider(group.id).notifier)
          .deleteExpense(expenseId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.groupExpenseDeleted),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[GroupDetail] Failed to delete expense: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.syncFailed}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      rethrow;
    }
  }
}

class _BalancesTab extends ConsumerWidget {
  final Group group;
  const _BalancesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final balances = ref.watch(groupBalancesProvider(group.id));
    final members = ref.watch(groupMembersProvider(group.id));
    final currentUserId = SupabaseService.currentUser?.id;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    if (members.isEmpty) return const SizedBox.shrink();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final userId = member.userId ?? member.id;
        final balance = balances[userId] ?? 0.0;
        final isYou = userId == currentUserId;
        final memberColor = DesignUtils.getColorFromId(userId);
        final positiveColor = theme.colorScheme.primary;
        final negativeColor = theme.colorScheme.error;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outline.withAlpha(100)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: memberColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: memberColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.displayName + (isYou ? ' (${l10n.you})' : ''),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        balance > 0
                            ? 'is owed \$${balance.toStringAsFixed(2)}'
                            : balance < 0
                            ? 'owes \$${balance.abs().toStringAsFixed(2)}'
                            : 'settled up',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: balance > 0
                              ? positiveColor
                              : balance < 0
                              ? negativeColor
                              : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isYou && balance != 0)
                  ElevatedButton(
                    onPressed: () =>
                        _showSettleDialog(context, ref, member, balance),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Settle',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettleDialog(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
    double balance,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final amt = balance.abs().toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settleUp),
        content: Text(
          balance < 0
              ? l10n.settleUpConfirmPayBack(member.displayName, amt)
              : l10n.settleUpConfirmPay(member.displayName, amt),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _settleAllBetween(ref, member);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _settleAllBetween(WidgetRef ref, GroupMember otherMember) async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) return;

    final expenses = ref.read(groupExpensesProvider(group.id));
    final now = DateTime.now();

    for (final expense in expenses) {
      final splits = ref.read(groupExpenseSplitsProvider(expense.id));
      for (final split in splits) {
        if (split.isSettled) continue;

        bool shouldSettle = false;
        if (expense.paidByUserId == currentUserId &&
            split.userId == otherMember.userId) {
          shouldSettle = true;
        } else if (expense.paidByUserId == otherMember.userId &&
            split.userId == currentUserId) {
          shouldSettle = true;
        }

        if (shouldSettle) {
          await ref
              .read(groupExpenseSplitsProvider(expense.id).notifier)
              .settleSplit(split.id);

          // Record local settlement transaction immediately
          _recordLocalSettlement(expense, split, currentUserId, now);
        }
      }
    }
  }

  void _recordLocalSettlement(
    GroupExpense expense,
    GroupExpenseSplit split,
    String currentUserId,
    DateTime now,
  ) {
    // Case 1: Current user is the debtor - record as expense
    if (split.userId == currentUserId &&
        expense.paidByUserId != currentUserId) {
      final settlementNote = '[Settlement] ${split.id}';
      final personalExpenseBox = Hive.box<Expense>('expenses');

      // Check if already recorded
      if (personalExpenseBox.values.any((e) => e.note == settlementNote)) {
        return;
      }

      final categoryBox = Hive.box<Category>('categories');
      final expCat = categoryBox.values.firstWhere(
        (c) => c.effectiveType == 'expense',
        orElse: () => Category(
          id: 'unknown',
          name: 'Other',
          iconName: 'help_outline',
          color: 0xFF9E9E9E,
          isDefault: true,
          categoryType: 'expense',
        ),
      );

      final settleExpense = Expense(
        id: const Uuid().v4(),
        amount: split.amount,
        categoryId: expCat.id.isEmpty ? 'unknown' : expCat.id,
        date: now,
        note: settlementNote,
        createdAt: now,
        groupId: expense.groupId,
        groupExpenseId: split.groupExpenseId,
      );
      personalExpenseBox.put(settleExpense.id, settleExpense);
      debugPrint(
        '[GroupDetail] Recorded local debtor settlement: ${split.amount}',
      );
    }

    // Case 2: Current user is the creditor - record as income
    if (expense.paidByUserId == currentUserId &&
        split.userId != currentUserId) {
      final incomeNote = '[Settlement Received] ${split.id}';
      debugPrint(
        '[GroupDetail] Looking to record income with note: $incomeNote',
      );
      final incomeBox = Hive.box<Income>('incomes');

      // Check if already recorded
      if (incomeBox.values.any((i) => i.note == incomeNote)) {
        debugPrint('[GroupDetail] Income already recorded, skipping');
        return;
      }

      final income = Income(
        id: const Uuid().v4(),
        amount: split.amount,
        source: 'Group Settlement',
        date: split.settledAt ?? now,
        note: incomeNote,
        createdAt: now,
        groupExpenseId:
            split.groupExpenseId, // Key: link to expense for deletion
      );
      incomeBox.put(income.id, income);
      debugPrint(
        '[GroupDetail] Recorded local creditor settlement income: ${income.id} with note: $incomeNote, groupExpenseId: ${split.groupExpenseId}',
      );
    }
  }
}

class _MembersTab extends ConsumerWidget {
  final Group group;
  const _MembersTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider(group.id));
    final currentUserId = SupabaseService.currentUser?.id;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isYou = member.userId == currentUserId;
        final isAdmin = member.role == 'admin';
        final memberColor = DesignUtils.getColorFromId(
          member.userId ?? member.id,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outline.withAlpha(100)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: memberColor.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: memberColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isYou)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAdmin ? 'Administrator' : 'Member',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isYou)
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20),
                    color: theme.colorScheme.error,
                    onPressed: () => _confirmLeaveGroup(context, ref, member),
                  )
                else if (isAdmin)
                  Icon(
                    Icons.verified_user,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmLeaveGroup(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveGroup),
        content: Text(l10n.leaveGroupConfirm(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _leaveGroup(context, ref, member);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.leave),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final groupId = group.id;
    final members = ref.read(groupMembersProvider(groupId));
    final activeMembersCount = members.where((m) => m.isActive).length;

    final isLastMember = activeMembersCount <= 1;

    if (isLastMember) {
      try {
        await SupabaseService.client.from('groups').delete().eq('id', groupId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.syncFailed}: $e'),
            ),
          );
          return;
        }
      }
    } else {
      await ref
          .read(groupMembersProvider(groupId).notifier)
          .removeMember(member.id);
    }

    await ref.read(groupsProvider.notifier).deleteGroup(groupId);
    GroupRealtimeService.instance.refreshGroupList();

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}

class _ExpenseCard extends StatelessWidget {
  final GroupExpense expense;
  final String payerName;
  final AppLocalizations l10n;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.payerName,
    required this.l10n,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final expenseColor = DesignUtils.getColorFromId(expense.id);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
      ),
      confirmDismiss: (_) async {
        // Wait for delete to complete before allowing dismiss
        try {
          onDelete();
          // Return true to allow the card to animate away
          return true;
        } catch (e) {
          debugPrint('[ExpenseCard] Delete failed: $e');
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outline.withAlpha(100)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Expense detail
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: expenseColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: expenseColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.paidBy} $payerName · ${DateFormat('MMM d').format(expense.date)}',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${expense.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    if (expense.syncStatus == 'pending')
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 12,
                          color: textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
