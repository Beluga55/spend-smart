import 'package:hive/hive.dart';

part 'wallet_transfer.g.dart';

@HiveType(typeId: 8)
class WalletTransfer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String fromWalletId;

  @HiveField(2)
  String toWalletId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  String? note;

  @HiveField(6)
  DateTime createdAt;

  WalletTransfer({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
  });

  WalletTransfer copyWith({
    String? id,
    String? fromWalletId,
    String? toWalletId,
    double? amount,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return WalletTransfer(
      id: id ?? this.id,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
