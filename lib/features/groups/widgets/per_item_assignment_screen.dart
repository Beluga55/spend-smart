import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class PerItemAssignmentScreen extends ConsumerStatefulWidget {
  final String groupId;
  final double totalAmount;
  final List<Map<String, dynamic>> items;

  const PerItemAssignmentScreen({
    super.key,
    required this.groupId,
    required this.totalAmount,
    required this.items,
  });

  @override
  ConsumerState<PerItemAssignmentScreen> createState() =>
      _PerItemAssignmentScreenState();
}

class _PerItemAssignmentScreenState
    extends ConsumerState<PerItemAssignmentScreen> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    for (final item in _items) {
      if (!item.containsKey('assignedTo')) {
        item['assignedTo'] = <String>[];
      }
    }
  }

  double get _assignedTotal {
    double total = 0;
    for (final item in _items) {
      final assigned = List<String>.from(item['assignedTo'] as List);
      if (assigned.isNotEmpty) {
        total += item['amount'] as double;
      }
    }
    return total;
  }

  double get _unassignedAmount => widget.totalAmount - _assignedTotal;

  void _distributeRemaining() {
    final members = ref.read(groupMembersProvider(widget.groupId));
    final memberIds = members.map((m) => m.userId ?? m.id).toList();

    setState(() {
      for (final item in _items) {
        final assigned = List<String>.from(item['assignedTo'] as List);
        if (assigned.isEmpty) {
          item['assignedTo'] = List<String>.from(memberIds);
        }
      }
    });
  }

  void _toggleAssignment(int itemIndex, String memberId) {
    setState(() {
      final assigned = List<String>.from(
        _items[itemIndex]['assignedTo'] as List,
      );
      if (assigned.contains(memberId)) {
        assigned.remove(memberId);
      } else {
        assigned.add(memberId);
      }
      _items[itemIndex]['assignedTo'] = assigned;
    });
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
          l10n.perItem,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _items),
            child: Text(
              l10n.save,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.unassignedAmount,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_unassignedAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _unassignedAmount == 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                if (_unassignedAmount > 0)
                  ElevatedButton(
                    onPressed: _distributeRemaining,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.distributeRemaining,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final assigned = List<String>.from(item['assignedTo'] as List);
                final isAssigned = assigned.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAssigned
                          ? theme.colorScheme.outlineVariant
                          : theme.colorScheme.error.withAlpha(100),
                      width: isAssigned ? 1 : 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['description'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '\$${(item['amount'] as double).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Assigned to:',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: members.map((member) {
                          final memberId = member.userId ?? member.id;
                          final isSelected = assigned.contains(memberId);
                          return FilterChip(
                            label: Text(member.displayName),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : textPrimary,
                            ),
                            selected: isSelected,
                            onSelected: (_) =>
                                _toggleAssignment(index, memberId),
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            selectedColor: theme.colorScheme.primary,
                            checkmarkColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide.none,
                            ),
                            elevation: 0,
                            pressElevation: 0,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
