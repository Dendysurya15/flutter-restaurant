import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/modules/admin_manage_store/widgets/table_widget.dart';
import 'package:restaurant/app/modules/admin_manage_store/widgets/search_table_widget.dart';
import '../controllers/admin_manage_store_controller.dart';

class AdminManageStoreView extends GetView<AdminManageStoreController> {
  const AdminManageStoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Stores'),
        centerTitle: true,
        backgroundColor:
            Colors.orange.shade600, // Changed to orange for restaurant theme
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: controller.refreshStores,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: controller.resetFilters,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
          ),
          // Add stats icon to show quick overview
          IconButton(
            onPressed: _showStoreStats,
            icon: const Icon(Icons.analytics),
            tooltip: 'Store Statistics',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshStores,
        child: Column(
          children: [
            // Quick stats bar for pickup restaurants
            _buildStatsBar(),

            // Search and Filter Section
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(16.0),
              child: const SearchTableWidget(),
            ),

            // DataTable Section with built-in pagination
            const Expanded(child: TableWidget()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Obx(() {
      final stats = controller.getStoreStats();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border(bottom: BorderSide(color: Colors.orange.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total Stores',
              stats['total'].toString(),
              Icons.store,
              Colors.blue,
            ),
            _buildStatItem(
              'Active',
              stats['active'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatItem(
              'Inactive',
              stats['inactive'].toString(),
              Icons.pause_circle,
              Colors.orange,
            ),
            _buildStatItem(
              'Categories',
              stats['categories'].toString(),
              Icons.category,
              Colors.purple,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _showStoreStats() {
    final stats = controller.getStoreStats();
    final averageMinOrder = controller.getAverageMinimumOrder();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Store Statistics'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow('Total Stores', stats['total'].toString()),
            _buildStatsRow('Active Stores', stats['active'].toString()),
            _buildStatsRow('Inactive Stores', stats['inactive'].toString()),
            _buildStatsRow('Categories', stats['categories'].toString()),
            const Divider(),
            _buildStatsRow(
              'Average Min. Order',
              'Rp ${_formatPrice(averageMinOrder)}',
            ),
            _buildStatsRow(
              'Stores with Min. Order',
              controller.getStoresWithMinimumOrder().length.toString(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
