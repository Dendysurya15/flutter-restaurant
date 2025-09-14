import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:restaurant/app/services/order_service.dart';
import 'package:restaurant/app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class PaymentMethodOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isOnline;

  PaymentMethodOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.isOnline = true,
  });
}

class PaymentService extends GetxService {
  final OrderService _orderService = Get.find<OrderService>();

  static final List<PaymentMethodOption> _allPaymentMethods = [
    // E-Wallets
    PaymentMethodOption(
      id: 'gopay',
      name: 'GoPay',
      description: 'Bayar dengan GoPay',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF00AA5B),
    ),
    PaymentMethodOption(
      id: 'shopeepay',
      name: 'ShopeePay',
      description: 'Bayar dengan ShopeePay',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFFEE4D2D),
    ),
    PaymentMethodOption(
      id: 'dana',
      name: 'DANA',
      description: 'Bayar dengan DANA',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF118EEA),
    ),
    PaymentMethodOption(
      id: 'ovo',
      name: 'OVO',
      description: 'Bayar dengan OVO',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF4C3494),
    ),
    // QR Code Payment
    PaymentMethodOption(
      id: 'qris',
      name: 'QRIS',
      description: 'Scan QR Code untuk bayar',
      icon: Icons.qr_code,
      color: const Color(0xFF1976d2),
    ),
    // Virtual Accounts
    PaymentMethodOption(
      id: 'bca_va',
      name: 'BCA Virtual Account',
      description: 'Transfer via BCA Virtual Account',
      icon: Icons.account_balance,
      color: const Color(0xFF003d6b),
    ),
    PaymentMethodOption(
      id: 'bni_va',
      name: 'BNI Virtual Account',
      description: 'Transfer via BNI Virtual Account',
      icon: Icons.account_balance,
      color: const Color(0xFFf57c00),
    ),
    PaymentMethodOption(
      id: 'bri_va',
      name: 'BRI Virtual Account',
      description: 'Transfer via BRI Virtual Account',
      icon: Icons.account_balance,
      color: const Color(0xFF003d82),
    ),
    // Credit Cards
    PaymentMethodOption(
      id: 'credit_card',
      name: 'Credit/Debit Card',
      description: 'Visa, Mastercard, JCB',
      icon: Icons.credit_card,
      color: Colors.purple,
    ),
    // Convenience Stores
    PaymentMethodOption(
      id: 'indomaret',
      name: 'Indomaret',
      description: 'Bayar di Indomaret',
      icon: Icons.store,
      color: const Color(0xFF0066cc),
    ),
    PaymentMethodOption(
      id: 'alfamart',
      name: 'Alfamart',
      description: 'Bayar di Alfamart',
      icon: Icons.store,
      color: const Color(0xFFff6600),
    ),
    // Cash
    PaymentMethodOption(
      id: 'cash',
      name: 'Cash',
      description: 'Bayar tunai di tempat',
      icon: Icons.money,
      color: Colors.green,
      isOnline: false,
    ),
  ];

  List<PaymentMethodOption> getAvailablePaymentMethods(String orderType) {
    if (orderType == 'dine_in') {
      return _allPaymentMethods;
    } else {
      return _allPaymentMethods.where((method) => method.id != 'cash').toList();
    }
  }

  PaymentMethodOption? getPaymentMethodById(String id) {
    return _allPaymentMethods.firstWhereOrNull((method) => method.id == id);
  }

  Future<void> expirePayment(String paymentId, String orderId) async {
    try {
      // Update payment status to failed (not expired)
      await Supabase.instance.client
          .from('payments')
          .update({
            'status': 'failed', // Changed from 'expired' to 'failed'
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);

      // Update order status to failed and payment_status to failed
      await Supabase.instance.client
          .from('orders')
          .update({
            'status': 'cancelled',
            'payment_status': 'failed', // Changed from 'expired' to 'failed'
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      print('✅ Payment and order updated to failed status');
    } catch (e) {
      print('❌ Error expiring payment: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> processPayment({
    required PaymentModel payment,
    required Map<String, dynamic> orderData,
  }) async {
    final paymentMethod = getPaymentMethodById(payment.paymentMethod);

    if (paymentMethod == null) {
      return {'success': false, 'message': 'Invalid payment method'};
    }

    if (paymentMethod.isOnline) {
      // For online payments, return a token that the controller will use
      // The actual payment processing is now handled by the PaymentController with WebView
      try {
        final snapToken = await getSnapTokenFromBackend(payment, orderData);

        if (snapToken == null) {
          return {
            'success': false,
            'message': 'Failed to generate payment token',
            'status': 'token_error',
          };
        }

        return {
          'success': true,
          'message': 'Payment token generated successfully',
          'snap_token': snapToken,
          'status': 'token_ready',
          'payment_url':
              'https://app.sandbox.midtrans.com/snap/v4/redirection/$snapToken',
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Error generating payment token: $e',
          'status': 'token_error',
        };
      }
    } else {
      // For cash payments, process normally
      return await _processCashPayment(payment, orderData);
    }
  }

  Future<Map<String, dynamic>> _processCashPayment(
    PaymentModel payment,
    Map<String, dynamic> orderData,
  ) async {
    try {
      await _orderService.updatePaymentStatus(
        paymentId: payment.id,
        status: 'pending',
        transactionId: 'cash_${DateTime.now().millisecondsSinceEpoch}',
      );

      return {
        'success': true,
        'message': 'Order confirmed. Please pay cash upon pickup/delivery.',
        'transaction_id': 'cash_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to process cash payment: $e',
        'status': 'failed',
      };
    }
  }

  Future<String?> getSnapTokenFromBackend(
    PaymentModel payment,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final order = orderData['order'] as OrderModel;

      print('🔄 Creating snap token for order: ${order.orderNumber}');

      // Prepare transaction data for Midtrans
      final transactionData = {
        'transaction_details': {
          'order_id': order.orderNumber, // Use order number as transaction ID
          'gross_amount': payment.amount.toInt(),
        },
        'customer_details': {
          'first_name': order.customerName.split(' ').first,
          'last_name': order.customerName.split(' ').length > 1
              ? order.customerName.split(' ').skip(1).join(' ')
              : '',
          'email':
              'customer@example.com', // You might want to get this from user data
          'phone': order.customerPhone,
        },
        'item_details': [
          {
            'id': 'order_${order.id}',
            'price': payment.amount.toInt(),
            'quantity': 1,
            'name': 'Order from Restaurant - ${order.orderNumber}',
          },
        ],
        'enabled_payments': _getEnabledPayments(payment.paymentMethod),
      };

      print('📝 Transaction data: ${jsonEncode(transactionData)}');

      // Create snap token using Midtrans Snap API
      final snapToken = await _createSnapToken(transactionData);

      return snapToken;
    } catch (e) {
      print('❌ Error getting snap token: $e');
      return null;
    }
  }

  List<String> _getEnabledPayments(String paymentMethod) {
    switch (paymentMethod) {
      case 'gopay':
        return ['gopay'];
      case 'shopeepay':
        return ['shopeepay'];
      case 'dana':
        return ['dana'];
      case 'ovo':
        return ['ovo'];
      case 'qris':
        return ['qris'];
      case 'bca_va':
        return ['bank_transfer'];
      case 'bni_va':
        return ['bank_transfer'];
      case 'bri_va':
        return ['bank_transfer'];
      case 'credit_card':
        return ['credit_card'];
      case 'indomaret':
        return ['cstore'];
      case 'alfamart':
        return ['cstore'];
      default:
        return [
          'gopay',
          'shopeepay',
          'dana',
          'ovo',
          'qris',
          'bank_transfer',
          'credit_card',
        ];
    }
  }

  Future<String?> _createSnapToken(Map<String, dynamic> transactionData) async {
    try {
      // For sandbox/development, use this URL
      const snapApiUrl =
          'https://app.sandbox.midtrans.com/snap/v1/transactions';

      // Get server key from environment (YOUR ACTUAL KEY)
      final serverKey = dotenv.env['MIDTRANS_SERVER_KEY'];

      if (serverKey == null || serverKey.isEmpty) {
        throw Exception('MIDTRANS_SERVER_KEY not found in environment');
      }

      print('🔑 Using server key: ${serverKey.substring(0, 15)}...');

      final response = await http.post(
        Uri.parse(snapApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$serverKey:'))}',
          'Accept': 'application/json',
        },
        body: jsonEncode(transactionData),
      );

      print('📡 Snap API response status: ${response.statusCode}');
      print('📡 Snap API response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['token'];
      } else {
        print('❌ Failed to create snap token: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating snap token: $e');
      return null;
    }
  }

  // Rest of your existing methods...
  Future<void> handlePaymentNotification(
    Map<String, dynamic> notification,
  ) async {
    try {
      final orderId = notification['order_id'];
      final transactionStatus = notification['transaction_status'];
      final fraudStatus = notification['fraud_status'];

      String paymentStatus = 'pending';
      String orderStatus = 'pending';

      if (transactionStatus == 'capture') {
        if (fraudStatus == 'challenge') {
          paymentStatus = 'challenge';
          orderStatus = 'pending';
        } else if (fraudStatus == 'accept') {
          paymentStatus = 'completed';
          orderStatus = 'confirmed';
        }
      } else if (transactionStatus == 'settlement') {
        paymentStatus = 'completed';
        orderStatus = 'confirmed';
      } else if (transactionStatus == 'pending') {
        paymentStatus = 'pending';
        orderStatus = 'pending';
      } else if (transactionStatus == 'deny') {
        paymentStatus = 'failed';
        orderStatus = 'cancelled';
      } else if (transactionStatus == 'expire') {
        paymentStatus = 'expired';
        orderStatus = 'cancelled';
      } else if (transactionStatus == 'cancel') {
        paymentStatus = 'cancelled';
        orderStatus = 'cancelled';
      }

      await _orderService.updateOrderAndPaymentStatus(
        orderId: orderId,
        orderStatus: orderStatus,
        paymentStatus: paymentStatus,
      );
    } catch (e) {
      print('Error handling payment notification: $e');
    }
  }

  // Your existing methods for timer integration...
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final currentUserId = Get.find<AuthService>().currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await Supabase.instance.client
          .from('orders')
          .select('''
            *,
            payments (*)
          ''')
          .eq('customer_id', currentUserId)
          .eq('payment_status', 'pending')
          .inFilter('status', ['pending', 'confirmed']);

      List<Map<String, dynamic>> pendingPayments = [];

      for (final orderData in response) {
        final order = OrderModel.fromJson(orderData);
        final paymentData = orderData['payments'];

        if (paymentData != null && paymentData.isNotEmpty) {
          final payment = PaymentModel.fromJson(paymentData[0]);

          final timeSinceCreated = DateTime.now().difference(payment.createdAt);
          final remainingSeconds = 900 - timeSinceCreated.inSeconds;

          if (remainingSeconds > 0) {
            pendingPayments.add({
              'order': order,
              'payment': payment,
              'remaining_seconds': remainingSeconds,
            });
          }
        }
      }

      return pendingPayments;
    } catch (e) {
      print('Error getting pending payments: $e');
      return [];
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      switch (status.toLowerCase()) {
        case 'accepted':
        case 'confirmed':
          updateData['accepted_at'] = DateTime.now().toIso8601String();
          break;
        case 'ready':
          updateData['ready_at'] = DateTime.now().toIso8601String();
          break;
        case 'completed':
          updateData['completed_at'] = DateTime.now().toIso8601String();
          break;
        case 'cancelled':
          await _updateOrderPaymentStatus(orderId, 'cancelled');
          break;
      }

      await Supabase.instance.client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);
    } catch (e) {
      print('Error updating order status: $e');
      throw e;
    }
  }

  Future<void> _updateOrderPaymentStatus(
    String orderId,
    String paymentStatus,
  ) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({
            'payment_status': paymentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      print('Error updating order payment status: $e');
      throw e;
    }
  }
}
