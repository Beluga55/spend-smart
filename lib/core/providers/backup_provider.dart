import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/models/budget.dart';
import 'package:mobile_expense_tracker/core/models/saving_goal.dart';
import 'package:mobile_expense_tracker/core/models/recurring_expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/wallet.dart';
import 'package:mobile_expense_tracker/core/models/wallet_transfer.dart';
import 'package:mobile_expense_tracker/core/constants/app_constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class BackupData {
  final List<Map<String, dynamic>> expenses;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> budgets;
  final List<Map<String, dynamic>> savingGoals;
  final List<Map<String, dynamic>> recurringExpenses;
  final List<Map<String, dynamic>> incomes;
  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> walletTransfers;
  final DateTime exportedAt;

  BackupData({
    required this.expenses,
    required this.categories,
    required this.budgets,
    required this.savingGoals,
    required this.recurringExpenses,
    required this.incomes,
    required this.wallets,
    required this.walletTransfers,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() => {
    'version': 3,
    'exportedAt': exportedAt.toIso8601String(),
    'expenses': expenses,
    'categories': categories,
    'budgets': budgets,
    'savingGoals': savingGoals,
    'recurringExpenses': recurringExpenses,
    'incomes': incomes,
    'wallets': wallets,
    'walletTransfers': walletTransfers,
  };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      expenses: List<Map<String, dynamic>>.from(json['expenses'] ?? []),
      categories: List<Map<String, dynamic>>.from(json['categories'] ?? []),
      budgets: List<Map<String, dynamic>>.from(json['budgets'] ?? []),
      savingGoals: List<Map<String, dynamic>>.from(json['savingGoals'] ?? []),
      recurringExpenses: List<Map<String, dynamic>>.from(
        json['recurringExpenses'] ?? [],
      ),
      incomes: List<Map<String, dynamic>>.from(json['incomes'] ?? []),
      wallets: List<Map<String, dynamic>>.from(json['wallets'] ?? []),
      walletTransfers: List<Map<String, dynamic>>.from(json['walletTransfers'] ?? []),
      exportedAt: DateTime.parse(json['exportedAt']),
    );
  }
}

class BackupService {
  Future<BackupData> gatherData() async {
    final expenseBox = Hive.box<Expense>('expenses');
    final categoryBox = Hive.box<Category>('categories');
    final budgetBox = Hive.box<Budget>('budgets');
    final savingGoalBox = Hive.box<SavingGoal>('saving_goals');
    final recurringBox = Hive.box<RecurringExpense>('recurring_expenses');
    final incomeBox = Hive.box<Income>('incomes');
    final walletBox = Hive.box<Wallet>('wallets');
    final walletTransferBox = Hive.box<WalletTransfer>('wallet_transfers');

    return BackupData(
      expenses: expenseBox.values
          .map(
            (e) => {
              'id': e.id,
              'amount': e.amount,
              'categoryId': e.categoryId,
              'date': e.date.toIso8601String(),
              'note': e.note,
              'createdAt': e.createdAt.toIso8601String(),
              'walletId': e.walletId,
            },
          )
          .toList(),
      categories: categoryBox.values
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'iconName': c.iconName,
              'color': c.color,
              'isDefault': c.isDefault,
              'categoryType': c.categoryType,
            },
          )
          .toList(),
      budgets: budgetBox.values
          .map(
            (b) => {
              'id': b.id,
              'month': b.month,
              'year': b.year,
              'limitAmount': b.limitAmount,
              'categoryId': b.categoryId,
              'day': b.day,
            },
          )
          .toList(),
      savingGoals: savingGoalBox.values
          .map(
            (g) => {
              'id': g.id,
              'name': g.name,
              'targetAmount': g.targetAmount,
              'currentAmount': g.currentAmount,
              'deadline': g.deadline?.toIso8601String(),
              'iconName': g.iconName,
              'color': g.color,
              'createdAt': g.createdAt.toIso8601String(),
            },
          )
          .toList(),
      recurringExpenses: recurringBox.values
          .map(
            (r) => {
              'id': r.id,
              'amount': r.amount,
              'categoryId': r.categoryId,
              'note': r.note,
              'frequency': r.frequency.name,
              'startDate': r.startDate.toIso8601String(),
              'endDate': r.endDate?.toIso8601String(),
              'lastCreated': r.lastCreated?.toIso8601String(),
              'isActive': r.isActive,
            },
          )
          .toList(),
      incomes: incomeBox.values
          .map(
            (i) => {
              'id': i.id,
              'amount': i.amount,
              'source': i.source,
              'date': i.date.toIso8601String(),
              'note': i.note,
              'createdAt': i.createdAt.toIso8601String(),
              'walletId': i.walletId,
            },
          )
          .toList(),
      wallets: walletBox.values
          .map(
            (w) => {
              'id': w.id,
              'name': w.name,
              'iconName': w.iconName,
              'color': w.color,
              'type': w.type,
              'isDefault': w.isDefault,
              'createdAt': w.createdAt.toIso8601String(),
            },
          )
          .toList(),
      walletTransfers: walletTransferBox.values
          .map(
            (t) => {
              'id': t.id,
              'fromWalletId': t.fromWalletId,
              'toWalletId': t.toWalletId,
              'amount': t.amount,
              'date': t.date.toIso8601String(),
              'note': t.note,
              'createdAt': t.createdAt.toIso8601String(),
            },
          )
          .toList(),
      exportedAt: DateTime.now(),
    );
  }

  Future<File> createBackupFile(BackupData data) async {
    final jsonString = jsonEncode(data.toJson());
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${directory.path}/expense_backup_$timestamp.json');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<void> shareBackup() async {
    final data = await gatherData();
    final file = await createBackupFile(data);
    String normalizedPath = file.path.replaceAll('\\', '/');
    await Share.shareXFiles([
      XFile(normalizedPath),
    ], text: 'Expense Tracker Backup');
  }

  Future<void> uploadToCloud() async {
    final data = await gatherData();
    final jsonString = jsonEncode(data.toJson());

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final client = SupabaseService.client;

    await client.from('backups').upsert({
      'user_id': userId,
      'data': jsonString,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<BackupData?> downloadFromCloud() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final client = SupabaseService.client;

    final response = await client
        .from('backups')
        .select('data')
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null || response['data'] == null) {
      return null;
    }

    final jsonString = response['data'] as String;
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return BackupData.fromJson(json);
  }

  Future<void> restoreFromCloud() async {
    final backupData = await downloadFromCloud();
    if (backupData == null) {
      throw Exception('No backup found');
    }

    final expenseBox = Hive.box<Expense>('expenses');
    final categoryBox = Hive.box<Category>('categories');
    final budgetBox = Hive.box<Budget>('budgets');
    final savingGoalBox = Hive.box<SavingGoal>('saving_goals');
    final recurringBox = Hive.box<RecurringExpense>('recurring_expenses');
    final incomeBox = Hive.box<Income>('incomes');
    final walletBox = Hive.box<Wallet>('wallets');
    final walletTransferBox = Hive.box<WalletTransfer>('wallet_transfers');

    await expenseBox.clear();
    await categoryBox.clear();
    await budgetBox.clear();
    await savingGoalBox.clear();
    await recurringBox.clear();
    await incomeBox.clear();
    await walletBox.clear();
    await walletTransferBox.clear();

    for (final e in backupData.expenses) {
      final expense = Expense(
        id: e['id'],
        amount: (e['amount'] as num).toDouble(),
        categoryId: e['categoryId'],
        date: DateTime.parse(e['date']),
        note: e['note'],
        createdAt: DateTime.parse(e['createdAt']),
        walletId: e['walletId'],
      );
      await expenseBox.put(expense.id, expense);
    }

    for (final c in backupData.categories) {
      final category = Category(
        id: c['id'],
        name: c['name'],
        iconName: c['iconName'],
        color: c['color'],
        isDefault: c['isDefault'] ?? false,
        categoryType: c['categoryType'] ?? 'expense',
      );
      await categoryBox.put(category.id, category);
    }

    for (final b in backupData.budgets) {
      final budget = Budget(
        id: b['id'],
        month: b['month'],
        year: b['year'],
        limitAmount: (b['limitAmount'] as num).toDouble(),
        categoryId: b['categoryId'],
        day: b['day'],
      );
      await budgetBox.put(budget.id, budget);
    }

    for (final g in backupData.savingGoals) {
      final goal = SavingGoal(
        id: g['id'],
        name: g['name'],
        targetAmount: (g['targetAmount'] as num).toDouble(),
        currentAmount: (g['currentAmount'] as num).toDouble(),
        deadline: g['deadline'] != null ? DateTime.parse(g['deadline']) : null,
        iconName: g['iconName'],
        color: g['color'],
        createdAt: DateTime.parse(g['createdAt']),
      );
      await savingGoalBox.put(goal.id, goal);
    }

    for (final r in backupData.recurringExpenses) {
      final recurring = RecurringExpense(
        id: r['id'],
        amount: (r['amount'] as num).toDouble(),
        categoryId: r['categoryId'],
        note: r['note'],
        frequency: RecurringFrequency.values.firstWhere(
          (f) => f.name == r['frequency'],
          orElse: () => RecurringFrequency.monthly,
        ),
        startDate: DateTime.parse(r['startDate']),
        endDate: r['endDate'] != null ? DateTime.parse(r['endDate']) : null,
        lastCreated: r['lastCreated'] != null
            ? DateTime.parse(r['lastCreated'])
            : null,
        isActive: r['isActive'] ?? true,
      );
      await recurringBox.put(recurring.id, recurring);
    }

    for (final i in backupData.incomes) {
      final income = Income(
        id: i['id'],
        amount: (i['amount'] as num).toDouble(),
        source: i['source'],
        date: DateTime.parse(i['date']),
        note: i['note'],
        createdAt: DateTime.parse(i['createdAt']),
        walletId: i['walletId'],
      );
      await incomeBox.put(income.id, income);
    }

    for (final w in backupData.wallets) {
      final wallet = Wallet(
        id: w['id'],
        name: w['name'],
        iconName: w['iconName'],
        color: w['color'],
        type: w['type'],
        isDefault: w['isDefault'] ?? false,
        createdAt: DateTime.parse(w['createdAt']),
      );
      await walletBox.put(wallet.id, wallet);
    }

    for (final t in backupData.walletTransfers) {
      final transfer = WalletTransfer(
        id: t['id'],
        fromWalletId: t['fromWalletId'],
        toWalletId: t['toWalletId'],
        amount: (t['amount'] as num).toDouble(),
        date: DateTime.parse(t['date']),
        note: t['note'],
        createdAt: DateTime.parse(t['createdAt']),
      );
      await walletTransferBox.put(transfer.id, transfer);
    }

    // Re-seed default expense categories if none exist after restore
    final hasExpenseCategories = categoryBox.values.any(
      (c) => c.categoryType == 'expense',
    );
    if (!hasExpenseCategories) {
      const uuid = Uuid();
      for (final cat in AppConstants.defaultCategories) {
        final id = uuid.v4();
        await categoryBox.put(
          id,
          Category(
            id: id,
            name: cat.name,
            iconName: cat.iconName,
            color: cat.color,
            isDefault: true,
            categoryType: 'expense',
          ),
        );
      }
    }

    // Re-seed default income categories if none exist after restore
    final hasIncomeCategories = categoryBox.values.any(
      (c) => c.categoryType == 'income',
    );
    if (!hasIncomeCategories) {
      const uuid = Uuid();
      for (final cat in AppConstants.defaultIncomeCategories) {
        final id = uuid.v4();
        await categoryBox.put(
          id,
          Category(
            id: id,
            name: cat.name,
            iconName: cat.iconName,
            color: cat.color,
            isDefault: true,
            categoryType: 'income',
          ),
        );
      }
    }

    // Re-seed default wallet if none exist after restore
    if (walletBox.isEmpty) {
      const uuid = Uuid();
      final id = uuid.v4();
      await walletBox.put(
        id,
        Wallet(
          id: id,
          name: 'Cash',
          iconName: 'wallet',
          color: 0xFF4CAF50,
          type: 'cash',
          isDefault: true,
          createdAt: DateTime.now(),
        ),
      );
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

final backupProvider = Provider((ref) {
  return ref.watch(backupServiceProvider);
});
