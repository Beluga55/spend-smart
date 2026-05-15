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
  ConsumerState<SplitConfigurationScreen> createState() => _SplitConfigurationScreenState();
}

class _SplitConfigurationScreenState extends ConsumerState<SplitConfigurationScreen> {
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
      return _assignedItems.fold(0, (sum, item) => sum + (item['amount'] as double));
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

    await ref.read(groupExpensesProvider(widget.groupId).notifier).addExpense(groupExpense);

    if (_splitType == SplitType.equal) {
      final share = widget.totalAmount / members.length;
      for (final member in members) {
        final split = GroupExpenseSplit(
          id: const Uuid().v4(),
          groupExpenseId: groupExpenseId,
          userId: member.userId ?? member.id,
          amount: share,
          isSettled: member.userId == widget.paidByUserId,
          updatedAt: now,
        );
        await ref.read(groupExpenseSplitBoxProvider).put(split.id, split);
      }
    } else if (_splitType == SplitType.custom) {
      for (final entry in _customAmounts.entries) {
        final split = GroupExpenseSplit(
          id: const Uuid().v4(),
          groupExpenseId: groupExpenseId,
          userId: entry.key,
          amount: entry.value,
          isSettled: entry.key == widget.paidByUserId,
          updatedAt: now,
        );
        await ref.read(groupExpenseSplitBoxProvider).put(split.id, split);
      }
    } else if (_splitType == SplitType.perItem) {
      final memberShares = <String, double>{};
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
        await ref.read(groupExpenseItemBoxProvider).put(itemModel.id, itemModel);
      }
      for (final entry in memberShares.entries) {
        final split = GroupExpenseSplit(
          id: const Uuid().v4(),
          groupExpenseId: groupExpenseId,
          userId: entry.key,
          amount: entry.value,
          isSettled: entry.key == widget.paidByUserId,
          updatedAt: now,
        );
        await ref.read(groupExpenseSplitBoxProvider).put(split.id, split);
      }
    }

    // Create personal expenses for each member
    final categoryBox = Hive.box<Category>('categories');
    final expenseCategory = categoryBox.values.firstWhere(
      (c) => c.effectiveType == 'expense',
      orElse: () => Category(id: '', name: 'Other', iconName: 'help_outline', color: 0xFF999999, isDefault: true, categoryType: 'expense'),
    );
    final categoryId = expenseCategory.id.isEmpty ? 'unknown' : expenseCategory.id;

    final splits = ref.read(groupExpenseSplitBoxProvider).values.where((s) => s.groupExpenseId == groupExpenseId);
    for (final split in splits) {
      final expense = Expense(
        id: const Uuid().v4(),
        amount: split.amount,
        categoryId: categoryId,
        date: widget.date,
        note: '[Group] ${widget.description}',
        createdAt: now,
        groupId: widget.groupId,
        groupExpenseId: groupExpenseId,
      );
      await Hive.box<Expense>('expenses').put(expense.id, expense);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group expense saved')),
      );
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
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.splitConfiguration)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: \$${widget.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 16),
            SegmentedButton<SplitType>(
              segments: [
                ButtonSegment(value: SplitType.equal, label: Text(l10n.equalSplit)),
                ButtonSegment(value: SplitType.custom, label: Text(l10n.customAmounts)),
                if (widget.receiptItems != null)
                  ButtonSegment(value: SplitType.perItem, label: Text(l10n.perItem)),
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
            if (_splitType == SplitType.equal) ...[
              ...members.map((m) => ListTile(
                title: Text(m.displayName),
                trailing: Text('\$${(widget.totalAmount / members.length).toStringAsFixed(2)}'),
              )),
            ] else if (_splitType == SplitType.custom) ...[
              ...members.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: m.displayName,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixText: '\$',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customAmounts[m.userId ?? m.id] = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                );
              }),
            ] else if (_splitType == SplitType.perItem) ...[
              Text(
                '${_assignedItems.length} items assigned',
                style: TextStyle(color: textSecondary),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _goToPerItem,
                child: Text(l10n.perItem),
              ),
            ],
            if (!_isValid)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l10n.totalDoesNotMatch,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid ? _save : null,
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}