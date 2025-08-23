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
      openingHours: json['opening_hours'] != null
          ? Map<String, dynamic>.from(json['opening_hours'])
          : null,
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

  // NEW: Opening hours helper methods
  bool get isOpenNow {
    if (openingHours == null) return true;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday).toLowerCase();
    final todayHours = openingHours![dayName];

    if (todayHours == null || todayHours == 'closed') return false;

    try {
      final parts = todayHours.split('-');
      if (parts.length != 2) return true;

      final openParts = parts[0].split(':');
      final closeParts = parts[1].split(':');

      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);

      final currentHour = now.hour;
      final currentMinute = now.minute;
      final currentTotalMinutes = currentHour * 60 + currentMinute;
      final openTotalMinutes = openHour * 60 + openMinute;
      final closeTotalMinutes = closeHour * 60 + closeMinute;

      if (openTotalMinutes <= closeTotalMinutes) {
        return currentTotalMinutes >= openTotalMinutes &&
            currentTotalMinutes <= closeTotalMinutes;
      } else {
        return currentTotalMinutes >= openTotalMinutes ||
            currentTotalMinutes <= closeTotalMinutes;
      }
    } catch (e) {
      return true;
    }
  }

  String get currentStatus {
    if (!isActive) return 'Closed';
    if (!isOpenNow) return 'Closed';
    return 'Open';
  }

  String? getTodayHours() {
    if (openingHours == null) return 'No hours';

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday).toLowerCase();
    final todayHours = openingHours![dayName];

    if (todayHours == null || todayHours == 'closed') {
      return 'Closed today';
    }

    return todayHours;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }
}
