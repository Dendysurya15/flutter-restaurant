class OrderModel {
  final String id;
  final String customerId;
  final String storeId;
  final String orderNumber;
  final String orderType; // 'dine_in' or 'delivery'
  final String status; // 'pending', 'accepted', 'declined', etc.
  final String customerName;
  final String customerPhone;
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String paymentMethod; // 'online' or 'offline'
  final String paymentStatus; // 'pending', 'paid', etc.
  final String? specialInstructions;
  final DateTime? estimatedDeliveryTime;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.storeId,
    required this.orderNumber,
    required this.orderType,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.subtotal,
    this.deliveryFee = 0,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.specialInstructions,
    this.estimatedDeliveryTime,
    this.acceptedAt,
    this.readyAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      customerId: json['customer_id'],
      storeId: json['store_id'],
      orderNumber: json['order_number'],
      orderType: json['order_type'],
      status: json['status'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      deliveryAddress: json['delivery_address'],
      deliveryLatitude: json['delivery_latitude']?.toDouble(),
      deliveryLongitude: json['delivery_longitude']?.toDouble(),
      subtotal: (json['subtotal']).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      totalAmount: (json['total_amount']).toDouble(),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'pending',
      specialInstructions: json['special_instructions'],
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'])
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      readyAt: json['ready_at'] != null
          ? DateTime.parse(json['ready_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'store_id': storeId,
      'order_number': orderNumber,
      'order_type': orderType,
      'status': status,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'special_instructions': specialInstructions,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'ready_at': readyAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
