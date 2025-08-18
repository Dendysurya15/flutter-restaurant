class DailySalesModel {
  final String id;
  final String storeId;
  final DateTime date;
  final int totalOrders;
  final double totalRevenue;
  final double onlinePayments;
  final double offlinePayments;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailySalesModel({
    required this.id,
    required this.storeId,
    required this.date,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.onlinePayments = 0,
    this.offlinePayments = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailySalesModel.fromJson(Map<String, dynamic> json) {
    return DailySalesModel(
      id: json['id'],
      storeId: json['store_id'],
      date: DateTime.parse(json['date']),
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      onlinePayments: (json['online_payments'] ?? 0).toDouble(),
      offlinePayments: (json['offline_payments'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'date': date.toIso8601String().split('T')[0], // Date only
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'online_payments': onlinePayments,
      'offline_payments': offlinePayments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
