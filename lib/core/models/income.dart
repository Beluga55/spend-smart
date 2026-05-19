import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 6)
class Income extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String source;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? note;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? walletId;

  @HiveField(7)
  String? groupExpenseId;

  Income({
    required this.id,
    required this.amount,
    required this.source,
    required this.date,
    this.note,
    required this.createdAt,
    this.walletId,
    this.groupExpenseId,
  });

  Income copyWith({
    String? id,
    double? amount,
    String? source,
    DateTime? date,
    String? note,
    DateTime? createdAt,
    String? walletId,
    String? groupExpenseId,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      walletId: walletId ?? this.walletId,
      groupExpenseId: groupExpenseId ?? this.groupExpenseId,
    );
  }
}
