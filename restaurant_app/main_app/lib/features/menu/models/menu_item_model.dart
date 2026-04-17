class MenuItemModel {
  final String? id;
  final String categoryId;
  final String name;
  final double price;
  final String? description;
  final String imagePath;
  final bool isVeg;
  final bool isLowStock;
  final int? sortOrder;
  final String? createdAt;

  MenuItemModel({
    this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    this.description,
    this.imagePath = '',
    this.isVeg = true,
    this.isLowStock = false,
    this.sortOrder,
    this.createdAt,
  });

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      id: map['id'] as String?,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
      imagePath: map['image_path'] as String? ?? '',
      isVeg: map['is_veg'] == 1 || map['is_veg'] == true,
      isLowStock: map['is_low_stock'] == 1 || map['is_low_stock'] == true,
      sortOrder: map['sort_order'] as int?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'price': price,
      'description': description,
      'image_path': imagePath,
      'is_veg': isVeg ? 1 : 0,
      'is_low_stock': isLowStock ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
  }

  MenuItemModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? price,
    String? description,
    String? imagePath,
    bool? isVeg,
    bool? isLowStock,
    int? sortOrder,
    String? createdAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      isVeg: isVeg ?? this.isVeg,
      isLowStock: isLowStock ?? this.isLowStock,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
