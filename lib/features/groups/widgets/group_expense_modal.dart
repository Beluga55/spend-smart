import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiptScannerSheet(
        onParsed: (data) {
          final total = data['total'];
          final date = data['date'];
          final merchant = data['merchant'];
          final items = data['items'];

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
          if (items != null && items is List) {
            // Store items for per-item split
            // They'll be passed when proceeding to split config
          }
        },

      ),
    );
  }

  void _proceedToSplit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SplitConfigurationScreen(
          groupId: widget.groupId,
          description: _descriptionController.text.trim(),
          totalAmount: amount,
          date: _selectedDate,
          paidByUserId: _paidByUserId ?? '',
          receiptItems: widget.receiptItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final dividerColor = Theme.of(context).colorScheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.addGroupExpense,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.note,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              decoration: InputDecoration(
                labelText: l10n.amount,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enterAmount;
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return l10n.enterValidAmount;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.date,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanReceipt,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Scan Receipt'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedToSplit,
                child: Text('${l10n.save} & ${l10n.splitConfiguration}'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}