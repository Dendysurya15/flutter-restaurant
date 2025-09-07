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
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Ongoing'),
              Tab(text: 'Success'),
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
              _buildOrderList(_getSuccessOrders(), 'No completed orders'),
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
              order.status != 'cancelled' &&
              order.status != 'failed');
    }).toList();
  }

  List<OrderModel> _getSuccessOrders() {
    return controller.allOrders.where((order) {
      return order.status == 'completed' && order.paymentStatus == 'paid';
    }).toList();
  }

  List<OrderModel> _getFailedOrders() {
    return controller.allOrders.where((order) {
      return order.status == 'cancelled' ||
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
            const Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(fontSize: 18)),
            const Text('Start ordering to see your history here'),
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

    // Updated status logic with expiration check
    if (order.paymentStatus == 'pending' && !isExpired) {
      statusColor = Colors.orange;
      statusText = 'Need Payment';
    } else if (order.paymentStatus == 'pending' && isExpired) {
      statusColor = Colors.red;
      statusText = 'Expired';
    } else if (order.status == 'completed') {
      statusColor = Colors.green;
      statusText = 'Completed';
    } else if (order.status == 'cancelled' || order.status == 'failed') {
      statusColor = Colors.red;
      statusText = 'Failed';
    } else {
      statusColor = Colors.green;
      statusText =
          'Processing Food'; // Changed from 'Processing' to 'Processing Food'
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Order #${order.orderNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.customerName),
            Text('Rp.${order.totalAmount.toInt()}'),
            Text(_formatDate(order.createdAt)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            border: Border.all(color: statusColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ),
        onTap: () {
          if (order.paymentStatus == 'pending') {
            // Go to payment view (whether expired or not)
            controller.navigateToPayment(order);
          } else {
            // Completed/failed orders - show details
            controller.showOrderDetails(order);
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
