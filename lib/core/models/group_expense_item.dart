import 'package:hive/hive.dart';

part 'group_expense_item.g.dart';

@HiveType(typeId: 13)
class GroupExpenseItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String groupExpenseId;

  @HiveField(2)
  String description;

  @HiveField(3)
  double amount;

  @HiveField(4)
  List<String> assignedToUserIds;

  @HiveField(5)
  DateTime updatedAt;

  GroupExpenseItem({
    required this.id,
    required this.groupExpenseId,
    required this.description,
    required this.amount,
    required this.assignedToUserIds,
    required this.updatedAt,
  });

  GroupExpenseItem copyWith({
    String? id,
    String? groupExpenseId,
    String? description,
    double? amount,
    List<String>? assignedToUserIds,
    DateTime? updatedAt,
  }) {
    return GroupExpenseItem(
      id: id ?? this.id,
      groupExpenseId: groupExpenseId ?? this.groupExpenseId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      assignedToUserIds: assignedToUserIds ?? this.assignedToUserIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
