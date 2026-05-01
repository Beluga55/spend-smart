import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/saving_goal.dart';
import 'package:uuid/uuid.dart';

final savingGoalBoxProvider = Provider<Box<SavingGoal>>((ref) {
  return Hive.box<SavingGoal>('saving_goals');
});

final savingGoalsProvider = StateNotifierProvider<SavingGoalsNotifier, List<SavingGoal>>((ref) {
  final box = ref.watch(savingGoalBoxProvider);
  return SavingGoalsNotifier(box);
});

class SavingGoalsNotifier extends StateNotifier<List<SavingGoal>> {
  final Box<SavingGoal> _box;

  SavingGoalsNotifier(this._box) : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.toList();
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    required String iconName,
    required int color,
  }) async {
    const uuid = Uuid();
    final goal = SavingGoal(
      id: uuid.v4(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      iconName: iconName,
      color: color,
      createdAt: DateTime.now(),
    );
    await _box.put(goal.id, goal);
    _refresh();
  }

  Future<void> updateGoal(SavingGoal goal) async {
    await _box.put(goal.id, goal);
    _refresh();
  }

  Future<void> deleteGoal(String id) async {
    await _box.delete(id);
    _refresh();
  }

  Future<void> addToGoal(String id, double amount) async {
    final goal = _box.get(id);
    if (goal != null) {
      final updated = goal.copyWith(currentAmount: goal.currentAmount + amount);
      await _box.put(id, updated);
      _refresh();
    }
  }

  Future<void> withdrawFromGoal(String id, double amount) async {
    final goal = _box.get(id);
    if (goal != null) {
      final newAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);
      final updated = goal.copyWith(currentAmount: newAmount);
      await _box.put(id, updated);
      _refresh();
    }
  }
}

final totalSavingsProvider = Provider<double>((ref) {
  final goals = ref.watch(savingGoalsProvider);
  return goals.fold(0, (sum, goal) => sum + goal.currentAmount);
});

final completedGoalsProvider = Provider<List<SavingGoal>>((ref) {
  final goals = ref.watch(savingGoalsProvider);
  return goals.where((g) => g.isCompleted).toList();
});

final activeGoalsProvider = Provider<List<SavingGoal>>((ref) {
  final goals = ref.watch(savingGoalsProvider);
  return goals.where((g) => !g.isCompleted).toList();
});