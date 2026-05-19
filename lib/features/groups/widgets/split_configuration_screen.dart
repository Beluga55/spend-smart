import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_item.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/providers/group_expense_provider.dart';
import 'package:mobile_expense_tracker/core/services/group_sync_service.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/per_item_assignment_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

enum SplitType { equal, custom, perItem }

class SplitConfigurationScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String description;
  final double totalAmount;
  final DateTime date;
  final String paidByUserId;
  final List<Map<String, dynamic>>? receiptItems;

  const SplitConfigurationScreen({
    super.key,
    required this.groupId,
    required this.description,
    required this.totalAmount,
    required this.date,
    required this.paidByUserId,
    this.receiptItems,
  });

  @override
  ConsumerState<SplitConfigurationScreen> createState() =>
      _SplitConfigurationScreenState();
}

class _SplitConfigurationScreenState
    extends ConsumerState<SplitConfigurationScreen> {
  SplitType _splitType = SplitType.equal;
  final Map<String, double> _customAmounts = {};
  List<Map<String, dynamic>> _assignedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.receiptItems != null) {
      _assignedItems = List.from(widget.receiptItems!);
    }
  }

  double get _currentTotal {
    if (_splitType == SplitType.equal) {
      return widget.totalAmount;
    } else if (_splitType == SplitType.custom) {
      return _customAmounts.values.fold(0, (sum, a) => sum + a);
    } else {
      return _assignedItems.fold(
        0,
        (sum, item) => sum + (item['amount'] as double),
      );
    }
  }

  bool get _isValid {
    if (_splitType == SplitType.perItem) {
      return _currentTotal == widget.totalAmount;
    }
    return (_currentTotal - widget.totalAmount).abs() < 0.01;
  }

  Future<void> _save() async {
    if (!_isValid) return;

    final members = ref.read(groupMembersProvider(widget.groupId));
    final now = DateTime.now();
    final groupExpenseId = const Uuid().v4();

    final groupExpense = GroupExpense(
      id: groupExpenseId,
      groupId: widget.groupId,
      description: widget.description,
      totalAmount: widget.totalAmount,
      date: widget.date,
      paidByUserId: widget.paidByUserId,
      syncStatus: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    await ref
        .read(groupExpensesProvider(widget.groupId).notifier)
        .addExpense(groupExpense);

    if (_splitType == SplitType.equal) {
      final sharePerMember = widget.totalAmount / members.length;
      final splitNotifier = ref.read(
        groupExpenseSplitsProvider(groupExpenseId).notifier,
      );
      for (final member in members) {
        final isPayer = (member.userId ?? member.id) == widget.paidByUserId;
        final split = GroupExpenseSplit(
          id: const Uuid().v4(),
          groupExpenseId: groupExpenseId,
          userId: member.userId ?? member.id,
          amount: sharePerMember,
          isSettled: isPayer,
          updatedAt: now,
        );
        await splitNotifier.addSplit(split);
      }
    } else if (_splitType == SplitType.custom) {
      final splitNotifier = ref.read(
        groupExpenseSplitsProvider(groupExpenseId).notifier,
      );
      for (final entry in _customAmounts.entries) {
        final isPayer = entry.key == widget.paidByUserId;
        final split = GroupExpenseSplit(
          id: const Uuid().v4(),
          groupExpenseId: groupExpenseId,
          userId: entry.key,
          amount: entry.value,
          isSettled: isPayer,
          updatedAt: now,
        );
        await splitNotifier.addSplit(split);
      }
    } else if (_splitType == SplitType.perItem) {
      final memberShares = <String, double>{};
      final itemNotifier = ref.read(
        groupExpenseItemsProvider(groupExpenseId).notifier,
      );
      for (final item in _assignedItems) {
        final amount = item['amount'] as double;
        final assignedIds = List<String>.from(item['assignedTo'] as List);
        if (assignedIds.isNotEmpty) {
          final share = amount / assignedIds.length;
          for (final id in assignedIds) {
            memberShares[id] = (memberShares[id] ?? 0) + share;
          }
        }
        final itemModel = GroupExpenseItem(
          id: const Uuid().v4(),
          groupExpenseId: groupExpenseId,
          description: item['description'] as String,
          amount: amount,
          assignedToUserIds: assignedIds,
          updatedAt: now,
        );
        await itemNotifier.addItem(itemModel);
      }
      final splitNotifier = ref.read(
        groupExpenseSplitsProvider(groupExpenseId).notifier,
      );
      for (final entry in memberShares.entries) {
        final isPayer = entry.key == widget.paidByUserId;
        final split = GroupExpenseSplit(
          id: const Uuid().v4(),
          groupExpenseId: groupExpenseId,
          userId: entry.key,
          amount: entry.value,
          isSettled: isPayer,
          updatedAt: now,
        );
        await splitNotifier.addSplit(split);
      }
    }

    // Create personal expense for the payer (full amount they paid)
    final categoryBox = Hive.box<Category>('categories');
    final expenseCategory = categoryBox.values.firstWhere(
      (c) => c.effectiveType == 'expense',
      orElse: () => Category(
        id: '',
        name: 'Other',
        iconName: 'help_outline',
        color: 0xFF999999,
        isDefault: true,
        categoryType: 'expense',
      ),
    );
    final categoryId = expenseCategory.id.isEmpty
        ? 'unknown'
        : expenseCategory.id;

    final payerExpense = Expense(
      id: const Uuid().v4(),
      amount: widget.totalAmount,
      categoryId: categoryId,
      date: widget.date,
      note: '[Group] ${widget.description}',
      createdAt: now,
      groupId: widget.groupId,
      groupExpenseId: groupExpenseId,
    );
    await Hive.box<Expense>('expenses').put(payerExpense.id, payerExpense);

    // Navigate back immediately - local data is already saved
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.groupExpenseSaved),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Push to Supabase in background (don't block UI)
    final sync = ref.read(groupSyncServiceProvider);

    final allSplits = ref
        .read(groupExpenseSplitBoxProvider)
        .values
        .where((s) => s.groupExpenseId == groupExpenseId);
    for (final split in allSplits) {
      await sync.pushSplit(split);
    }

    final items = ref
        .read(groupExpenseItemBoxProvider)
        .values
        .where((i) => i.groupExpenseId == groupExpenseId);
    for (final item in items) {
      await sync.pushItem(item);
    }
  }

  void _goToPerItem() async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (context) => PerItemAssignmentScreen(
          groupId: widget.groupId,
          totalAmount: widget.totalAmount,
          items: widget.receiptItems ?? [],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _assignedItems = result;
        _splitType = SplitType.perItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(groupMembersProvider(widget.groupId));
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.splitConfiguration,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.receipt_long,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                          Text(
                            'Total: \$${widget.totalAmount.toStringAsFixed(2)}',
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
              const SizedBox(height: 24),
              Text(
                'Split Method',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<SplitType>(
                style: SegmentedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                segments: [
                  ButtonSegment(
                    value: SplitType.equal,
                    label: Text(
                      l10n.equalSplit,
                      style: const TextStyle(fontSize: 13),
                    ),
                    icon: const Icon(Icons.balance),
                  ),
                  ButtonSegment(
                    value: SplitType.custom,
                    label: Text(
                      l10n.customAmounts,
                      style: const TextStyle(fontSize: 13),
                    ),
                    icon: const Icon(Icons.edit_note),
                  ),
                  if (widget.receiptItems != null)
                    ButtonSegment(
                      value: SplitType.perItem,
                      label: Text(
                        l10n.perItem,
                        style: const TextStyle(fontSize: 13),
                      ),
                      icon: const Icon(Icons.list_alt),
                    ),
                ],
                selected: {_splitType},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    setState(() => _splitType = set.first);
                    if (set.first == SplitType.perItem) {
                      _goToPerItem();
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _splitType == SplitType.equal
                    ? ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final m = members[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  m.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '\$${(widget.totalAmount / members.length).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : _splitType == SplitType.custom
                    ? ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final m = members[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                labelText: m.displayName,
                                filled: true,
                                fillColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.attach_money),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _customAmounts[m.userId ?? m.id] =
                                      double.tryParse(value) ?? 0;
                                });
                              },
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_assignedItems.length} items assigned',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _goToPerItem,
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(l10n.perItem),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (!_isValid)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.totalDoesNotMatch,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isValid ? _save : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.save,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
