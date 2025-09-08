class OrderModel {
  final String id;
  final String customerId;
  final String storeId;
  final String orderNumber;
  final String orderType; // 'pickup' only (removed delivery)
  final String
  status; // 'pending', 'preparing', 'ready', 'completed', 'rejected'
  final String customerName;
  final String customerPhone;
  final double subtotal;
  final double totalAmount;
  final String paymentMethod; // 'online' or 'offline'
  final String paymentStatus; // 'pending', 'paid', etc.
  final String? specialInstructions;
  final DateTime?
  estimatedCookingTime; // Changed from deliveryTime to cookingTime
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
    this.orderType = 'pickup', // Default to pickup
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.subtotal,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.specialInstructions,
    this.estimatedCookingTime,
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
      orderType: json['order_type'] ?? 'pickup',
      status: json['status'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      subtotal: (json['subtotal']).toDouble(),
      totalAmount: (json['total_amount']).toDouble(),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'pending',
      specialInstructions: json['special_instructions'],
      estimatedCookingTime: json['estimated_cooking_time'] != null
          ? DateTime.parse(json['estimated_cooking_time'])
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
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'special_instructions': specialInstructions,
      'estimated_cooking_time': estimatedCookingTime?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'ready_at': readyAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get time until ready
  Duration? get timeUntilReady {
    if (estimatedCookingTime == null) return null;
    final now = DateTime.now();
    if (estimatedCookingTime!.isBefore(now)) return null;
    return estimatedCookingTime!.difference(now);
  }

  // Helper method to check if order is overdue
  bool get isOverdue {
    if (estimatedCookingTime == null || status != 'preparing') return false;
    return DateTime.now().isAfter(estimatedCookingTime!);
  }

  // Helper method to get status color
  String get statusColor {
    switch (status) {
      case 'pending':
        return '#FFA726'; // Orange
      case 'preparing':
        return '#42A5F5'; // Blue
      case 'ready':
        return '#FF7043'; // Deep Orange
      case 'completed':
        return '#66BB6A'; // Green
      case 'rejected':
        return '#EF5350'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Helper method to get readable status text
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Waiting for Confirmation';
      case 'preparing':
        return 'Cooking in Progress';
      case 'ready':
        return 'Ready for Pickup';
      case 'completed':
        return 'Order Completed';
      case 'rejected':
        return 'Order Rejected';
      default:
        return status.toUpperCase();
    }
  }

  // Copy with method for easy updates
  OrderModel copyWith({
    String? id,
    String? customerId,
    String? storeId,
    String? orderNumber,
    String? orderType,
    String? status,
    String? customerName,
    String? customerPhone,
    double? subtotal,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? specialInstructions,
    DateTime? estimatedCookingTime,
    DateTime? acceptedAt,
    DateTime? readyAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      storeId: storeId ?? this.storeId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      estimatedCookingTime: estimatedCookingTime ?? this.estimatedCookingTime,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      readyAt: readyAt ?? this.readyAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
