import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class DashboardOwnerController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Observable lists for different order statuses
  var allOrders = <OrderModel>[].obs;
  var preparingOrders = <OrderModel>[].obs;
  var readyOrders = <OrderModel>[].obs;
  var completedOrders = <OrderModel>[].obs;
  var rejectedOrders = <OrderModel>[].obs;

  // Track new orders for UI highlighting (shows green border and NEW ORDER label)
  var newOrderIds = <String>[].obs;

  // Loading state
  var isLoading = false.obs;

  // Track previous order IDs to detect truly new orders
  List<String> _previousOrderIds = [];

  // Store ID for the current owner
  String? _currentStoreId;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
    _getCurrentStoreId().then((_) {
      fetchOrders();
      _setupOrdersSubscription();
    });
  }

  /// Initialize notification system
  Future<void> _initializeNotifications() async {
    print('🔔 Initializing notifications...');

    // Android notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS notification settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    // Request permissions for Android 13+
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      print('✅ Notification permissions requested');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Channel for new orders (high priority)
    const AndroidNotificationChannel newOrdersChannel =
        AndroidNotificationChannel(
          'new_orders',
          'New Orders',
          description: 'High priority notifications for new incoming orders',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.green,
          showBadge: true,
        );

    // Channel for order ready notifications
    const AndroidNotificationChannel orderReadyChannel =
        AndroidNotificationChannel(
          'order_ready',
          'Order Ready',
          description: 'Notifications when orders are ready for pickup',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

    // Channel for general status updates
    const AndroidNotificationChannel statusUpdatesChannel =
        AndroidNotificationChannel(
          'status_updates',
          'Order Status Updates',
          description: 'General notifications for order status changes',
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
        );

    // Create the channels
    await androidPlugin.createNotificationChannel(newOrdersChannel);
    await androidPlugin.createNotificationChannel(orderReadyChannel);
    await androidPlugin.createNotificationChannel(statusUpdatesChannel);

    print('✅ Notification channels created');
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final Map<String, dynamic> payload = json.decode(response.payload!);

        // Navigate based on notification type
        switch (payload['type']) {
          case 'new_order':
            // Navigate to dashboard and refresh orders
            Get.toNamed('/dashboard-owner');
            fetchOrders();
            break;
          case 'order_ready':
            Get.toNamed('/dashboard-owner');
            fetchOrders();
            break;
          default:
            fetchOrders();
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
        fetchOrders();
      }
    } else {
      fetchOrders();
    }
  }

  /// Get current store ID for the logged-in owner
  Future<void> _getCurrentStoreId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('👤 Getting store for user: ${user.id}');

      final storeResponse = await _supabase
          .from('stores')
          .select('id')
          .eq('owner_id', user.id)
          .limit(1)
          .single();

      _currentStoreId = storeResponse['id'];
      print('🏪 Store ID found: $_currentStoreId');
    } catch (e) {
      print('❌ Error getting store ID: $e');
      _showErrorToast('Failed to get store information');
    }
  }

  /// Set up real-time subscription for order changes
  void _setupOrdersSubscription() {
    if (_currentStoreId == null) {
      print('❌ No store ID available for subscription');
      return;
    }

    print('🔄 Setting up real-time subscription for store: $_currentStoreId');

    _supabase
        .channel('orders_${_currentStoreId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'store_id',
            value: _currentStoreId,
          ),
          callback: (payload) {
            print('📡 Real-time order change: ${payload.eventType}');
            print('📄 Payload: ${payload.newRecord}');

            // Handle different types of changes
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                _handleNewOrderInsert(payload.newRecord);
                break;
              case PostgresChangeEvent.update:
                _handleOrderUpdate(payload.newRecord, payload.oldRecord);
                break;
              case PostgresChangeEvent.delete:
                print('🗑️ Order deleted: ${payload.oldRecord}');
                break;
            }

            // Always refresh the orders list
            fetchOrders();
          },
        )
        .subscribe((status) {
          print('📡 Subscription status: $status');
        });
  }

  /// Handle new order insertion from real-time subscription
  void _handleNewOrderInsert(Map<String, dynamic>? newRecord) {
    if (newRecord == null) return;

    final orderId = newRecord['id'] as String?;
    final status = newRecord['status'] as String?;

    print('🆕 New order inserted: $orderId with status: $status');

    // Only process if it's a pending order (truly new)
    if (status == 'pending' && orderId != null) {
      final customerName = newRecord['customer_name'] as String? ?? 'Customer';
      final orderNumber = newRecord['order_number'] as String? ?? 'N/A';
      final totalAmount =
          (newRecord['total_amount'] as num?)?.toDouble() ?? 0.0;

      _processNewOrder(orderId, customerName, orderNumber, totalAmount);
    }
  }

  /// Handle order updates from real-time subscription
  void _handleOrderUpdate(
    Map<String, dynamic>? newRecord,
    Map<String, dynamic>? oldRecord,
  ) {
    if (newRecord == null || oldRecord == null) return;

    final orderId = newRecord['id'] as String;
    final oldStatus = oldRecord['status'] as String?;
    final newStatus = newRecord['status'] as String?;

    print('🔄 Order updated: $orderId from $oldStatus to $newStatus');

    // Remove from new orders list if status changed
    if (oldStatus != newStatus && newOrderIds.contains(orderId)) {
      newOrderIds.remove(orderId);
      print('✅ Removed $orderId from new orders list');
    }

    // Show notification for status changes
    if (newStatus == 'ready') {
      final customerName = newRecord['customer_name'] as String? ?? 'Customer';
      final orderNumber = newRecord['order_number'] as String? ?? 'N/A';
      _showOrderReadyNotification(orderId, customerName, orderNumber);
    }
  }

  /// Process a truly new order
  void _processNewOrder(
    String orderId,
    String customerName,
    String orderNumber,
    double totalAmount,
  ) {
    print('🎉 Processing new order: $orderId');

    // Add to new orders list for UI highlighting
    if (!newOrderIds.contains(orderId)) {
      newOrderIds.add(orderId);

      // Remove from new orders list after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        newOrderIds.remove(orderId);
        print('⏰ Removed highlighting for order: $orderId');
      });

      // Show in-app notification (toast) if app is in foreground
      _showNewOrderToast(customerName, orderNumber, totalAmount);

      // Show local notification for all states (foreground, background, locked)
      _showNewOrderNotification(
        orderId,
        customerName,
        orderNumber,
        totalAmount,
      );
    }
  }

  /// Fetch all orders from database
  Future<void> fetchOrders() async {
    if (_currentStoreId == null) {
      print('❌ Cannot fetch orders: No store ID');
      return;
    }

    try {
      isLoading.value = true;
      print('📥 Fetching orders for store: $_currentStoreId');

      // Fetch all orders for this store
      final ordersResponse = await _supabase
          .from('orders')
          .select('*')
          .eq('store_id', _currentStoreId!)
          .order('created_at', ascending: false);

      print('📊 Fetched ${ordersResponse.length} orders');

      // Convert to OrderModel objects
      final orders = ordersResponse.map((orderData) {
        return OrderModel.fromJson(orderData);
      }).toList();

      // Check for new orders (only on subsequent loads)
      final currentOrderIds = orders.map((order) => order.id).toList();

      if (_previousOrderIds.isNotEmpty) {
        final newIds = currentOrderIds
            .where((id) => !_previousOrderIds.contains(id))
            .where(
              (id) => orders.firstWhere((o) => o.id == id).status == 'pending',
            )
            .toList();

        print('🆕 Found ${newIds.length} new orders since last check');

        for (final newId in newIds) {
          final newOrder = orders.firstWhere((order) => order.id == newId);
          _processNewOrder(
            newOrder.id,
            newOrder.customerName,
            newOrder.orderNumber,
            newOrder.totalAmount,
          );
        }
      }

      // Update previous order IDs for next comparison
      _previousOrderIds = currentOrderIds;

      // Update observable lists based on status
      allOrders.value = orders;
      preparingOrders.value = orders
          .where((o) => o.status == 'preparing')
          .toList();
      readyOrders.value = orders.where((o) => o.status == 'ready').toList();
      completedOrders.value = orders
          .where((o) => o.status == 'completed')
          .toList();
      rejectedOrders.value = orders
          .where((o) => o.status == 'rejected')
          .toList();

      print(
        '📊 Orders categorized: ${orders.length} total, ${preparingOrders.length} preparing, ${readyOrders.length} ready',
      );
    } catch (e) {
      print('❌ Error fetching orders: $e');
      _showErrorToast('Failed to fetch orders: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Accept an order and start preparation
  Future<void> acceptOrder(String orderId, int estimatedMinutes) async {
    try {
      print(
        '✅ Accepting order: $orderId with $estimatedMinutes minutes estimate',
      );

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

      // Remove from new orders list
      newOrderIds.remove(orderId);

      _showSuccessToast(
        'Order accepted! Estimated ready time: $estimatedMinutes minutes',
      );

      // Cancel the new order notification
      await _notificationsPlugin.cancel(orderId.hashCode);

      await fetchOrders();
    } catch (e) {
      print('❌ Error accepting order: $e');
      _showErrorToast('Failed to accept order: ${e.toString()}');
    }
  }

  /// Reject an order
  Future<void> rejectOrder(String orderId) async {
    try {
      print('❌ Rejecting order: $orderId');

      await _supabase
          .from('orders')
          .update({
            'status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Remove from new orders list
      newOrderIds.remove(orderId);

      _showSuccessToast('Order rejected successfully');

      // Cancel the new order notification
      await _notificationsPlugin.cancel(orderId.hashCode);

      await fetchOrders();
    } catch (e) {
      print('❌ Error rejecting order: $e');
      _showErrorToast('Failed to reject order: ${e.toString()}');
    }
  }

  /// Mark order as ready for pickup
  Future<void> markOrderAsReady(String orderId) async {
    try {
      print('🍽️ Marking order as ready: $orderId');

      await _supabase
          .from('orders')
          .update({
            'status': 'ready',
            'ready_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessToast('Order marked as ready for pickup!');

      // Find the order for notification
      final order = allOrders.firstWhereOrNull((o) => o.id == orderId);
      if (order != null) {
        _showOrderReadyNotification(
          orderId,
          order.customerName,
          order.orderNumber,
        );
      }

      await fetchOrders();
    } catch (e) {
      print('❌ Error marking order as ready: $e');
      _showErrorToast('Failed to mark order as ready: ${e.toString()}');
    }
  }

  /// Mark order as completed
  Future<void> markOrderAsCompleted(String orderId) async {
    try {
      print('✅ Marking order as completed: $orderId');

      await _supabase
          .from('orders')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _showSuccessToast('Order completed successfully!');
      await fetchOrders();
    } catch (e) {
      print('❌ Error completing order: $e');
      _showErrorToast('Failed to complete order: ${e.toString()}');
    }
  }

  /// Show toast notification for new orders (foreground only)
  void _showNewOrderToast(
    String customerName,
    String orderNumber,
    double totalAmount,
  ) {
    if (Get.context == null) return;

    print('🔔 Showing toast for new order: $orderNumber');

    ToastHelper.showToast(
      context: Get.context!,
      title: "🔔 New Order Received!",
      description:
          "Order #$orderNumber from $customerName\nTotal: Rp ${_formatPrice(totalAmount)}",
      type: ToastificationType.info,
    );
  }

  /// Show local notification for new orders (all app states)
  Future<void> _showNewOrderNotification(
    String orderId,
    String customerName,
    String orderNumber,
    double totalAmount,
  ) async {
    print('🔔 Showing local notification for order: $orderNumber');

    const AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'new_orders',
      'New Orders',
      channelDescription: 'High priority notifications for new incoming orders',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'New Order Received',
      icon: '@mipmap/ic_launcher',
      color: Colors.green,
      enableLights: true,
      ledColor: Colors.green,
      ledOnMs: 1000,
      ledOffMs: 500,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      playSound: true,
      styleInformation: BigTextStyleInformation(
        'Order #$orderNumber from $customerName\nTotal: Rp ${_formatPrice(totalAmount)}\nTap to manage this order',
        contentTitle: '🔔 New Order Received!',
        summaryText: 'Restaurant Order Management',
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view_order',
          '👁️ View Order',
          showsUserInterface: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = json.encode({
      'orderId': orderId,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'type': 'new_order',
    });

    try {
      await _notificationsPlugin.show(
        orderId.hashCode,
        '🔔 New Order Received!',
        'Order #$orderNumber from $customerName - Rp ${_formatPrice(totalAmount)}',
        platformChannelSpecifics,
        payload: payload,
      );
      print('✅ Local notification shown for order: $orderNumber');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  /// Show notification when order is ready
  Future<void> _showOrderReadyNotification(
    String orderId,
    String customerName,
    String orderNumber,
  ) async {
    print('🍽️ Showing order ready notification: $orderNumber');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'order_ready',
          'Order Ready',
          channelDescription: 'Notifications when orders are ready for pickup',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.orange,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
          playSound: true,
          styleInformation: BigTextStyleInformation(
            'Order #$orderNumber for $customerName is now ready for pickup',
            contentTitle: '🍽️ Order Ready!',
            summaryText: 'Ready for Pickup',
          ),
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = json.encode({
      'orderId': orderId,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'type': 'order_ready',
    });

    try {
      await _notificationsPlugin.show(
        orderId.hashCode + 1000, // Different ID for ready notifications
        '🍽️ Order Ready!',
        'Order #$orderNumber for $customerName is ready for pickup',
        platformChannelSpecifics,
        payload: payload,
      );
      print('✅ Order ready notification shown');
    } catch (e) {
      print('❌ Error showing ready notification: $e');
    }
  }

  /// Format price with thousand separators
  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  /// Show success toast
  void _showSuccessToast(String message) {
    if (Get.context != null) {
      ToastHelper.showToast(
        context: Get.context!,
        title: "✅ Success",
        description: message,
        type: ToastificationType.success,
      );
    }
  }

  /// Show error toast
  void _showErrorToast(String message) {
    if (Get.context != null) {
      ToastHelper.showToast(
        context: Get.context!,
        title: "❌ Error",
        description: message,
        type: ToastificationType.error,
      );
    }
  }

  @override
  void onClose() {
    print('🔄 Cleaning up dashboard controller...');

    // Clean up Supabase subscriptions
    _supabase.removeAllChannels();

    // Cancel all notifications
    _notificationsPlugin.cancelAll();

    super.onClose();
  }
}
