import 'package:hive/hive.dart';

part 'wallet.g.dart';

@HiveType(typeId: 7)
class Wallet extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconName;

  @HiveField(3)
  int color;

  @HiveField(4)
  String type;

  @HiveField(5)
  bool isDefault;

  @HiveField(6)
  DateTime createdAt;

  Wallet({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    required this.type,
    this.isDefault = false,
    required this.createdAt,
  });

  Wallet copyWith({
    String? id,
    String? name,
    String? iconName,
    int? color,
    String? type,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
