import 'package:hive/hive.dart';

part 'group_expense.g.dart';

@HiveType(typeId: 11)
class GroupExpense extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String groupId;

  @HiveField(2)
  String description;

  @HiveField(3)
  double totalAmount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String paidByUserId;

  @HiveField(6)
  String? receiptImagePath;

  @HiveField(7)
  String syncStatus;

  @HiveField(8)
  String? supabaseId;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  GroupExpense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.totalAmount,
    required this.date,
    required this.paidByUserId,
    this.receiptImagePath,
    this.syncStatus = 'pending',
    this.supabaseId,
    required this.createdAt,
    required this.updatedAt,
  });

  GroupExpense copyWith({
    String? id,
    String? groupId,
    String? description,
    double? totalAmount,
    DateTime? date,
    String? paidByUserId,
    String? receiptImagePath,
    String? syncStatus,
    String? supabaseId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupExpense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      syncStatus: syncStatus ?? this.syncStatus,
      supabaseId: supabaseId ?? this.supabaseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
