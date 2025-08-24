import 'package:hive/hive.dart';

part 'cart_item_model.g.dart';

@HiveType(typeId: 0)
class CartItemModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String storeId;

  @HiveField(3)
  final String menuItemId;

  @HiveField(4)
  final int quantity;

  @HiveField(5)
  final double price;

  @HiveField(6)
  final String? specialInstructions;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  CartItemModel({
    required this.id,
    required this.customerId,
    required this.storeId,
    required this.menuItemId,
    required this.quantity,
    required this.price,
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
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] ?? 0.0),
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
      'price': price,
      'special_instructions': specialInstructions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CartItemModel copyWith({
    String? id,
    String? customerId,
    String? storeId,
    String? menuItemId,
    int? quantity,
    double? price,
    String? specialInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      storeId: storeId ?? this.storeId,
      menuItemId: menuItemId ?? this.menuItemId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
