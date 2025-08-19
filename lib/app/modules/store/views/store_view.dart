import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_controller.dart';

class StoreView extends GetView<StoreController> {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stores'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          // Add store button in app bar
          Obx(() {
            if (controller.stores.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => Get.toNamed('/store/form'),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty state - no stores
        if (controller.stores.isEmpty) {
          return _buildEmptyState();
        }

        // Show list of stores
        return _buildStoresList();
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 120, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'No Stores Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first store to start\nmanaging your business',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/store/form'),
              icon: const Icon(Icons.add_business),
              label: const Text('Add Your First Store'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.stores.length,
      itemBuilder: (context, index) {
        final store = controller.stores[index];
        return _buildStoreCard(store);
      },
    );
  }

  Widget _buildStoreCard(dynamic store) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: store.isActive ? Colors.orange : Colors.grey,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Store info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: store.isActive ? Colors.orange : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (store.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            store.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (store.address?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            store.address!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (store.phone?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            store.phone!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Service badges
                        Row(
                          children: [
                            if (store.deliveryAvailable)
                              _buildServiceBadge(
                                'Delivery',
                                Icons.delivery_dining,
                              ),
                            if (store.deliveryAvailable &&
                                store.dineInAvailable)
                              const SizedBox(width: 8),
                            if (store.dineInAvailable)
                              _buildServiceBadge('Dine-In', Icons.restaurant),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Store image or placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: store.imageUrl?.isNotEmpty == true
                        ? Image.network(
                            store.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          )
                        : _buildImagePlaceholder(),
                  ),
                ],
              ),
            ),

            // Status badge
            Positioned(
              top: 8,
              right: 50,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: store.isActive ? Colors.orange : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  store.isActive ? "Active" : "Inactive",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Three-dot menu button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showStoreMenu(store),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Icon(Icons.store, color: Colors.grey.shade400, size: 24),
    );
  }

  Widget _buildServiceBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showStoreMenu(dynamic store) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Store'),
              onTap: () {
                Get.back();
                Get.toNamed('/store/form', arguments: store);
              },
            ),
            ListTile(
              leading: Icon(
                store.isActive ? Icons.pause_circle : Icons.play_circle,
                color: store.isActive ? Colors.orange : Colors.green,
              ),
              title: Text(
                store.isActive ? 'Deactivate Store' : 'Activate Store',
              ),
              onTap: () {
                Get.back();
                controller.toggleStoreStatus(store.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.purple),
              title: const Text('View Analytics'),
              onTap: () {
                Get.back();
                Get.toNamed('/store/analytics', arguments: store.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Store'),
              onTap: () {
                Get.back();
                _confirmDeleteStore(store);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStore(dynamic store) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Store'),
        content: Text(
          'Are you sure you want to delete "${store.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteStore(store.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
