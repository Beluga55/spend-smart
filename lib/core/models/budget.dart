import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int month;

  @HiveField(2)
  int year;

  @HiveField(3)
  double limitAmount;

  @HiveField(4)
  String? categoryId;

  @HiveField(5)
  int? day;

  Budget({
    required this.id,
    required this.month,
    required this.year,
    required this.limitAmount,
    this.categoryId,
    this.day,
  });

  Budget copyWith({
    String? id,
    int? month,
    int? year,
    double? limitAmount,
    String? categoryId,
    int? day,
  }) {
    return Budget(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      limitAmount: limitAmount ?? this.limitAmount,
      categoryId: categoryId ?? this.categoryId,
      day: day ?? this.day,
    );
  }
}
