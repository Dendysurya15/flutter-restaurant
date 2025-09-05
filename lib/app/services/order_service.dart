import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:restaurant/app/data/models/payment_model.dart';
import 'package:restaurant/app/data/models/order_item_model.dart';
import 'package:restaurant/app/data/models/cart_item_model.dart';
import 'package:uuid/uuid.dart';

class OrderService extends GetxService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // Create complete order with payment
  Future<Map<String, dynamic>> createOrderWithPayment({
    required String customerId,
    required String storeId,
    required String orderType,
    required String customerName,
    required String customerPhone,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    required double subtotal,
    required double deliveryFee,
    required double totalAmount,
    required String paymentMethod,
    String? specialInstructions,
    required List<CartItemModel> cartItems,
  }) async {
    try {
      // Generate order number
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      final orderId = _uuid.v4();

      // 1. Create order
      final orderData = {
        'id': orderId,
        'customer_id': customerId,
        'store_id': storeId,
        'order_number': orderNumber,
        'order_type': orderType,
        'status': 'pending',
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        'delivery_latitude': deliveryLatitude,
        'delivery_longitude': deliveryLongitude,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'payment_status': paymentMethod == 'cash' ? 'pending' : 'pending',
        'special_instructions': specialInstructions,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final order = OrderModel.fromJson(orderResponse);

      // 2. Create order items
      final orderItems = <OrderItemModel>[];
      for (final cartItem in cartItems) {
        final orderItemData = {
          'id': _uuid.v4(),
          'order_id': orderId,
          'menu_item_id': cartItem.menuItemId,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.price,
          'total_price': cartItem.quantity * cartItem.price,
          'created_at': DateTime.now().toIso8601String(),
        };

        final orderItemResponse = await _supabase
            .from('order_items')
            .insert(orderItemData)
            .select()
            .single();

        orderItems.add(OrderItemModel.fromJson(orderItemResponse));
      }

      // 3. Create payment record
      final paymentData = {
        'id': _uuid.v4(),
        'order_id': orderId,
        'amount': totalAmount,
        'payment_method': _mapPaymentMethodForDatabase(paymentMethod),
        'payment_gateway': paymentMethod == 'cash' ? null : 'midtrans',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final paymentResponse = await _supabase
          .from('payments')
          .insert(paymentData)
          .select()
          .single();

      final payment = PaymentModel.fromJson(paymentResponse);

      return {
        'success': true,
        'order': order,
        'payment': payment,
        'order_items': orderItems,
        'message': 'Order created successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to create order: $e'};
    }
  }

  String _mapPaymentMethodForDatabase(String paymentMethod) {
    // Store the actual payment method, not just 'online'
    return paymentMethod;
  }

  // Update payment status
  Future<PaymentModel?> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      final response = await _supabase
          .from('payments')
          .update(updateData)
          .eq('id', paymentId)
          .select()
          .single();

      return PaymentModel.fromJson(response);
    } catch (e) {
      print('Error updating payment status: $e');
      return null;
    }
  }

  // Update order status and payment status
  Future<void> updateOrderAndPaymentStatus({
    required String orderId,
    required String orderStatus,
    required String paymentStatus,
  }) async {
    try {
      // Update order status
      await _supabase
          .from('orders')
          .update({
            'status': orderStatus,
            'payment_status': paymentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Update payment status
      await _supabase
          .from('payments')
          .update({
            'status': paymentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId);
    } catch (e) {
      print('Error updating order and payment status: $e');
    }
  }

  // Get order with payment details
  Future<Map<String, dynamic>?> getOrderWithPayment(String orderId) async {
    try {
      // Get order
      final orderResponse = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      final order = OrderModel.fromJson(orderResponse);

      // Get payment
      final paymentResponse = await _supabase
          .from('payments')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      PaymentModel? payment;
      if (paymentResponse != null) {
        payment = PaymentModel.fromJson(paymentResponse);
      }

      // Get order items
      final orderItemsResponse = await _supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      final orderItems = orderItemsResponse
          .map((item) => OrderItemModel.fromJson(item))
          .toList();

      return {'order': order, 'payment': payment, 'order_items': orderItems};
    } catch (e) {
      print('Error getting order with payment: $e');
      return null;
    }
  }

  // Get customer orders
  Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return response.map((order) => OrderModel.fromJson(order)).toList();
    } catch (e) {
      print('Error getting customer orders: $e');
      return [];
    }
  }
}
