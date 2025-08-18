class MenuCategoryModel {
  final String id;
  final String storeId;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  MenuCategoryModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: json['id'],
      storeId: json['store_id'],
      name: json['name'],
      description: json['description'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'name': name,
      'description': description,
      'sort_order': sortOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
