class MenuCategoryModel {
  final String? id;
  final String name;
  final String type;
  final bool isVeg;
  final int? sortOrder;
  final String? createdAt;

  MenuCategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.isVeg,
    this.sortOrder,
    this.createdAt,
  });

  factory MenuCategoryModel.fromMap(Map<String, dynamic> map) {
    return MenuCategoryModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      type: map['type'] as String,
      isVeg: map['is_veg'] == 1 || map['is_veg'] == true,
      sortOrder: map['sort_order'] as int?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'is_veg': isVeg ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  MenuCategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    bool? isVeg,
    int? sortOrder,
    String? createdAt,
  }) {
    return MenuCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isVeg: isVeg ?? this.isVeg,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
