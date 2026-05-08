import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/models/saving_goal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class SavingGoalModal extends StatefulWidget {
  final SavingGoal? goal;
  final Function(
    String name,
    double targetAmount,
    DateTime? deadline,
    String iconName,
    int color,
  )
  onSave;
  final VoidCallback? onDelete;

  const SavingGoalModal({
    super.key,
    this.goal,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<SavingGoalModal> createState() => _SavingGoalModalState();
}

class _SavingGoalModalState extends State<SavingGoalModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  DateTime? _deadline;
  late String _selectedIconName;
  late int _selectedColor;

  static const List<int> _availableColors = [
    0xFF4CAF50,
    0xFF2196F3,
    0xFFFF9800,
    0xFFE91E63,
    0xFF9C27B0,
    0xFF00BCD4,
    0xFFFF5722,
    0xFF795548,
    0xFF607D8B,
    0xFF3F51B5,
    0xFF009688,
    0xFFFFC107,
  ];

  static const List<String> _goalIconNames = [
    'savings',
    'flight',
    'home',
    'directions_car',
    'school',
    'sports',
    'beach_access',
    'local_hospital',
    'work',
    'child_care',
    'shopping_bag',
    'account_balance',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetAmountController = TextEditingController(
      text: widget.goal?.targetAmount.toStringAsFixed(0) ?? '',
    );
    _deadline = widget.goal?.deadline;
    _selectedIconName = widget.goal?.iconName ?? _goalIconNames.first;
    _selectedColor = widget.goal?.color ?? _availableColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.goal != null;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? l10n.editSavingGoal : l10n.addSavingGoal,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Color(_selectedColor).withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              IconConstants.getIcon(_selectedIconName),
                              color: Color(_selectedColor),
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.goalName,
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.enterAName;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.targetAmount,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _targetAmountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.enterTargetAmount,
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.enterValidAmount;
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return l10n.enterValidAmount;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.deadline,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _selectDeadline,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 20,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _deadline != null
                                        ? DateFormat(
                                            'MMM d, y',
                                          ).format(_deadline!)
                                        : l10n.setDeadline,
                                    style: TextStyle(
                                      color: _deadline != null
                                          ? textPrimary
                                          : textSecondary,
                                    ),
                                  ),
                                ),
                                if (_deadline != null)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _deadline = null),
                                    child: Icon(
                                      Icons.clear,
                                      size: 20,
                                      color: textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.icon,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _goalIconNames.map((iconName) {
                            final isSelected = iconName == _selectedIconName;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedIconName = iconName),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(_selectedColor).withAlpha(51)
                                      : backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Color(_selectedColor)
                                        : textSecondary.withAlpha(51),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  IconConstants.getIcon(iconName),
                                  color: isSelected
                                      ? Color(_selectedColor)
                                      : textSecondary,
                                  size: 24,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.color,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableColors.map((color) {
                            final isSelected = color == _selectedColor;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Color(color),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? textPrimary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveGoal,
                            child: Text(
                              isEditing ? l10n.save : l10n.addSavingGoal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      final targetAmount = double.parse(_targetAmountController.text);
      widget.onSave(
        _nameController.text.trim(),
        targetAmount,
        _deadline,
        _selectedIconName,
        _selectedColor,
      );
      Navigator.pop(context);
    }
  }
}

