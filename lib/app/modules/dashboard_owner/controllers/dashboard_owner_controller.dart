import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:toastification/toastification.dart';

class DashboardOwnerController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observable lists for different order statuses
  var allOrders = <dynamic>[].obs;
  var preparingOrders = <dynamic>[].obs;
  var readyOrders = <dynamic>[].obs;
  var completedOrders = <dynamic>[].obs;
  var rejectedOrders = <dynamic>[].obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    // Set up real-time subscription for orders
    _setupOrdersSubscription();
  }

  void _setupOrdersSubscription() {
    _supabase
        .channel('orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            print('Order change detected: ${payload.eventType}');
            fetchOrders(); // Refresh orders when changes occur
          },
        )
        .subscribe();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;

      // Get current user's store ID (assuming owner is logged in)
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Fetch user's store
      final storeResponse = await _supabase
          .from('stores')
          .select('id')
          .eq('owner_id', user.id)
          .limit(1)
          .single();

      if (storeResponse == null) return;

      final storeId = storeResponse['id'];

      // Fetch all orders for this store
      final ordersResponse = await _supabase
          .from('orders')
          .select('*')
          .eq('store_id', storeId)
          .order('created_at', ascending: false);

      // Convert to OrderModel objects
      final orders = ordersResponse.map((orderData) {
        return OrderModel.fromJson(orderData);
      }).toList();

      // Update observable lists
      allOrders.value = orders;
      preparingOrders.value = orders
          .where((order) => order.status == 'preparing')
          .toList();
      readyOrders.value = orders
          .where((order) => order.status == 'ready')
          .toList();
      completedOrders.value = orders
          .where((order) => order.status == 'completed')
          .toList();
      rejectedOrders.value = orders
          .where((order) => order.status == 'rejected')
          .toList();
    } catch (e) {
      print('Error fetching orders: $e');
      _showErrorToast('Failed to fetch orders');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptOrder(String orderId, int estimatedMinutes) async {
    try {
      final estimatedCookingTime = DateTime.now().add(
        Duration(minutes: estimatedMinutes),
      );

      await _supabase
          .from('orders')
          .update({
            'status': 'preparing',
            'accepted_at': DateTime.now().toIso8601String(),
            'estimated_cooking_time': estimatedCookingTime.toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessToast(
        'Order accepted! Estimated ready time: $estimatedMinutes minutes',
      );
      await fetchOrders();
    } catch (e) {
      print('Error accepting order: $e');
      _showErrorToast('Failed to accept order');
    }
  }

  Future<void> rejectOrder(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessToast('Order rejected');
      await fetchOrders();
    } catch (e) {
      print('Error rejecting order: $e');
      _showErrorToast('Failed to reject order');
    }
  }

  Future<void> markOrderAsReady(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'ready',
            'ready_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessToast('Order marked as ready for pickup!');
      await fetchOrders();
    } catch (e) {
      print('Error marking order as ready: $e');
      _showErrorToast('Failed to mark order as ready');
    }
  }

  Future<void> markOrderAsCompleted(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessToast('Order completed!');
      await fetchOrders();
    } catch (e) {
      print('Error completing order: $e');
      _showErrorToast('Failed to complete order');
    }
  }

  void _showSuccessToast(String message) {
    ToastHelper.showToast(
      context: Get.context!,
      title: "Success",
      description: message,
      type: ToastificationType.success,
    );
  }

  void _showErrorToast(String message) {
    ToastHelper.showToast(
      context: Get.context!,
      title: "Error",
      description: message,
      type: ToastificationType.error,
    );
  }

  @override
  void onClose() {
    // Clean up subscription
    _supabase.removeAllChannels();
    super.onClose();
  }
}
