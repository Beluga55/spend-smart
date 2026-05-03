import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/models/budget.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class BudgetModal extends ConsumerStatefulWidget {
  const BudgetModal({super.key});

  @override
  ConsumerState<BudgetModal> createState() => _BudgetModalState();
}

class _BudgetModalState extends ConsumerState<BudgetModal>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _budgetController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final budget = ref.read(globalBudgetProvider);
    _budgetController = TextEditingController(
      text: budget?.limitAmount.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final globalBudget = ref.watch(globalBudgetProvider);
    final categoryBudgets = ref.watch(categoryBudgetsProvider);
    final categories = ref.watch(expenseCategoriesProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final primaryColor = isDark ? Colors.white : AppTheme.primaryColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
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
                        color: dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.budgetSettings,
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
                  const SizedBox(height: 4),
                  Text(
                    '${selectedMonth.month}/${selectedMonth.year}',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: textSecondary,
              indicatorColor: primaryColor,
              tabs: [
                Tab(text: l10n.monthly),
                Tab(text: l10n.category),
              ],
            ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMonthlyBudgetTab(globalBudget, l10n),
                  _buildCategoryBudgetsTab(categoryBudgets, categories, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBudgetTab(Budget? globalBudget, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final errorColor = isDark ? Colors.white : AppTheme.errorColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monthlyBudget,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.setTotalLimit,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
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
                labelText: l10n.budgetAmount,
                filled: true,
                fillColor: backgroundColor,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveGlobalBudget,
                child: Text(
                  globalBudget != null ? l10n.updateBudget : l10n.setBudget,
                ),
              ),
            ),
            if (globalBudget != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _deleteGlobalBudget,
                  child: Text(
                    l10n.removeBudget,
                    style: TextStyle(color: errorColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetsTab(
    List<Budget> categoryBudgets,
    List<Category> categories,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final budget = categoryBudgets
                  .where((b) => b.categoryId == category.id)
                  .firstOrNull;
              return _buildCategoryBudgetTile(category, budget, l10n);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBudgetTile(
    Category category,
    Budget? budget,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(currencyProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final spent = categoryTotals[category.id] ?? 0;
    final remaining = budget != null ? budget.limitAmount - spent : 0.0;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final primaryColor = isDark ? Colors.white : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(category.color).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              IconConstants.getIcon(category.iconName),
              color: Color(category.color),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                if (budget != null)
                  Text(
                    '${currency.symbol}${remaining.toStringAsFixed(2)} ${l10n.remaining}',
                    style: TextStyle(
                      color: remaining < 0 ? Colors.red : textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (budget != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: primaryColor,
              onPressed: () =>
                  _showCategoryBudgetDialog(category, budget, l10n),
            )
          else
            TextButton(
              onPressed: () => _showCategoryBudgetDialog(category, null, l10n),
              child: Text(l10n.setBudget),
            ),
        ],
      ),
    );
  }

  void _showCategoryBudgetDialog(
    Category category,
    Budget? existingBudget,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final errorColor = isDark ? Colors.white : AppTheme.errorColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final controller = TextEditingController(
      text: existingBudget?.limitAmount.toStringAsFixed(2) ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Text(
                '${category.name} ${l10n.budgetSettings}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
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
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  if (existingBudget != null) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          ref
                              .read(categoryBudgetsProvider.notifier)
                              .deleteBudgetForCategory(category.id);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          l10n.delete,
                          style: TextStyle(color: errorColor),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(controller.text);
                        if (amount != null && amount > 0) {
                          ref
                              .read(categoryBudgetsProvider.notifier)
                              .setBudgetForCategory(category.id, amount);
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGlobalBudget() {
    final amount = double.tryParse(_budgetController.text);
    if (amount != null && amount > 0) {
      ref.read(globalBudgetProvider.notifier).setBudget(amount);
    } else if (_budgetController.text.isEmpty) {
      ref.read(globalBudgetProvider.notifier).deleteBudget();
    }
    Navigator.pop(context);
  }

  void _deleteGlobalBudget() {
    ref.read(globalBudgetProvider.notifier).deleteBudget();
    _budgetController.clear();
    Navigator.pop(context);
  }
}

