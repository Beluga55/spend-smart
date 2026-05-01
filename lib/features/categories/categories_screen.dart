import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/features/categories/widgets/category_modal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Theme.of(context).colorScheme.outline,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(153),
          tabs: [
            Tab(text: l10n.expenses),
            Tab(text: l10n.income),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoriesTab(type: 'expense'),
          _CategoriesTab(type: 'income'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_fab',
        onPressed: () => _showAddCategorySheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
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
                  child: _SheetTile(
                    icon: Icons.arrow_upward_rounded,
                    label: l10n.expenseCategories,
                    color: const Color(0xFFFF5252),
                    textPrimary: textPrimary,
                    dividerColor: dividerColor,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddCategoryModal(context, 'expense');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetTile(
                    icon: Icons.arrow_downward_rounded,
                    label: l10n.incomeCategories,
                    color: const Color(0xFF4CAF50),
                    textPrimary: textPrimary,
                    dividerColor: dividerColor,
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddCategoryModal(context, 'income');
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

  void _showAddCategoryModal(BuildContext context, String categoryType) {
    final l10n = AppLocalizations.of(context)!;
    final title = categoryType == 'income'
        ? l10n.incomeCategories
        : l10n.expenseCategories;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryModal(
        customTitle: title,
        onSave: (name, iconName, color) {
          ref
              .read(categoriesProvider.notifier)
              .addCategory(
                name: name,
                iconName: iconName,
                color: color,
                categoryType: categoryType,
              );
        },
      ),
    );
  }
}

// ── Sheet tile ──

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textPrimary;
  final Color dividerColor;
  final VoidCallback onTap;

  const _SheetTile({
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

// ── Unified categories tab (filtered by type) ──

class _CategoriesTab extends ConsumerWidget {
  final String type;

  const _CategoriesTab({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categories = type == 'expense'
        ? ref.watch(expenseCategoriesProvider)
        : ref.watch(incomeCategoriesProvider);

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: textSecondary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'expense' ? l10n.noExpensesYet : l10n.noIncomeYet,
              style: TextStyle(color: textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          surfaceColor: surfaceColor,
          dividerColor: dividerColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          onTap: () => _showEditCategoryModal(context, ref, category),
        );
      },
    );
  }

  void _showEditCategoryModal(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryModal(
        category: category,
        onSave: (name, iconName, color) {
          ref
              .read(categoriesProvider.notifier)
              .updateCategory(
                category.copyWith(name: name, iconName: iconName, color: color),
              );
        },
        onDelete: category.isDefault
            ? null
            : () {
                ref
                    .read(categoriesProvider.notifier)
                    .deleteCategory(category.id);
              },
      ),
    );
  }
}

// ── Category card ──

class _CategoryCard extends StatelessWidget {
  final Category category;
  final Color surfaceColor;
  final Color dividerColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.surfaceColor,
    required this.dividerColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Color(category.color).withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                IconConstants.getIcon(category.iconName),
                color: Color(category.color),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textPrimary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (category.isDefault)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: textSecondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.defaultCategory,
                  style: TextStyle(fontSize: 10, color: textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


