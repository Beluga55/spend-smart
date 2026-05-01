import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/models/saving_goal.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class GoalDetailModal extends ConsumerStatefulWidget {
  final SavingGoal goal;
  final Function(double amount) onAddMoney;
  final Function(double amount) onWithdraw;

  const GoalDetailModal({
    super.key,
    required this.goal,
    required this.onAddMoney,
    required this.onWithdraw,
  });

  @override
  ConsumerState<GoalDetailModal> createState() => _GoalDetailModalState();
}

class _GoalDetailModalState extends ConsumerState<GoalDetailModal> {
  final _amountController = TextEditingController();
  bool _isAdding = true;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);

    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final backgroundColor = isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Color(widget.goal.color).withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  IconConstants.getIcon(widget.goal.iconName),
                  color: Color(widget.goal.color),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.goal.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${currency.symbol}${widget.goal.currentAmount.toStringAsFixed(2)} / ${currency.symbol}${widget.goal.targetAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${widget.goal.progress.toStringAsFixed(1)}% ${l10n.completed.toLowerCase()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.goal.isCompleted ? Colors.green : textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isAdding = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isAdding
                                  ? (isDark ? Colors.white : AppTheme.primaryColor)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.addMoney,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isAdding
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isAdding = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isAdding
                                  ? (isDark ? Colors.white : AppTheme.primaryColor)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.withdraw,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: !_isAdding
                                    ? (isDark ? Colors.black : Colors.white)
                                    : textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textPrimary, fontSize: 18),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: textSecondary),
                      prefixText: '${currency.symbol} ',
                      prefixStyle: TextStyle(color: textPrimary, fontSize: 18),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAmountButton(currency.symbol, 10, textPrimary, backgroundColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAmountButton(currency.symbol, 50, textPrimary, backgroundColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAmountButton(currency.symbol, 100, textPrimary, backgroundColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAmountButton(currency.symbol, 500, textPrimary, backgroundColor),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
                child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAdding
                      ? Colors.green
                      : (isDark ? Colors.white : AppTheme.primaryColor),
                  foregroundColor: _isAdding
                      ? Colors.white
                      : (isDark ? Colors.black : Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isAdding ? l10n.addMoney : l10n.withdraw,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(String symbol, double amount, Color textPrimary, Color backgroundColor) {
    return GestureDetector(
      onTap: () {
        _amountController.text = amount.toStringAsFixed(0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$symbol${amount.toStringAsFixed(0)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    if (_isAdding) {
      widget.onAddMoney(amount);
    } else {
      if (amount > widget.goal.currentAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cannotWithdrawMoreThanCurrent),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      widget.onWithdraw(amount);
    }
    Navigator.pop(context);
  }
}