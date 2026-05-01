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

  Income({
    required this.id,
    required this.amount,
    required this.source,
    required this.date,
    this.note,
    required this.createdAt,
  });

  Income copyWith({
    String? id,
    double? amount,
    String? source,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
