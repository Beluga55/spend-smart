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
    DateTime nextDue;

    switch (frequency) {
      case RecurringFrequency.daily:
        nextDue = DateTime(baseDate.year, baseDate.month, baseDate.day + 1);
        break;
      case RecurringFrequency.weekly:
        nextDue = baseDate.add(const Duration(days: 7));
        break;
      case RecurringFrequency.monthly:
        nextDue = _addMonthsSafe(baseDate, 1);
        break;
      case RecurringFrequency.yearly:
        nextDue = _addYearsSafe(baseDate, 1);
        break;
    }

    if (endDate != null && nextDue.isAfter(endDate!)) {
      return null;
    }

    return nextDue;
  }

  DateTime _addMonthsSafe(DateTime date, int months) {
    final targetMonth = date.month + months;
    final targetYear = date.year + (targetMonth - 1) ~/ 12;
    final actualMonth = ((targetMonth - 1) % 12) + 1;
    final lastDayOfMonth = DateTime(targetYear, actualMonth + 1, 0).day;
    final targetDay = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
    return DateTime(targetYear, actualMonth, targetDay);
  }

  DateTime _addYearsSafe(DateTime date, int years) {
    final targetYear = date.year + years;
    if (date.month == 2 && date.day == 29) {
      final isLeap = (targetYear % 4 == 0 && targetYear % 100 != 0) || (targetYear % 400 == 0);
      if (!isLeap) return DateTime(targetYear, 2, 28);
    }
    return DateTime(targetYear, date.month, date.day);
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
