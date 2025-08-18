class PaymentModel {
  final String id;
  final String orderId;
  final double amount;
  final String paymentMethod;
  final String? paymentGateway;
  final String? transactionId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    this.paymentGateway,
    this.transactionId,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      orderId: json['order_id'],
      amount: (json['amount']).toDouble(),
      paymentMethod: json['payment_method'],
      paymentGateway: json['payment_gateway'],
      transactionId: json['transaction_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_gateway': paymentGateway,
      'transaction_id': transactionId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
