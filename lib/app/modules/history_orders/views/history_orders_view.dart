// app/modules/history_orders/views/history_orders_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/data/models/order_model.dart';
import '../controllers/history_orders_controller.dart';

class HistoryOrdersView extends GetView<HistoryOrdersController> {
  const HistoryOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order History'),
          backgroundColor: Colors
              .orange
              .shade700, // Changed to orange to match restaurant theme
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
              Tab(text: 'Failed'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _buildOrderList(controller.allOrders, 'No orders found'),
              _buildOrderList(_getOngoingOrders(), 'No ongoing orders'),
              _buildOrderList(_getCompletedOrders(), 'No completed orders'),
              _buildOrderList(_getFailedOrders(), 'No failed orders'),
            ],
          );
        }),
      ),
    );
  }

  List<OrderModel> _getOngoingOrders() {
    return controller.allOrders.where((order) {
      return order.paymentStatus == 'pending' ||
          (order.paymentStatus == 'paid' &&
              order.status != 'completed' &&
              order.status != 'rejected' &&
              order.status != 'failed');
    }).toList();
  }

  List<OrderModel> _getCompletedOrders() {
    return controller.allOrders.where((order) {
      return order.status == 'completed' && order.paymentStatus == 'paid';
    }).toList();
  }

  List<OrderModel> _getFailedOrders() {
    return controller.allOrders.where((order) {
      return order.status == 'rejected' ||
          order.status == 'failed' ||
          order.paymentStatus == 'expired';
    }).toList();
  }

  Widget _buildOrderList(List<OrderModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start ordering to see your history here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    // Check if payment is expired (15 minutes = 900 seconds)
    final timeSinceCreated = DateTime.now().difference(order.createdAt);
    final isExpired = timeSinceCreated.inSeconds > 900;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    // Updated status logic for pickup-only restaurant
    if (order.paymentStatus == 'pending' && !isExpired) {
      statusColor = Colors.orange;
      statusText = 'Need Payment';
      statusIcon = Icons.payment;
    } else if (order.paymentStatus == 'pending' && isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
      statusIcon = Icons.timer_off;
    } else if (order.status == 'completed') {
      statusColor = Colors.green;
      statusText = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (order.status == 'rejected' || order.status == 'failed') {
      statusColor = Colors.red;
      statusText = 'Failed';
      statusIcon = Icons.cancel;
    } else if (order.status == 'preparing') {
      statusColor = Colors.blue;
      statusText = 'Cooking';
      statusIcon = Icons.restaurant;
    } else if (order.status == 'ready') {
      statusColor = Colors.purple;
      statusText = 'Ready for Pickup';
      statusIcon = Icons.shopping_bag;
    } else {
      statusColor = Colors.amber;
      statusText = 'Processing';
      statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (order.paymentStatus == 'pending') {
            // Go to payment view (whether expired or not)
            controller.navigateToPayment(order);
          } else {
            // Completed/failed orders - show details
            controller.showOrderDetails(order);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    order.customerName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Order details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rp ${_formatPrice(order.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Estimated cooking time if available
              if (order.estimatedCookingTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Est. ready: ${_formatTime(order.estimatedCookingTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Payment timer for pending orders
              if (order.paymentStatus == 'pending' && !isExpired) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Payment expires in: ${_getPaymentTimeLeft(order.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${_formatTime(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _getPaymentTimeLeft(DateTime orderCreated) {
    final timeSinceCreated = DateTime.now().difference(orderCreated);
    final remainingSeconds =
        900 - timeSinceCreated.inSeconds; // 15 minutes = 900 seconds

    if (remainingSeconds <= 0) {
      return 'Expired';
    }

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
