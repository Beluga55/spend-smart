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
  ConsumerState<PerItemAssignmentScreen> createState() => _PerItemAssignmentScreenState();
}

class _PerItemAssignmentScreenState extends ConsumerState<PerItemAssignmentScreen> {
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map((item) => Map<String, dynamic>.from(item)).toList();
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
      final assigned = List<String>.from(_items[itemIndex]['assignedTo'] as List);
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
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final dividerColor = Theme.of(context).colorScheme.outline;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.perItem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _items),
            child: Text(l10n.save),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.unassignedAmount, style: TextStyle(color: textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '\$${_unassignedAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _unassignedAmount == 0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (_unassignedAmount > 0)
                  ElevatedButton(
                    onPressed: _distributeRemaining,
                    child: Text(l10n.distributeRemaining),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final assigned = List<String>.from(item['assignedTo'] as List);
                final isAssigned = assigned.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isAssigned ? dividerColor : Colors.orange),
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
                              style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary),
                            ),
                          ),
                          Text(
                            '\$${(item['amount'] as double).toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: members.map((member) {
                          final memberId = member.userId ?? member.id;
                          final isSelected = assigned.contains(memberId);
                          return FilterChip(
                            label: Text(member.displayName),
                            selected: isSelected,
                            onSelected: (_) => _toggleAssignment(index, memberId),
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