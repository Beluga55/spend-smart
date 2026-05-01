import 'package:hive/hive.dart';

part 'recurring_expense.g.dart';

@HiveType(typeId: 5)
enum RecurringFrequency {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
  @HiveField(3)
  yearly,
}

@HiveType(typeId: 4)
class RecurringExpense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String categoryId;

  @HiveField(3)
  String? note;

  @HiveField(4)
  RecurringFrequency frequency;

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  DateTime? endDate;

  @HiveField(7)
  DateTime? lastCreated;

  @HiveField(8)
  bool isActive;

  RecurringExpense({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.lastCreated,
    this.isActive = true,
  });

  RecurringExpense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? note,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastCreated,
    bool? isActive,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastCreated: lastCreated ?? this.lastCreated,
      isActive: isActive ?? this.isActive,
    );
  }

  DateTime? getNextDueDate() {
    final DateTime baseDate = lastCreated ?? startDate;
    final DateTime now = DateTime.now();
    DateTime nextDue;

    switch (frequency) {
      case RecurringFrequency.daily:
        nextDue = DateTime(baseDate.year, baseDate.month, baseDate.day + 1);
        break;
      case RecurringFrequency.weekly:
        nextDue = baseDate.add(const Duration(days: 7));
        break;
      case RecurringFrequency.monthly:
        nextDue = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
        break;
      case RecurringFrequency.yearly:
        nextDue = DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
        break;
    }

    if (endDate != null && nextDue.isAfter(endDate!)) {
      return null;
    }

    return nextDue;
  }

  bool isDue() {
    if (!isActive) return false;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    if (lastCreated == null) {
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      return !startDay.isAfter(today);
    }

    final nextDue = getNextDueDate();
    if (nextDue == null) return false;

    final nextDueDay = DateTime(nextDue.year, nextDue.month, nextDue.day);
    return !nextDueDay.isAfter(today);
  }
}
