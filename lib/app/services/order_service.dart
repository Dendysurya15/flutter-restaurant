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

  // Create complete order with payment (pickup only)
  Future<Map<String, dynamic>> createOrderWithPayment({
    required String customerId,
    required String storeId,
    required String customerName,
    required String customerPhone,
    required double subtotal,
    required double totalAmount,
    required String paymentMethod,
    String? specialInstructions,
    required List<CartItemModel> cartItems,
  }) async {
    try {
      // Generate order number
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
      final orderId = _uuid.v4();

      // 1. Create order (pickup only - removed delivery fields)
      final orderData = {
        'id': orderId,
        'customer_id': customerId,
        'store_id': storeId,
        'order_number': orderNumber,
        'order_type': 'pickup', // Always pickup
        'status': 'pending',
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'subtotal': subtotal,
        'total_amount': totalAmount, // Same as subtotal for pickup
        'payment_method': paymentMethod,
        'payment_status': 'pending',
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
          'special_instructions': cartItem.specialInstructions,
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
        'payment_gateway':
            'midtrans', // Always use midtrans for online payments
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
    // Store the actual payment method
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
      // Update order status with payment_status = 'paid'
      await _supabase
          .from('orders')
          .update({
            'status': orderStatus,
            'payment_status': paymentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Update payment status with status = 'completed'
      await _supabase
          .from('payments')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId);
    } catch (e) {
      print('Error updating order and payment status: $e');
    }
  }

  // Update order status with estimated cooking time
  Future<void> updateOrderStatusWithCookingTime({
    required String orderId,
    required String status,
    int? estimatedMinutes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add cooking time for certain status updates
      if (status == 'preparing' && estimatedMinutes != null) {
        updateData['estimated_cooking_time'] = DateTime.now()
            .add(Duration(minutes: estimatedMinutes))
            .toIso8601String();
        updateData['accepted_at'] = DateTime.now().toIso8601String();
      } else if (status == 'ready') {
        updateData['ready_at'] = DateTime.now().toIso8601String();
      } else if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('orders').update(updateData).eq('id', orderId);
    } catch (e) {
      print('Error updating order status with cooking time: $e');
    }
  }

  // Update order status (simple version)
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      print('Error updating order status: $e');
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

      // Get order items with menu item details
      final orderItemsResponse = await _supabase
          .from('order_items')
          .select('*, menu_items(name, description, image_url)')
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

  // Get store orders (for restaurant dashboard)
  Future<List<OrderModel>> getStoreOrders(String storeId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      return response.map((order) => OrderModel.fromJson(order)).toList();
    } catch (e) {
      print('Error getting store orders: $e');
      return [];
    }
  }

  // Get orders by status for restaurant
  Future<List<OrderModel>> getOrdersByStatus(
    String storeId,
    String status,
  ) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('store_id', storeId)
          .eq('status', status)
          .order('created_at', ascending: false);

      return response.map((order) => OrderModel.fromJson(order)).toList();
    } catch (e) {
      print('Error getting orders by status: $e');
      return [];
    }
  }

  // Accept order and set cooking time
  Future<void> acceptOrder(String orderId, int estimatedMinutes) async {
    await updateOrderStatusWithCookingTime(
      orderId: orderId,
      status: 'preparing',
      estimatedMinutes: estimatedMinutes,
    );
  }

  // Mark order as ready
  Future<void> markOrderReady(String orderId) async {
    await updateOrderStatusWithCookingTime(orderId: orderId, status: 'ready');
  }

  // Complete order (customer picked up)
  Future<void> completeOrder(String orderId) async {
    await updateOrderStatusWithCookingTime(
      orderId: orderId,
      status: 'completed',
    );
  }

  // Reject order
  Future<void> rejectOrder(String orderId) async {
    await updateOrderStatus(orderId, 'rejected');
  }

  // Get order statistics for restaurant dashboard
  Future<Map<String, int>> getOrderStats(String storeId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('status')
          .eq('store_id', storeId);

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'preparing': 0,
        'ready': 0,
        'completed': 0,
        'rejected': 0,
      };

      for (final order in response) {
        final status = order['status'] as String;
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error getting order stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'preparing': 0,
        'ready': 0,
        'completed': 0,
        'rejected': 0,
      };
    }
  }
}
