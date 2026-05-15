import 'package:hive/hive.dart';

part 'group_expense_split.g.dart';

@HiveType(typeId: 12)
class GroupExpenseSplit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String groupExpenseId;

  @HiveField(2)
  String userId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  bool isSettled;

  @HiveField(5)
  DateTime? settledAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  String syncStatus;

  GroupExpenseSplit({
    required this.id,
    required this.groupExpenseId,
    required this.userId,
    required this.amount,
    this.isSettled = false,
    this.settledAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });

  GroupExpenseSplit copyWith({
    String? id,
    String? groupExpenseId,
    String? userId,
    double? amount,
    bool? isSettled,
    DateTime? settledAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return GroupExpenseSplit(
      id: id ?? this.id,
      groupExpenseId: groupExpenseId ?? this.groupExpenseId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
