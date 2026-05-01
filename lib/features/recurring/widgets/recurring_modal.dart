import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/models/recurring_expense.dart';

class RecurringModal extends ConsumerStatefulWidget {
  final RecurringExpense? recurring;
  final Function(double amount, String categoryId, RecurringFrequency frequency, DateTime startDate, String? note, DateTime? endDate) onSave;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;

  const RecurringModal({
    super.key,
    this.recurring,
    required this.onSave,
    this.onToggleActive,
    this.onDelete,
  });

  @override
  ConsumerState<RecurringModal> createState() => _RecurringModalState();
}

class _RecurringModalState extends ConsumerState<RecurringModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedCategoryId;
  late RecurringFrequency _selectedFrequency;
  late DateTime _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.recurring?.amount.toStringAsFixed(2) ?? '',
    );
    _noteController = TextEditingController(text: widget.recurring?.note ?? '');
    _selectedFrequency = widget.recurring?.frequency ?? RecurringFrequency.monthly;
    _selectedStartDate = widget.recurring?.startDate ?? DateTime.now();
    _selectedEndDate = widget.recurring?.endDate;

    final categories = ref.read(categoriesProvider);
    _selectedCategoryId = widget.recurring?.categoryId ?? categories.first.id;
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
    final categories = ref.watch(categoriesProvider);
    final isEditing = widget.recurring != null;

    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final dividerColor = isDark ? AppTheme.darkDividerColor : AppTheme.dividerColor;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Recurring' : 'Add Recurring',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildAmountInput(textPrimary, textSecondary, backgroundColor, dividerColor),
              const SizedBox(height: 20),
              _buildCategorySelector(categories, textPrimary, textSecondary),
              const SizedBox(height: 24),
              Text(
                'Frequency',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
              ),
              const SizedBox(height: 12),
              _buildFrequencySelector(textPrimary, textSecondary, backgroundColor, dividerColor),
              const SizedBox(height: 24),
              Text(
                'Start Date',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
              ),
              const SizedBox(height: 10),
              _buildDateSelector(context, _selectedStartDate, true, textPrimary, textSecondary, backgroundColor, dividerColor),
              const SizedBox(height: 20),
              _buildOptionalField(
                'Note (optional)',
                textPrimary,
                textSecondary,
                TextFormField(
                  controller: _noteController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g., Netflix subscription',
                    hintStyle: TextStyle(color: textSecondary.withAlpha(128)),
                  ),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(height: 20),
                _buildOptionalField(
                  'End Date (optional)',
                  textPrimary,
                  textSecondary,
                  _buildDateSelector(context, _selectedEndDate, false, textPrimary, textSecondary, backgroundColor, dividerColor),
                ),
                const SizedBox(height: 24),
                _buildActionButtons(isDark, textPrimary, textSecondary, dividerColor),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveRecurring,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textPrimary,
                    foregroundColor: backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Update' : 'Add Recurring',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(Color textPrimary, Color textSecondary, Color backgroundColor, Color dividerColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textSecondary,
            ),
            hintText: '0.00',
            hintStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textSecondary.withAlpha(77),
            ),
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: textPrimary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Enter amount';
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) return 'Enter valid amount';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector(List categories, Color textPrimary, Color textSecondary) {
    final selectedCategory = categories.cast<dynamic>().firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => categories.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _showCategoryPicker(categories, textPrimary, textSecondary),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Color(selectedCategory.color).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(selectedCategory.color).withAlpha(77)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(selectedCategory.color).withAlpha(51),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    IconConstants.getIcon(selectedCategory.iconName),
                    color: Color(selectedCategory.color),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedCategory.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCategoryPicker(List categories, Color textPrimary, Color textSecondary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  final isSelected = cat.id == _selectedCategoryId;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(cat.color).withAlpha(isSelected ? 51 : 25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        IconConstants.getIcon(cat.iconName),
                        color: Color(cat.color),
                        size: 22,
                      ),
                    ),
                    title: Text(cat.name, style: TextStyle(color: textPrimary)),
                    trailing: isSelected ? Icon(Icons.check, color: Color(cat.color)) : null,
                    onTap: () {
                      setState(() => _selectedCategoryId = cat.id);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector(Color textPrimary, Color textSecondary, Color backgroundColor, Color dividerColor) {
    return Row(
      children: RecurringFrequency.values.map((frequency) {
        final isSelected = frequency == _selectedFrequency;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: frequency != RecurringFrequency.yearly ? 8 : 0),
            child: InkWell(
              onTap: () => setState(() => _selectedFrequency = frequency),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? textPrimary.withAlpha(13) : backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? textPrimary : dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getFrequencyIcon(frequency),
                      color: isSelected ? textPrimary : textSecondary,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFrequencyLabel(frequency),
                      style: TextStyle(
                        color: isSelected ? textPrimary : textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getFrequencyIcon(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return Icons.today;
      case RecurringFrequency.weekly:
        return Icons.date_range;
      case RecurringFrequency.monthly:
        return Icons.calendar_month;
      case RecurringFrequency.yearly:
        return Icons.event_repeat;
    }
  }

  String _getFrequencyLabel(RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  Widget _buildDateSelector(BuildContext context, DateTime? date, bool isStart, Color textPrimary, Color textSecondary, Color backgroundColor, Color dividerColor) {
    return InkWell(
      onTap: () => _selectDate(isStart),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dividerColor),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: textSecondary),
            const SizedBox(width: 12),
            Text(
              date != null ? '${date.month}/${date.day}/${date.year}' : 'Not set',
              style: TextStyle(color: textPrimary, fontSize: 16),
            ),
            const Spacer(),
            if (isStart)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: textSecondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getDayOrdinal(date?.day ?? 1),
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDayOrdinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _selectedStartDate : (_selectedEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartDate = picked;
        } else {
          _selectedEndDate = picked;
        }
      });
    }
  }

  Widget _buildOptionalField(String label, Color textPrimary, Color textSecondary, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, Color textPrimary, Color textSecondary, Color dividerColor) {
    return Row(
      children: [
        if (widget.onToggleActive != null)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                widget.onToggleActive!();
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.recurring!.isActive ? 'Pause' : 'Activate',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        if (widget.onToggleActive != null && widget.onDelete != null) const SizedBox(width: 12),
        if (widget.onDelete != null)
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete!();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  void _saveRecurring() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      widget.onSave(
        amount,
        _selectedCategoryId,
        _selectedFrequency,
        _selectedStartDate,
        note,
        _selectedEndDate,
      );
      Navigator.pop(context);
    }
  }
}
