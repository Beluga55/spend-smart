import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final dividerColor = isDark ? AppTheme.darkDividerColor : AppTheme.dividerColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final primaryColor = isDark ? Colors.white : AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              onMonthChanged(DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              ));
            },
            color: textSecondary,
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 20,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM yyyy').format(selectedMonth),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final now = DateTime.now();
              final limit = DateTime(now.year, now.month + 1);
              final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
              if (!nextMonth.isAfter(limit)) {
                onMonthChanged(nextMonth);
              }
            },
            color: textSecondary,
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month + 1),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (result != null) {
      onMonthChanged(DateTime(result.year, result.month));
    }
  }
}
