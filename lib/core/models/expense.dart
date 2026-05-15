import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String categoryId;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? note;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? walletId;

  @HiveField(7)
  String? receiptImagePath;

  @HiveField(8)
  String? groupId;

  @HiveField(9)
  String? groupExpenseId;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.note,
    required this.createdAt,
    this.walletId,
    this.receiptImagePath,
    this.groupId,
    this.groupExpenseId,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    String? walletId,
    String? receiptImagePath,
    String? groupId,
    String? groupExpenseId,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      walletId: walletId ?? this.walletId,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      groupId: groupId ?? this.groupId,
      groupExpenseId: groupExpenseId ?? this.groupExpenseId,
    );
  }
}
