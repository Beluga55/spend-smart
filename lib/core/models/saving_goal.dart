import 'package:hive/hive.dart';

part 'saving_goal.g.dart';

@HiveType(typeId: 3)
class SavingGoal extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double currentAmount;

  @HiveField(4)
  DateTime? deadline;

  @HiveField(5)
  String iconName;

  @HiveField(6)
  int color;

  @HiveField(7)
  DateTime createdAt;

  SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    required this.iconName,
    required this.color,
    required this.createdAt,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  bool get isCompleted => currentAmount >= targetAmount;

  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    final days = deadline!.difference(now).inDays;
    return days < 0 ? 0 : days;
  }

  SavingGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? iconName,
    int? color,
    DateTime? createdAt,
    bool clearDeadline = false,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}