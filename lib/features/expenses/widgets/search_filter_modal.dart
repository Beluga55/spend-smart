import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/search_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class SearchFilterModal extends ConsumerStatefulWidget {
  const SearchFilterModal({super.key});

  @override
  ConsumerState<SearchFilterModal> createState() => _SearchFilterModalState();
}

class _SearchFilterModalState extends ConsumerState<SearchFilterModal> {
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final search = ref.read(searchProvider);
    _minAmountController = TextEditingController(
      text: search.minAmount?.toString() ?? '',
    );
    _maxAmountController = TextEditingController(
      text: search.maxAmount?.toString() ?? '',
    );
    _startDate = search.startDate;
    _endDate = search.endDate;
    _selectedCategoryId = search.categoryId;
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider);

    final backgroundColor = isDark ? AppTheme.darkSurfaceColor : AppTheme.surfaceColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filters,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    l10n.clearAll,
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.amountRange,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: l10n.min,
                      hintStyle: TextStyle(color: textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: l10n.max,
                      hintStyle: TextStyle(color: textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dateRange,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context,
                    label: l10n.from,
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    context,
                    label: l10n.to,
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: textSecondary.withAlpha(51)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String?>(
                value: _selectedCategoryId,
                isExpanded: true,
                underline: const SizedBox(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                dropdownColor: backgroundColor,
                hint: Text(
                  l10n.allCategories,
                  style: TextStyle(color: textSecondary),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.allCategories),
                  ),
                  ...categories.map((cat) => DropdownMenuItem<String?>(
                    value: cat.id,
                    child: Text(cat.name),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedCategoryId = value),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : AppTheme.primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.applyFilters,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: textSecondary.withAlpha(51)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('MMM d, y').format(date)
                    : label,
                style: TextStyle(
                  color: date != null ? textPrimary : textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _clearAll() {
    setState(() {
      _minAmountController.clear();
      _maxAmountController.clear();
      _startDate = null;
      _endDate = null;
      _selectedCategoryId = null;
    });
    ref.read(searchProvider.notifier).clearFilters();
  }

  void _applyFilters() {
    final minAmount = double.tryParse(_minAmountController.text);
    final maxAmount = double.tryParse(_maxAmountController.text);

    ref.read(searchProvider.notifier).setAmountRange(minAmount, maxAmount);
    ref.read(searchProvider.notifier).setDateRange(_startDate, _endDate);
    ref.read(searchProvider.notifier).setCategory(_selectedCategoryId);

    Navigator.pop(context);
  }
}