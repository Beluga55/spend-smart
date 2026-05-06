import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/providers/search_provider.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/features/expenses/widgets/expense_modal.dart';
import 'package:mobile_expense_tracker/features/expenses/widgets/search_filter_modal.dart';
import 'package:mobile_expense_tracker/features/income/widgets/income_modal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

/// A unified transaction item that wraps either an Expense or an Income.
class _Transaction {
  final DateTime date;
  final DateTime createdAt;
  final bool isIncome;
  final Expense? expense;
  final Income? income;

  _Transaction({
    required this.date,
    required this.createdAt,
    required this.isIncome,
    this.expense,
    this.income,
  });

  factory _Transaction.fromExpense(Expense e) => _Transaction(
    date: e.date,
    createdAt: e.createdAt,
    isIncome: false,
    expense: e,
  );

  factory _Transaction.fromIncome(Income i) => _Transaction(
    date: i.date,
    createdAt: i.createdAt,
    isIncome: true,
    income: i,
  );

  String get id => isIncome ? income!.id : expense!.id;
}

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider);
    final search = ref.watch(searchProvider);
    final filteredExpenses = ref.watch(filteredExpensesProvider);
    final monthlyIncomes = ref.watch(monthlyIncomesProvider);
    final hasActiveFilters = search.hasFilters;

    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Apply category filter to expenses only
    List<Expense> displayExpenses = _selectedCategoryId != null
        ? filteredExpenses
              .where((e) => e.categoryId == _selectedCategoryId)
              .toList()
        : filteredExpenses;

    // Merge into unified transaction list
    final transactions = <_Transaction>[
      ...displayExpenses.map((e) => _Transaction.fromExpense(e)),
      ...monthlyIncomes.map((i) => _Transaction.fromIncome(i)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final grouped = _groupByDate(transactions);

    return Scaffold(
      appBar: _isSearching
          ? _buildSearchAppBar(l10n, textSecondary, primaryColor)
          : _buildNormalAppBar(
              l10n,
              textSecondary,
              primaryColor,
              hasActiveFilters,
            ),
      body: transactions.isEmpty
          ? _buildEmptyState(l10n, textSecondary, hasActiveFilters)
          : _buildTransactionList(grouped, categories, l10n),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions_fab',
        onPressed: () => _showQuickAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar(
    AppLocalizations l10n,
    Color textSecondary,
    Color primaryColor,
    bool hasActiveFilters,
  ) {
    return AppBar(
      title: Text(l10n.transactions),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        if (hasActiveFilters)
          IconButton(
            icon: Icon(Icons.filter_list, color: primaryColor),
            onPressed: () => _showFilterModal(context),
          )
        else
          IconButton(
            icon: Icon(
              _selectedCategoryId != null
                  ? Icons.filter_list
                  : Icons.filter_list_outlined,
              color: _selectedCategoryId != null ? primaryColor : null,
            ),
            onPressed: () => _showCategoryFilterSheet(context),
          ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar(
    AppLocalizations l10n,
    Color textSecondary,
    Color primaryColor,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          setState(() {
            _isSearching = false;
            _searchController.clear();
          });
          ref.read(searchProvider.notifier).setQuery('');
        },
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.searchExpenses,
          hintStyle: TextStyle(color: textSecondary),
          border: InputBorder.none,
        ),
        style: TextStyle(color: textSecondary),
        onChanged: (value) => ref.read(searchProvider.notifier).setQuery(value),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterModal(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n,
    Color textSecondary,
    bool hasFilters,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.receipt_long_outlined,
            size: 64,
            color: textSecondary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? l10n.noResultsFound : l10n.noExpensesYet,
            style: TextStyle(color: textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters ? l10n.tryAdjustingFilters : l10n.tapToAddFirstExpense,
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: _clearAllFilters, child: Text(l10n.clearAll)),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    Map<DateTime, List<_Transaction>> grouped,
    List<Category> categories,
    AppLocalizations l10n,
  ) {
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDateHeader(date, l10n),
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...items.map(
              (tx) => tx.isIncome
                  ? _IncomeTile(income: tx.income!)
                  : _ExpenseTile(expense: tx.expense!, categories: categories),
            ),
          ],
        );
      },
    );
  }

  Map<DateTime, List<_Transaction>> _groupByDate(
    List<_Transaction> transactions,
  ) {
    final grouped = <DateTime, List<_Transaction>>{};
    for (final tx in transactions) {
      final dateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(dateOnly, () => []).add(tx);
    }
    return grouped;
  }

  String _formatDateHeader(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return l10n.today;
    if (date == yesterday) return l10n.yesterday;
    return DateFormat('EEEE, MMM d').format(date);
  }

  void _showQuickAdd(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    icon: Icons.arrow_upward_rounded,
                    label: l10n.addExpense,
                    color: Theme.of(context).colorScheme.error,
                    textPrimary: textPrimary,
                    dividerColor: dividerColor,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddExpenseModal(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    icon: Icons.arrow_downward_rounded,
                    label: l10n.addIncome,
                    color: AppTheme.successColor,
                    textPrimary: textPrimary,
                    dividerColor: dividerColor,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddIncomeModal(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchFilterModal(),
    );
  }

  void _showCategoryFilterSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final categories = ref.read(categoriesProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: Icon(Icons.clear_all, color: textPrimary),
                      title: Text(
                        l10n.allCategories,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: _selectedCategoryId == null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedCategoryId = null);
                      },
                    ),
                    ...categories.map(
                      (cat) => ListTile(
                        leading: Container(
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
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: _selectedCategoryId == cat.id
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() => _selectedCategoryId = cat.id);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllFilters() {
    _searchController.clear();
    ref.read(searchProvider.notifier).clearFilters();
    setState(() {
      _isSearching = false;
      _selectedCategoryId = null;
    });
  }

  void _showAddExpenseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseModal(
        onSave: (amount, categoryId, date, note, walletId) {
          ref
              .read(expensesProvider.notifier)
              .addExpense(
                amount: amount,
                categoryId: categoryId,
                date: date,
                note: note,
                walletId: walletId,
              );
          _checkBudgetAlert();
        },
      ),
    );
  }

  void _showAddIncomeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomeModal(
        onSave: (amount, source, date, note, walletId) {
          ref
              .read(incomesProvider.notifier)
              .addIncome(
                amount: amount,
                source: source,
                date: date,
                note: note,
                walletId: walletId,
              );
        },
      ),
    );
  }

  void _checkBudgetAlert() {
    final l10n = AppLocalizations.of(context)!;
    final budgetProgress = ref.read(globalBudgetProgressProvider);
    final budget = ref.read(globalBudgetProvider);

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

    if (budget != null && budgetProgress >= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.budgetExceeded),
          backgroundColor: textPrimary,
        ),
      );
    } else if (budget != null && budgetProgress >= 80) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.budgetWarningPercent(budgetProgress.toInt())),
          backgroundColor: textSecondary,
        ),
      );
    }
  }
}

// ── Quick tile for the add sheet ──

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textPrimary;
  final Color dividerColor;
  final VoidCallback onTap;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.textPrimary,
    required this.dividerColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expense tile ──

class _ExpenseTile extends ConsumerWidget {
  final Expense expense;
  final List<Category> categories;

  const _ExpenseTile({required this.expense, required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);

    Category category = categories.cast<Category>().firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () =>
          Category(id: '', name: '', iconName: 'more_horiz', color: 0xFFB8B8B8),
    );
    final displayName = category.name.isEmpty ? l10n.unknown : category.name;

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      onDismissed: (_) {
        final deleted = expense;
        final box = Hive.box<Expense>('expenses');
        ref.read(expensesProvider.notifier).deleteExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.expenseDeleted),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () {
                box.put(deleted.id, deleted);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
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
        title: Text(
          expense.note?.isNotEmpty == true ? expense.note! : displayName,
          style: TextStyle(fontWeight: FontWeight.w500, color: textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          displayName,
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
        trailing: Text(
          '-${currency.symbol}${expense.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.error,
            fontSize: 16,
          ),
        ),
        onTap: () => _showEditExpenseModal(context, ref),
      ),
    ),
      ),
    );
  }

  void _showEditExpenseModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseModal(
        expense: expense,
        onSave: (amount, categoryId, date, note, walletId) {
          ref
              .read(expensesProvider.notifier)
              .updateExpense(
                expense.copyWith(
                  amount: amount,
                  categoryId: categoryId,
                  date: date,
                  note: note,
                  walletId: walletId,
                ),
              );
        },
        onDelete: () {
          ref.read(expensesProvider.notifier).deleteExpense(expense.id);
        },
      ),
    );
  }
}

// ── Income tile ──

class _IncomeTile extends ConsumerWidget {
  final Income income;

  const _IncomeTile({required this.income});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencyProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final cat = getIncomeCategoryForSource(income.source, incomeCategories);

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Dismissible(
      key: Key(income.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.error,
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      onDismissed: (_) {
        final deleted = income;
        final box = Hive.box<Income>('incomes');
        ref.read(incomesProvider.notifier).deleteIncome(income.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.incomeDeleted),
            action: SnackBarAction(
              label: l10n.undo,
              onPressed: () {
                box.put(deleted.id, deleted);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color(cat.color).withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            IconConstants.getIcon(cat.iconName),
            color: Color(cat.color),
            size: 22,
          ),
        ),
        title: Text(
          income.note?.isNotEmpty == true ? income.note! : cat.name,
          style: TextStyle(fontWeight: FontWeight.w500, color: textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          cat.name,
          style: TextStyle(color: textSecondary, fontSize: 12),
        ),
        trailing: Text(
          '+${currency.symbol}${income.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.successColor,
            fontSize: 16,
          ),
        ),
        onTap: () => _showEditIncomeModal(context, ref),
      ),
    ),
      ),
    );
  }

  void _showEditIncomeModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomeModal(
        income: income,
        onSave: (amount, source, date, note, walletId) {
          ref
              .read(incomesProvider.notifier)
              .updateIncome(
                income.copyWith(
                  amount: amount,
                  source: source,
                  date: date,
                  note: note,
                  walletId: walletId,
                ),
              );
        },
        onDelete: () {
          ref.read(incomesProvider.notifier).deleteIncome(income.id);
        },
      ),
    );
  }
}




