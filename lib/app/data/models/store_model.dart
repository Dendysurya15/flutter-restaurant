class StoreModel {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String? description;
  final String? imageUrl;
  final String? address;
  final String? phone;
  final Map<String, dynamic>? openingHours;
  final bool deliveryAvailable;
  final bool dineInAvailable;
  final double deliveryFee;
  final double minimumOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoreModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    this.description,
    this.imageUrl,
    this.address,
    this.phone,
    this.openingHours,
    this.deliveryAvailable = true,
    this.dineInAvailable = true,
    this.deliveryFee = 0,
    this.minimumOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      imageUrl: json['image_url'],
      address: json['address'],
      phone: json['phone'],
      openingHours: json['opening_hours'],
      deliveryAvailable: json['delivery_available'] ?? true,
      dineInAvailable: json['dine_in_available'] ?? true,
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      minimumOrder: (json['minimum_order'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'address': address,
      'phone': phone,
      'opening_hours': openingHours,
      'delivery_available': deliveryAvailable,
      'dine_in_available': dineInAvailable,
      'delivery_fee': deliveryFee,
      'minimum_order': minimumOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
