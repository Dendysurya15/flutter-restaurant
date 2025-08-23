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
        backgroundColor: Colors.blue.shade600,
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshStores,
        child: Column(
          children: [
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
}
