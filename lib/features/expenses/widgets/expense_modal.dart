import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class ExpenseModal extends ConsumerStatefulWidget {
  final Expense? expense;
  final Function(double amount, String categoryId, DateTime date, String? note)
  onSave;
  final VoidCallback? onDelete;

  const ExpenseModal({
    super.key,
    this.expense,
    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<ExpenseModal> createState() => _ExpenseModalState();
}

class _ExpenseModalState extends ConsumerState<ExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedCategoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.amount.toStringAsFixed(2) ?? '',
    );
    _noteController = TextEditingController(text: widget.expense?.note ?? '');
    _selectedDate = widget.expense?.date ?? DateTime.now();

    final categories = ref.read(expenseCategoriesProvider);
    _selectedCategoryId = widget.expense?.categoryId ?? categories.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(expenseCategoriesProvider);
    final isEditing = widget.expense != null;

    final surfaceColor = isDark
        ? AppTheme.darkSurfaceColor
        : AppTheme.surfaceColor;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.textPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.textSecondary;
    final backgroundColor = isDark
        ? AppTheme.darkBackgroundColor
        : AppTheme.backgroundColor;
    final dividerColor = isDark
        ? AppTheme.darkDividerColor
        : AppTheme.dividerColor;
    final errorColor = isDark ? Colors.white : AppTheme.errorColor;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? l10n.editExpense : l10n.addExpense,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  if (isEditing && widget.onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: errorColor),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onDelete!();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.amount,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: textPrimary),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  hintText: '0.00',
                  filled: true,
                  fillColor: backgroundColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.enterAmount;
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0)
                    return l10n.enterValidAmount;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                l10n.selectCategory,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(),
                menuMaxHeight: 300,
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(cat.color).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            IconConstants.getIcon(cat.iconName),
                            color: Color(cat.color),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedCategoryId = value);
                },
              ),
              const SizedBox(height: 20),
              Text(
                l10n.date,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM d, yyyy').format(_selectedDate),
                        style: TextStyle(color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.noteOptional,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.addANote,
                  filled: true,
                  fillColor: backgroundColor,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  child: Text(isEditing ? l10n.updateBudget : l10n.addExpense),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month + 1, now.day),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      widget.onSave(amount, _selectedCategoryId, _selectedDate, note);
      Navigator.pop(context);
    }
  }
}
