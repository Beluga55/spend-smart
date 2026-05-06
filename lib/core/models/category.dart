import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String iconName;

  @HiveField(3)
  int color;

  @HiveField(4)
  bool isDefault;

  @HiveField(5)
  String? categoryType; // 'expense' or 'income'

  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.color,
    this.isDefault = false,
    this.categoryType = 'expense',
  });

  /// Safe accessor that never returns null.
  String get effectiveType => categoryType ?? 'expense';

  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    int? color,
    bool? isDefault,
    String? categoryType,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      categoryType: categoryType ?? this.categoryType,
    );
  }
}
