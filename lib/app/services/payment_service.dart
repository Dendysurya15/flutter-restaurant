import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/services/order_service.dart';
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

  Future<Map<String, dynamic>> processPayment({
    required PaymentModel payment,
    required Map<String, dynamic> orderData,
  }) async {
    final paymentMethod = getPaymentMethodById(payment.paymentMethod);

    if (paymentMethod == null) {
      return {'success': false, 'message': 'Invalid payment method'};
    }

    if (paymentMethod.isOnline) {
      return await _processMidtransPayment(payment, orderData);
    } else {
      return await _processCashPayment(payment, orderData);
    }
  }

  Future<Map<String, dynamic>> _processMidtransPayment(
    PaymentModel payment,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final snapToken = await _getSnapTokenFromBackend(payment, orderData);

      if (snapToken == null) {
        throw Exception('Failed to get snap token');
      }

      // Use Completer to handle the callback-based API
      final completer = Completer<Map<String, dynamic>>();

      try {
        await MidtransSDK().startPaymentUiFlow(token: snapToken);

        // If no exception is thrown, assume payment was completed successfully
        await _orderService.updatePaymentStatus(
          paymentId: payment.id,
          status: 'completed',
          transactionId: 'midtrans_${DateTime.now().millisecondsSinceEpoch}',
        );

        await _orderService.updateOrderAndPaymentStatus(
          orderId: payment.orderId,
          orderStatus: 'confirmed',
          paymentStatus: 'paid',
        );

        return {
          'success': true,
          'message': 'Payment berhasil! Pesanan Anda sedang diproses.',
          'transaction_id': 'midtrans_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'completed',
        };
      } catch (paymentError) {
        // If exception is thrown, payment was cancelled/failed
        await _orderService.updatePaymentStatus(
          paymentId: payment.id,
          status: 'cancelled',
        );

        return {
          'success': false,
          'message': 'Pembayaran dibatalkan atau gagal.',
          'status': 'cancelled',
        };
      }
    } catch (e) {
      await _orderService.updatePaymentStatus(
        paymentId: payment.id,
        status: 'failed',
      );

      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
        'status': 'failed',
      };
    }
  }

  // Remove these methods since we're not using them anymore
  // _handleMidtransResult, _processTransactionStatus methods are removed

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
        'message':
            'Pesanan dikonfirmasi. Silakan bayar tunai saat pengambilan/pengantaran.',
        'transaction_id': 'cash_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memproses pembayaran tunai: $e',
        'status': 'failed',
      };
    }
  }

  Future<String?> _getSnapTokenFromBackend(
    PaymentModel payment,
    Map<String, dynamic> orderData,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return 'mock_snap_token_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      return null;
    }
  }

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
}
