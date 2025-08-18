class MenuItemModel {
  final String id;
  final String storeId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int? preparationTime;
  final bool isVegetarian;
  final bool isSpicy;
  final bool isAvailable;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItemModel({
    required this.id,
    required this.storeId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.preparationTime,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.isAvailable = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      storeId: json['store_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price']).toDouble(),
      imageUrl: json['image_url'],
      preparationTime: json['preparation_time'],
      isVegetarian: json['is_vegetarian'] ?? false,
      isSpicy: json['is_spicy'] ?? false,
      isAvailable: json['is_available'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'preparation_time': preparationTime,
      'is_vegetarian': isVegetarian,
      'is_spicy': isSpicy,
      'is_available': isAvailable,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
