import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/features/expenses/widgets/receipt_scanner_sheet.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/split_configuration_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class GroupExpenseModal extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialDescription;
  final double? initialAmount;
  final DateTime? initialDate;
  final List<Map<String, dynamic>>? receiptItems;

  const GroupExpenseModal({
    super.key,
    required this.groupId,
    this.initialDescription,
    this.initialAmount,
    this.initialDate,
    this.receiptItems,
  });

  @override
  ConsumerState<GroupExpenseModal> createState() => _GroupExpenseModalState();
}

class _GroupExpenseModalState extends ConsumerState<GroupExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late DateTime _selectedDate;
  String? _paidByUserId;

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.initialDescription ?? '';
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toString();
    }
    _selectedDate = widget.initialDate ?? DateTime.now();
    _paidByUserId = SupabaseService.client.auth.currentUser?.id;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _scanReceipt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiptScannerSheet(
        onParsed: (data) {
          final total = data['total'];
          final date = data['date'];
          final merchant = data['merchant'];

          if (total != null && total is num) {
            _amountController.text = total.toStringAsFixed(2);
          }
          if (date != null && date is String) {
            try {
              _selectedDate = DateTime.parse(date);
            } catch (_) {}
          }
          if (merchant != null && merchant is String) {
            _descriptionController.text = merchant;
          }
        },
      ),
    );
  }

  void _proceedToSplit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final paidBy =
        _paidByUserId ?? SupabaseService.client.auth.currentUser?.id ?? '';
    if (paidBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSignInForGroups),
        ),
      );
      return;
    }

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplitConfigurationScreen(
          groupId: widget.groupId,
          description: _descriptionController.text.trim(),
          totalAmount: amount,
          date: _selectedDate,
          paidByUserId: paidBy,
          receiptItems: widget.receiptItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;
    final dividerColor = theme.colorScheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dividerColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.addGroupExpense,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: l10n.note,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterAmount;
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return l10n.enterValidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('MMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final members = ref.watch(
                    groupMembersProvider(widget.groupId),
                  );
                  final currentUser = SupabaseService.client.auth.currentUser;
                  return DropdownButtonFormField<String>(
                    value: _paidByUserId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: l10n.paidBy,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.person_pin_rounded),
                    ),
                    items: members.map((m) {
                      final isYou = m.userId == currentUser?.id;
                      return DropdownMenuItem(
                        value: m.userId ?? m.id,
                        child: Text(
                          m.displayName + (isYou ? ' (${l10n.you})' : ''),
                          style: TextStyle(color: textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _paidByUserId = val),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _scanReceipt,
                  icon: const Icon(Icons.document_scanner_rounded),
                  label: const Text(
                    'Scan Receipt',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundColor: theme.colorScheme.onSecondaryContainer,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedToSplit,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '${l10n.save} & ${l10n.splitConfiguration}',
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
