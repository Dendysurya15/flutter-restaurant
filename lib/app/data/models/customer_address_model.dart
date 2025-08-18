class CustomerAddressModel {
  final String id;
  final String customerId;
  final String title;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;

  CustomerAddressModel({
    required this.id,
    required this.customerId,
    required this.title,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) {
    return CustomerAddressModel(
      id: json['id'],
      customerId: json['customer_id'],
      title: json['title'],
      addressLine1: json['address_line_1'],
      addressLine2: json['address_line_2'],
      city: json['city'],
      postalCode: json['postal_code'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'title': title,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
