import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/recurring_expense.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';

class RecurringSyncService {
  final Ref ref;

  RecurringSyncService(this.ref);

  Future<void> syncRecurringToCloud(RecurringExpense recurring) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final client = SupabaseService.client;

    await client.from('recurring_expenses').upsert({
      'id': recurring.id,
      'user_id': userId,
      'amount': recurring.amount,
      'category_id': recurring.categoryId,
      'note': recurring.note,
      'frequency': recurring.frequency.name,
      'start_date': recurring.startDate.toIso8601String().split('T').first,
      'end_date': recurring.endDate?.toIso8601String().split('T').first,
      'last_created': recurring.lastCreated?.toIso8601String().split('T').first,
      'is_active': recurring.isActive,
    });
  }

  Future<void> deleteRecurringFromCloud(String id) async {
    final client = SupabaseService.client;
    await client.from('recurring_expenses').delete().eq('id', id);
  }

  Future<void> pullCloudRecurrings() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final client = SupabaseService.client;
    final recurringBox = Hive.box<RecurringExpense>('recurring_expenses');

    final response = await client
        .from('recurring_expenses')
        .select()
        .eq('user_id', userId);

    final cloudRecurrings = response as List;

    for (final r in cloudRecurrings) {
      final existing = recurringBox.get(r['id']);
      if (existing == null) {
        final recurring = RecurringExpense(
          id: r['id'],
          amount: (r['amount'] as num).toDouble(),
          categoryId: r['category_id'],
          note: r['note'],
          frequency: RecurringFrequency.values.firstWhere(
            (f) => f.name == r['frequency'],
            orElse: () => RecurringFrequency.monthly,
          ),
          startDate: DateTime.parse(r['start_date']),
          endDate: r['end_date'] != null ? DateTime.parse(r['end_date']) : null,
          lastCreated: r['last_created'] != null ? DateTime.parse(r['last_created']) : null,
          isActive: r['is_active'] ?? true,
        );
        await recurringBox.put(recurring.id, recurring);
      }
    }
  }

  Future<void> pullCloudExpenses() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final client = SupabaseService.client;
    final expenseBox = Hive.box<Expense>('expenses');
    final recurringBox = Hive.box<RecurringExpense>('recurring_expenses');

    final response = await client
        .from('expenses')
        .select()
        .eq('user_id', userId)
        .not('recurring_id', 'is', null);

    final cloudExpenses = response as List;

    for (final e in cloudExpenses) {
      final existing = expenseBox.get(e['id']);
      if (existing == null) {
        final expense = Expense(
          id: e['id'],
          amount: (e['amount'] as num).toDouble(),
          categoryId: e['category_id'],
          date: DateTime.parse(e['date']),
          note: e['note'],
          createdAt: DateTime.parse(e['created_at']),
        );
        await expenseBox.put(expense.id, expense);

        final recurringId = e['recurring_id'];
        if (recurringId != null) {
          final recurring = recurringBox.get(recurringId);
          if (recurring != null) {
            final updated = recurring.copyWith(lastCreated: expense.date);
            await recurringBox.put(recurring.id, updated);
          }
        }
      }
    }
  }

  Future<void> syncAll() async {
    await pullCloudRecurrings();
    await pullCloudExpenses();
  }
}

final recurringSyncServiceProvider = Provider<RecurringSyncService>((ref) {
  return RecurringSyncService(ref);
});
