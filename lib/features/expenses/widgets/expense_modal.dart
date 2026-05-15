import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/ai_provider.dart';
import 'package:mobile_expense_tracker/core/providers/wallet_provider.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/features/expenses/widgets/receipt_scanner_sheet.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/group_picker_sheet.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/group_expense_modal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class ExpenseModal extends ConsumerStatefulWidget {
  final Expense? expense;
  final Function(
    double amount,
    String categoryId,
    DateTime date,
    String? note,
    String? walletId,
    String? receiptImagePath,
  ) onSave;
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
  String? _selectedWalletId;
  String? _selectedReceiptPath;
  String? _aiSuggestedCategoryId;
  bool _isSuggestingCategory = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.expense?.amount.toStringAsFixed(2) ?? '',
    );
    _noteController = TextEditingController(text: widget.expense?.note ?? '');
    _selectedDate = widget.expense?.date ?? DateTime.now();
    _selectedWalletId = widget.expense?.walletId;
    _selectedReceiptPath = widget.expense?.receiptImagePath;

    final categories = ref.read(expenseCategoriesProvider);
    _selectedCategoryId = widget.expense?.categoryId ?? (categories.isNotEmpty ? categories.first.id : '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _suggestCategory() async {
    final aiSettings = ref.read(aiSettingsProvider);
    if (!aiSettings.enabledFeatures.contains(AIFeature.autoCategorize) ||
        !aiSettings.hasAnyKey) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add your Gemini or NVIDIA API key in Settings → AI Assistant to use this feature.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final note = _noteController.text.trim();
    if (note.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add a description in the Note field so AI knows what this expense is.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final label = note;
    final categories = ref.read(expenseCategoriesProvider);
    final categoryNames = categories.map((c) => c.name).toList();

    setState(() => _isSuggestingCategory = true);

    try {
      final service = ref.read(aiSettingsProvider.notifier).service;
      final suggested = await service.suggestCategory(label, categoryNames);

      // Debug: log raw response so we can see what the AI returns
      debugPrint('[AI Category] Provider: ${service.lastUsedProvider}, Raw response: "$suggested"');

      var cleaned = suggested.trim();
      cleaned = cleaned.replaceAll("'", '');
      cleaned = cleaned.replaceAll('"', '');

      if (cleaned.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI returned empty. Try again or check your API key.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Try exact match first
      Category? match;
      try {
        match = categories.firstWhere(
          (c) => c.name.toLowerCase() == cleaned.toLowerCase(),
        );
      } catch (_) {
        // exact match failed — try partial
        try {
          match = categories.firstWhere(
            (c) => cleaned.toLowerCase().contains(c.name.toLowerCase()),
          );
        } catch (_) {
          // partial failed too — no good match
        }
      }

      if (match == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI said "$cleaned" but no category matches. Pick manually.'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() {
        _aiSuggestedCategoryId = match!.id;
        _selectedCategoryId = match.id;
      });
      if (context.mounted) {
        final provider = service.lastUsedProvider ?? 'AI';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Suggested: ${match.name} ($provider)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[AI Category] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get suggestion: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isSuggestingCategory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(expenseCategoriesProvider);
    final wallets = ref.watch(walletsProvider);
    final isEditing = widget.expense != null;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).colorScheme.outline;
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
                        Text(cat.name, style: TextStyle(color: textPrimary)),
                      ],
                    ),
                  );
                }).toList(),
                style: TextStyle(color: textPrimary),
                dropdownColor: surfaceColor,
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedCategoryId = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    size: 16,
                    color: _aiSuggestedCategoryId != null
                        ? const Color(0xFF6C63FF)
                        : textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _aiSuggestedCategoryId != null
                        ? 'AI suggested category ✓'
                        : 'AI Suggest Category',
                    style: TextStyle(
                      fontSize: 13,
                      color: _aiSuggestedCategoryId != null
                          ? const Color(0xFF6C63FF)
                          : textSecondary,
                    ),
                  ),
                  if (_isSuggestingCategory) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                  if (!_isSuggestingCategory)
                    GestureDetector(
                      onTap: _suggestCategory,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                ],
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
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _scanReceipt(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedReceiptPath != null
                        ? Colors.green.withAlpha(15)
                        : backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedReceiptPath != null
                          ? Colors.green.withAlpha(80)
                          : dividerColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedReceiptPath != null
                            ? Icons.check_circle_outline
                            : Icons.camera_alt_outlined,
                        size: 20,
                        color: _selectedReceiptPath != null
                            ? Colors.green
                            : textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedReceiptPath != null
                            ? 'Receipt attached'
                            : 'Scan Receipt',
                        style: TextStyle(
                          color: _selectedReceiptPath != null
                              ? Colors.green
                              : textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedReceiptPath != null)
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedReceiptPath = null);
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.wallet,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedWalletId,
                decoration: InputDecoration(
                  hintText: l10n.selectWallet,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.noWallet),
                  ),
                  ...wallets.map((wallet) {
                    return DropdownMenuItem(
                      value: wallet.id,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(wallet.color).withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              IconConstants.getIcon(wallet.iconName),
                              color: Color(wallet.color),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(wallet.name, style: TextStyle(color: textPrimary)),
                        ],
                      ),
                    );
                  }),
                ],
                style: TextStyle(color: textPrimary),
                dropdownColor: surfaceColor,
                onChanged: (value) {
                  setState(() => _selectedWalletId = value);
                },
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

      widget.onSave(
        amount,
        _selectedCategoryId,
        _selectedDate,
        note,
        _selectedWalletId,
        _selectedReceiptPath,
      );
      Navigator.pop(context);
    }
  }

  void _scanReceipt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            final currentNote = _noteController.text.trim();
            if (currentNote.isEmpty) {
              _noteController.text = merchant;
            } else {
              _noteController.text = '$merchant — $currentNote';
            }
          }
          setState(() {});
        },
        onAddToGroup: (data) {
          Navigator.pop(context); // close expense modal
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => GroupPickerSheet(
              onGroupSelected: (groupId) {
                final total = data['total'];
                final date = data['date'];
                final merchant = data['merchant'];
                final items = data['items'];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupExpenseModal(
                      groupId: groupId,
                      initialDescription: merchant,
                      initialAmount: total is num ? total.toDouble() : null,
                      initialDate: date is String ? DateTime.tryParse(date) : null,
                      receiptItems: items is List
                          ? items.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                          : null,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

