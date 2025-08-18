class CartItemModel {
  final String id;
  final String customerId;
  final String storeId;
  final String menuItemId;
  final int quantity;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItemModel({
    required this.id,
    required this.customerId,
    required this.storeId,
    required this.menuItemId,
    required this.quantity,
    this.specialInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      customerId: json['customer_id'],
      storeId: json['store_id'],
      menuItemId: json['menu_item_id'],
      quantity: json['quantity'],
      specialInstructions: json['special_instructions'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'store_id': storeId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
