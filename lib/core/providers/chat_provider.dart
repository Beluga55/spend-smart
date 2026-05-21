import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/models/chat_message.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/models/wallet.dart';
import 'package:mobile_expense_tracker/core/providers/ai_provider.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:mobile_expense_tracker/core/providers/wallet_provider.dart';
import 'package:uuid/uuid.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this._ref) : super([]);

  final Ref _ref;

  static const int _maxHistoryLength = 10;

  void clearChat() {
    state = [];
    _ref.read(chatLoadingProvider.notifier).state = false;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    state = [...state, userMsg];
    _ref.read(chatLoadingProvider.notifier).state = true;

    try {
      final aiSettings = _ref.read(aiSettingsProvider);
      if (!aiSettings.enabledFeatures.contains(AIFeature.chatQuery) ||
          !aiSettings.hasAnyKey) {
        _addAssistantMessage(
          'AI Chat is not enabled. Please configure an API key and enable the feature in Settings > AI Assistant.',
        );
        return;
      }

      final service = _ref.read(aiSettingsProvider.notifier).service;
      final context = _buildContext();
      final history = _buildHistory();

      final response = await service.chat(
        query: text.trim(),
        context: context,
        history: history,
      );

      final type = response['type'] as String? ?? 'answer';
      final message =
          response['message'] as String? ?? 'Sorry, I did not understand that.';
      final actionData = response['action'] as Map<String, dynamic>?;
      debugPrint(
        '[Chat] AI response: type=$type, hasAction=${actionData != null}',
      );

      ChatAction? action;
      if (actionData != null && type != 'answer') {
        action = ChatAction(type: type, data: actionData);
      }

      // Execute the action if present
      String executionNote = '';
      if (action != null) {
        executionNote = await _executeAction(action);
      }

      _addAssistantMessage(
        executionNote.isNotEmpty ? '$message\n\n$executionNote' : message,
        action: action,
      );
    } catch (e, stack) {
      developer.log('[Chat] Error: $e\n$stack');
      _addAssistantMessage('Something went wrong. Please try again. Error: $e');
    } finally {
      _ref.read(chatLoadingProvider.notifier).state = false;
    }
  }

  Map<String, dynamic> _buildContext() {
    final expenses = _ref.read(expensesProvider);
    final incomes = _ref.read(incomesProvider);
    final categories = _ref.read(categoriesProvider);
    final budgets = _ref.read(categoryBudgetsProvider);
    final globalBudget = _ref.read(globalBudgetProvider);
    final wallets = _ref.read(walletsProvider);
    final totalBalance = _ref.read(totalBalanceProvider);
    final monthlyTotal = _ref.read(monthlyTotalProvider);
    final monthlyIncome = _ref.read(monthlyIncomeTotalProvider);
    final monthlyBalance = _ref.read(monthlyBalanceProvider);

    final now = DateTime.now();
    final currentMonthExpenses =
        expenses
            .where((e) => e.date.month == now.month && e.date.year == now.year)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final currentMonthIncomes =
        incomes
            .where((i) => i.date.month == now.month && i.date.year == now.year)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return {
      'totalBalance': totalBalance.toStringAsFixed(2),
      'monthlyExpenseTotal': monthlyTotal.toStringAsFixed(2),
      'monthlyIncomeTotal': monthlyIncome.toStringAsFixed(2),
      'monthlyBalance': monthlyBalance.toStringAsFixed(2),
      'categories': categories
          .map((c) => {'name': c.name, 'type': c.effectiveType})
          .toList(),
      'expenses': currentMonthExpenses.take(30).map((e) {
        final cat = categories.firstWhere(
          (c) => c.id == e.categoryId,
          orElse: () => categories.first,
        );
        return {
          'date':
              '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
          'amount': e.amount.toStringAsFixed(2),
          'category': cat.name,
          'note': e.note ?? '',
        };
      }).toList(),
      'incomes': currentMonthIncomes
          .take(20)
          .map(
            (i) => {
              'date':
                  '${i.date.year}-${i.date.month.toString().padLeft(2, '0')}-${i.date.day.toString().padLeft(2, '0')}',
              'amount': i.amount.toStringAsFixed(2),
              'source': i.source,
              'note': i.note ?? '',
            },
          )
          .toList(),
      'budgets': [
        if (globalBudget != null)
          {
            'name': 'Monthly',
            'limit': globalBudget.limitAmount.toStringAsFixed(2),
          },
        ...budgets.where((b) => b.categoryId != null).map((b) {
          final cat = categories.firstWhere(
            (c) => c.id == b.categoryId,
            orElse: () => categories.first,
          );
          return {'name': cat.name, 'limit': b.limitAmount.toStringAsFixed(2)};
        }),
      ],
      'wallets': wallets.map((w) {
        final balance = _ref.read(walletBalanceProvider(w.id));
        return {
          'id': w.id,
          'name': w.name,
          'balance': balance.toStringAsFixed(2),
          'isDefault': w.isDefault,
        };
      }).toList(),
    };
  }

  List<Map<String, dynamic>> _buildHistory() {
    final recent = state.length > _maxHistoryLength
        ? state.sublist(state.length - _maxHistoryLength)
        : List<ChatMessage>.from(state);
    return recent
        .map(
          (m) => {
            'role': m.role == ChatRole.user ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();
  }

  void _addAssistantMessage(String content, {ChatAction? action}) {
    final msg = ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      action: action,
    );
    state = [...state, msg];
  }

  Future<String> _executeAction(ChatAction action) async {
    developer.log(
      '[Chat] _executeAction: type=${action.type}, data=${action.data}',
    );
    switch (action.type) {
      case 'create_expense':
        return _createExpense(action.data);
      case 'create_income':
        return _createIncome(action.data);
      case 'create_multiple_expenses':
        developer.log('[Chat] Routing to _createMultipleExpenses');
        return _createMultipleExpenses(action.data);
      case 'create_multiple_incomes':
        return _createMultipleIncomes(action.data);
      case 'create_category':
        return _createCategory(action.data);
      case 'delete_expense':
        return _deleteExpense(action.data);
      case 'delete_income':
        return _deleteIncome(action.data);
      case 'delete_category':
        return _deleteCategory(action.data);
      case 'create_transfer':
        return _createTransfer(action.data);
      default:
        return '';
    }
  }

  Future<String> _createExpense(Map<String, dynamic> data) async {
    try {
      final amount = (data['amount'] as num?)?.toDouble();
      final categoryName = data['category'] as String?;
      final walletName = data['wallet'] as String?;
      final dateStr = data['date'] as String?;
      final note = data['note'] as String?;

      if (amount == null || amount <= 0) {
        return '⚠️ Could not create expense: invalid amount.';
      }
      if (categoryName == null || categoryName.isEmpty) {
        return '⚠️ Could not create expense: category is required.';
      }

      final categories = _ref.read(categoriesProvider);
      final match = _findCategoryByName(categories, categoryName, 'expense');
      if (match == null) {
        return '⚠️ Category "$categoryName" does not exist. Try asking me to create it first!';
      }

      DateTime date;
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = DateTime.now();
        }
      } else {
        date = DateTime.now();
      }

      // Find wallet by name if specified, otherwise use default
      String? walletId;
      String walletInfo = '';
      if (walletName != null && walletName.isNotEmpty) {
        final wallets = _ref.read(walletsProvider);
        final walletMatch = _findWalletByName(wallets, walletName);
        if (walletMatch != null) {
          walletId = walletMatch.id;
          walletInfo = ' in ${walletMatch.name}';
        } else {
          return '⚠️ Wallet "$walletName" not found. Available wallets: ${wallets.map((w) => w.name).join(', ')}';
        }
      } else {
        final defaultWallet = _ref.read(defaultWalletProvider);
        walletId = defaultWallet?.id;
        if (defaultWallet != null) {
          walletInfo = ' in ${defaultWallet.name}';
        }
      }

      await _ref
          .read(expensesProvider.notifier)
          .addExpense(
            amount: amount,
            categoryId: match.id,
            date: date,
            note: note,
            walletId: walletId,
          );

      return '✅ Created expense: ${match.name} \$${amount.toStringAsFixed(2)}$walletInfo';
    } catch (e) {
      return '⚠️ Failed to create expense: $e';
    }
  }

  Future<String> _createIncome(Map<String, dynamic> data) async {
    try {
      final amount = (data['amount'] as num?)?.toDouble();
      final source = data['source'] as String?;
      final walletName = data['wallet'] as String?;
      final dateStr = data['date'] as String?;
      final note = data['note'] as String?;

      if (amount == null || amount <= 0) {
        return '⚠️ Could not create income: invalid amount.';
      }
      if (source == null || source.isEmpty) {
        return '⚠️ Could not create income: source is required.';
      }

      DateTime date;
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = DateTime.now();
        }
      } else {
        date = DateTime.now();
      }

      // Find wallet by name if specified, otherwise use default
      String? walletId;
      String walletInfo = '';
      if (walletName != null && walletName.isNotEmpty) {
        final wallets = _ref.read(walletsProvider);
        final walletMatch = _findWalletByName(wallets, walletName);
        if (walletMatch != null) {
          walletId = walletMatch.id;
          walletInfo = ' in ${walletMatch.name}';
        } else {
          return '⚠️ Wallet "$walletName" not found. Available wallets: ${wallets.map((w) => w.name).join(', ')}';
        }
      } else {
        final defaultWallet = _ref.read(defaultWalletProvider);
        walletId = defaultWallet?.id;
        if (defaultWallet != null) {
          walletInfo = ' in ${defaultWallet.name}';
        }
      }

      await _ref
          .read(incomesProvider.notifier)
          .addIncome(
            amount: amount,
            source: source,
            date: date,
            note: note,
            walletId: walletId,
          );

      return '✅ Created income: $source \$${amount.toStringAsFixed(2)}$walletInfo';
    } catch (e) {
      return '⚠️ Failed to create income: $e';
    }
  }

  Future<String> _createMultipleExpenses(Map<String, dynamic> data) async {
    try {
      developer.log('[Chat] _createMultipleExpenses data: $data');
      final transactions = data['transactions'] as List<dynamic>?;
      developer.log('[Chat] transactions count: ${transactions?.length}');
      if (transactions == null || transactions.isEmpty) {
        return '⚠️ No transactions to create.';
      }

      final categories = _ref.read(categoriesProvider);
      final wallets = _ref.read(walletsProvider);
      final defaultWallet = _ref.read(defaultWalletProvider);
      final created = <String>[];
      final errors = <String>[];

      for (final tx in transactions) {
        final txData = tx as Map<String, dynamic>;
        final amount = (txData['amount'] as num?)?.toDouble();
        final categoryName = txData['category'] as String?;
        final walletName = txData['wallet'] as String?;
        final dateStr = txData['date'] as String?;
        final note = txData['note'] as String?;

        if (amount == null || amount <= 0) {
          errors.add('Invalid amount');
          continue;
        }
        if (categoryName == null || categoryName.isEmpty) {
          errors.add('Missing category');
          continue;
        }

        final match = _findCategoryByName(categories, categoryName, 'expense');
        if (match == null) {
          errors.add('Category "$categoryName" not found');
          continue;
        }

        DateTime date;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {
            date = DateTime.now();
          }
        } else {
          date = DateTime.now();
        }

        // Find wallet by name if specified, otherwise use default
        String? walletId;
        String walletInfo = '';
        if (walletName != null && walletName.isNotEmpty) {
          final walletMatch = _findWalletByName(wallets, walletName);
          if (walletMatch != null) {
            walletId = walletMatch.id;
            walletInfo = ' in ${walletMatch.name}';
          } else {
            errors.add('Wallet "$walletName" not found');
            continue;
          }
        } else {
          walletId = defaultWallet?.id;
          if (defaultWallet != null) {
            walletInfo = ' in ${defaultWallet.name}';
          }
        }

        await _ref
            .read(expensesProvider.notifier)
            .addExpense(
              amount: amount,
              categoryId: match.id,
              date: date,
              note: note,
              walletId: walletId,
            );
        created.add('${match.name} \$${amount.toStringAsFixed(2)}$walletInfo');
      }

      developer.log(
        '[Chat] created: ${created.length}, errors: ${errors.length}',
      );

      if (created.isEmpty && errors.isNotEmpty) {
        return '⚠️ Failed to create any expenses:\n${errors.join("\n")}';
      }
      if (errors.isNotEmpty) {
        return '✅ Created ${created.length} expenses:\n${created.join("\n")}\n\n⚠️ Some failed:\n${errors.join("\n")}';
      }
      return '✅ Created ${created.length} expenses:\n${created.join("\n")}';
    } catch (e) {
      return '⚠️ Failed to create expenses: $e';
    }
  }

  Future<String> _createMultipleIncomes(Map<String, dynamic> data) async {
    try {
      final transactions = data['transactions'] as List<dynamic>?;
      if (transactions == null || transactions.isEmpty) {
        return '⚠️ No transactions to create.';
      }

      final wallets = _ref.read(walletsProvider);
      final defaultWallet = _ref.read(defaultWalletProvider);
      final created = <String>[];
      final errors = <String>[];

      for (final tx in transactions) {
        final txData = tx as Map<String, dynamic>;
        final amount = (txData['amount'] as num?)?.toDouble();
        final source = txData['source'] as String?;
        final walletName = txData['wallet'] as String?;
        final dateStr = txData['date'] as String?;
        final note = txData['note'] as String?;

        if (amount == null || amount <= 0) {
          errors.add('Invalid amount');
          continue;
        }
        if (source == null || source.isEmpty) {
          errors.add('Missing source');
          continue;
        }

        DateTime date;
        if (dateStr != null && dateStr.isNotEmpty) {
          try {
            date = DateTime.parse(dateStr);
          } catch (_) {
            date = DateTime.now();
          }
        } else {
          date = DateTime.now();
        }

        // Find wallet by name if specified, otherwise use default
        String? walletId;
        String walletInfo = '';
        if (walletName != null && walletName.isNotEmpty) {
          final walletMatch = _findWalletByName(wallets, walletName);
          if (walletMatch != null) {
            walletId = walletMatch.id;
            walletInfo = ' in ${walletMatch.name}';
          } else {
            errors.add('Wallet "$walletName" not found');
            continue;
          }
        } else {
          walletId = defaultWallet?.id;
          if (defaultWallet != null) {
            walletInfo = ' in ${defaultWallet.name}';
          }
        }

        await _ref
            .read(incomesProvider.notifier)
            .addIncome(
              amount: amount,
              source: source,
              date: date,
              note: note,
              walletId: walletId,
            );
        created.add('$source \$${amount.toStringAsFixed(2)}$walletInfo');
      }

      if (created.isEmpty && errors.isNotEmpty) {
        return '⚠️ Failed to create any incomes:\n${errors.join("\n")}';
      }
      if (errors.isNotEmpty) {
        return '✅ Created ${created.length} incomes:\n${created.join("\n")}\n\n⚠️ Some failed:\n${errors.join("\n")}';
      }
      return '✅ Created ${created.length} incomes:\n${created.join("\n")}';
    } catch (e) {
      return '⚠️ Failed to create incomes: $e';
    }
  }

  Future<String> _createTransfer(Map<String, dynamic> data) async {
    try {
      final amount = (data['amount'] as num?)?.toDouble();
      final fromWalletName = data['fromWallet'] as String?;
      final toWalletName = data['toWallet'] as String?;
      final dateStr = data['date'] as String?;
      final note = data['note'] as String?;

      if (amount == null || amount <= 0) {
        return '⚠️ Could not create transfer: invalid amount.';
      }
      if (fromWalletName == null || fromWalletName.isEmpty) {
        return '⚠️ Could not create transfer: source wallet is required.';
      }
      if (toWalletName == null || toWalletName.isEmpty) {
        return '⚠️ Could not create transfer: destination wallet is required.';
      }
      if (fromWalletName.toLowerCase() == toWalletName.toLowerCase()) {
        return '⚠️ Could not create transfer: source and destination wallets must be different.';
      }

      final wallets = _ref.read(walletsProvider);
      final fromWallet = _findWalletByName(wallets, fromWalletName);
      final toWallet = _findWalletByName(wallets, toWalletName);

      if (fromWallet == null) {
        return '⚠️ Wallet "$fromWalletName" not found. Available wallets: ${wallets.map((w) => w.name).join(', ')}';
      }
      if (toWallet == null) {
        return '⚠️ Wallet "$toWalletName" not found. Available wallets: ${wallets.map((w) => w.name).join(', ')}';
      }

      // Check if source wallet has sufficient balance
      final fromBalance = _ref.read(walletBalanceProvider(fromWallet.id));
      if (amount > fromBalance) {
        return '⚠️ Insufficient balance in ${fromWallet.name} (available: \$${fromBalance.toStringAsFixed(2)}). Cannot transfer \$${amount.toStringAsFixed(2)}.';
      }

      DateTime date;
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          date = DateTime.parse(dateStr);
        } catch (_) {
          date = DateTime.now();
        }
      } else {
        date = DateTime.now();
      }

      await _ref
          .read(walletTransfersProvider.notifier)
          .addTransfer(
            fromWalletId: fromWallet.id,
            toWalletId: toWallet.id,
            amount: amount,
            date: date,
            note: note,
          );

      return '✅ Transferred \$${amount.toStringAsFixed(2)} from ${fromWallet.name} to ${toWallet.name}';
    } catch (e) {
      return '⚠️ Failed to create transfer: $e';
    }
  }

  Future<String> _createCategory(Map<String, dynamic> data) async {
    try {
      final name = data['name'] as String?;
      final iconName = data['iconName'] as String?;
      final colorStr = data['color'] as String?;
      final categoryType = data['categoryType'] as String? ?? 'expense';

      if (name == null || name.isEmpty) {
        return '⚠️ Could not create category: name is required.';
      }

      final categories = _ref.read(categoriesProvider);
      final existing = _findCategoryByName(categories, name, categoryType);
      if (existing != null) {
        return '⚠️ Category "$name" already exists.';
      }

      final icon = (iconName ?? 'category').trim().toLowerCase();
      final color = _parseColor(colorStr) ?? 0xFF607D8B;

      await _ref
          .read(categoriesProvider.notifier)
          .addCategory(
            name: name.trim(),
            iconName: icon,
            color: color,
            categoryType: categoryType,
          );

      return '✅ Created category: $name';
    } catch (e) {
      return '⚠️ Failed to create category: $e';
    }
  }

  Future<String> _deleteExpense(Map<String, dynamic> data) async {
    try {
      final amount = (data['amount'] as num?)?.toDouble();
      final categoryName = data['category'] as String?;
      final dateStr = data['date'] as String?;
      final note = data['note'] as String?;

      final expenses = _ref.read(expensesProvider);
      final categories = _ref.read(categoriesProvider);

      // Build candidate list and score them
      final candidates = expenses.where((e) {
        if (amount != null && e.amount != amount) return false;
        if (dateStr != null && dateStr.isNotEmpty) {
          final d =
              '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
          if (d != dateStr) return false;
        }
        if (categoryName != null && categoryName.isNotEmpty) {
          final cat = categories.firstWhere(
            (c) => c.id == e.categoryId,
            orElse: () => categories.first,
          );
          if (cat.name.toLowerCase() != categoryName.toLowerCase().trim())
            return false;
        }
        return true;
      }).toList();

      if (candidates.isEmpty) {
        return '⚠️ No matching expense found to delete.';
      }

      // Prefer the one whose note matches best
      Expense target;
      if (note != null && note.isNotEmpty) {
        final noteMatches = candidates
            .where(
              (e) => (e.note ?? '').toLowerCase().contains(note.toLowerCase()),
            )
            .toList();
        target = noteMatches.isNotEmpty ? noteMatches.first : candidates.first;
      } else {
        target = candidates.first;
      }

      final cat = categories.firstWhere(
        (c) => c.id == target.categoryId,
        orElse: () => categories.first,
      );

      await _ref.read(expensesProvider.notifier).deleteExpense(target.id);
      return '✅ Deleted expense: ${cat.name} \$${target.amount.toStringAsFixed(2)}';
    } catch (e) {
      return '⚠️ Failed to delete expense: $e';
    }
  }

  Future<String> _deleteIncome(Map<String, dynamic> data) async {
    try {
      final amount = (data['amount'] as num?)?.toDouble();
      final source = data['source'] as String?;
      final dateStr = data['date'] as String?;
      final note = data['note'] as String?;

      final incomes = _ref.read(incomesProvider);

      final candidates = incomes.where((i) {
        if (amount != null && i.amount != amount) return false;
        if (dateStr != null && dateStr.isNotEmpty) {
          final d =
              '${i.date.year}-${i.date.month.toString().padLeft(2, '0')}-${i.date.day.toString().padLeft(2, '0')}';
          if (d != dateStr) return false;
        }
        if (source != null && source.isNotEmpty) {
          if (i.source.toLowerCase() != source.toLowerCase().trim())
            return false;
        }
        return true;
      }).toList();

      if (candidates.isEmpty) {
        return '⚠️ No matching income found to delete.';
      }

      Income target;
      if (note != null && note.isNotEmpty) {
        final noteMatches = candidates
            .where(
              (i) => (i.note ?? '').toLowerCase().contains(note.toLowerCase()),
            )
            .toList();
        target = noteMatches.isNotEmpty ? noteMatches.first : candidates.first;
      } else {
        target = candidates.first;
      }

      await _ref.read(incomesProvider.notifier).deleteIncome(target.id);
      return '✅ Deleted income: ${target.source} \$${target.amount.toStringAsFixed(2)}';
    } catch (e) {
      return '⚠️ Failed to delete income: $e';
    }
  }

  Future<String> _deleteCategory(Map<String, dynamic> data) async {
    try {
      final name = data['name'] as String?;
      if (name == null || name.isEmpty) {
        return '⚠️ Could not delete category: name is required.';
      }

      final categories = _ref.read(categoriesProvider);
      final match =
          _findCategoryByName(categories, name, 'expense') ??
          _findCategoryByName(categories, name, 'income');

      if (match == null) {
        return '⚠️ Category "$name" does not exist.';
      }

      if (match.isDefault) {
        return '⚠️ Cannot delete default category "${match.name}".';
      }

      // Check if any transactions use this category
      final expenses = _ref.read(expensesProvider);
      final incomes = _ref.read(incomesProvider);
      final hasExpenses = expenses.any((e) => e.categoryId == match.id);
      final hasIncomes = incomes.any((i) => i.source == match.name);

      if (hasExpenses || hasIncomes) {
        return '⚠️ Cannot delete "${match.name}" — it has transactions attached. Remove those first.';
      }

      await _ref.read(categoriesProvider.notifier).deleteCategory(match.id);
      return '✅ Deleted category: ${match.name}';
    } catch (e) {
      return '⚠️ Failed to delete category: $e';
    }
  }

  /// Find a category by name (case-insensitive exact match, then contains).
  static Category? _findCategoryByName(
    List<Category> categories,
    String name,
    String type,
  ) {
    final lower = name.toLowerCase().trim();

    // Exact match
    for (final cat in categories) {
      if (cat.name.toLowerCase() == lower && cat.effectiveType == type) {
        return cat;
      }
    }

    // Contains match
    for (final cat in categories) {
      if (cat.name.toLowerCase().contains(lower) && cat.effectiveType == type) {
        return cat;
      }
    }

    // Reverse contains
    for (final cat in categories) {
      if (lower.contains(cat.name.toLowerCase()) && cat.effectiveType == type) {
        return cat;
      }
    }

    return null;
  }

  /// Find a wallet by name (case-insensitive exact match, then contains).
  static Wallet? _findWalletByName(List<Wallet> wallets, String name) {
    final lower = name.toLowerCase().trim();

    // Exact match
    for (final wallet in wallets) {
      if (wallet.name.toLowerCase() == lower) {
        return wallet;
      }
    }

    // Contains match
    for (final wallet in wallets) {
      if (wallet.name.toLowerCase().contains(lower)) {
        return wallet;
      }
    }

    return null;
  }

  int? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var clean = hex.trim();
    if (clean.startsWith('#')) clean = clean.substring(1);
    if (clean.length == 6) clean = 'FF$clean';
    if (clean.length != 8) return null;
    try {
      return int.parse(clean, radix: 16);
    } catch (_) {
      return null;
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier(ref);
});

final chatLoadingProvider = StateProvider<bool>((ref) => false);
