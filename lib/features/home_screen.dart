import 'package:flutter/material.dart';
import 'package:mobile_expense_tracker/features/home/widgets/drawer_content.dart';
import 'package:mobile_expense_tracker/features/dashboard/dashboard_screen.dart';
import 'package:mobile_expense_tracker/features/expenses/expenses_screen.dart';
import 'package:mobile_expense_tracker/features/wallets/wallets_screen.dart';
import 'package:mobile_expense_tracker/features/categories/categories_screen.dart';
import 'package:mobile_expense_tracker/features/saving_goals/saving_goals_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ExpensesScreen(),
    WalletsScreen(),
    CategoriesScreen(),
    SavingGoalsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Builder(
      builder: (context) => Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        drawer: const DrawerContent(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: l10n.dashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: l10n.transactions,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: const Icon(Icons.account_balance_wallet),
              label: l10n.wallets,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.category_outlined),
              activeIcon: const Icon(Icons.category),
              label: l10n.categories,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.savings_outlined),
              activeIcon: const Icon(Icons.savings),
              label: l10n.savingGoals,
            ),
          ],
        ),
      ),
    );
  }
}
