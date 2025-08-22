import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_detail_controller.dart';

class StoreDetailView extends GetView<StoreDetailController> {
  const StoreDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.store.value?.name ?? 'Store Detail')),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: controller.refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Action buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.goToAddCategory,
                    icon: Icon(Icons.add),
                    label: Text('Add Category'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.goToAddMenuItem,
                    icon: Icon(Icons.add),
                    label: Text('Add Menu Item'),
                  ),
                ),
              ],
            ),
          ),

          // Category filter
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
              () => ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', 'All Items'),
                  ...controller.categories
                      .where((category) => category.isActive)
                      .map(
                        (category) =>
                            _buildFilterChip(category.id, category.name),
                      ),
                ],
              ),
            ),
          ),

          // Menu items list
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMenuItems.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.filteredMenuItems.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No menu items found'),
                      if (controller.categories.isEmpty) ...[
                        SizedBox(height: 8),
                        Text('Add categories first, then add menu items'),
                      ],
                    ],
                  ),
                );
              }

              return _buildMenuItemsList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    return Obx(
      () => Padding(
        padding: EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: controller.selectedCategoryId.value == id,
          onSelected: (_) => controller.onCategoryFilterChanged(id),
        ),
      ),
    );
  }

  Widget _buildMenuItemsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: controller.filteredMenuItems.length,
      itemBuilder: (context, index) {
        final item = controller.filteredMenuItems[index];
        final category = controller.categories.firstWhereOrNull(
          (cat) => cat.id == item.categoryId,
        );

        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              ListTile(
                contentPadding: EdgeInsets.all(16),

                // Avatar with image
                leading: _buildMenuItemAvatar(item),

                // Title and subtitle
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Vegetarian and spicy icons
                    if (item.isVegetarian) ...[
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.eco,
                          size: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(width: 4),
                    ],
                    if (item.isSpicy) ...[
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ],
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                    ],

                    // Price and category row
                    Row(
                      children: [
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Text(
                            category?.name ?? 'No Category',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.preparationTime != null) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${item.preparationTime} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Trailing actions
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit button
                    Container(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        onPressed: () {
                          _showMenuActions(item);
                        },
                        icon: Icon(Icons.more_vert, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status badge (positioned absolutely)
              Positioned(
                top: 12,
                right: 60,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItemAvatar(item) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? Image.network(
                item.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              )
            : _buildPlaceholderAvatar(),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[300]!, Colors.orange[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.restaurant, color: Colors.white, size: 24),
    );
  }

  void _showMenuActions(item) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Menu item header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildMenuItemAvatar(item),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(),

            // Action buttons
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Edit Menu Item'),
              onTap: () {
                Get.back();
                Get.snackbar('Info', 'Edit functionality coming soon');
              },
            ),

            ListTile(
              leading: Icon(
                item.isAvailable ? Icons.visibility_off : Icons.visibility,
                color: item.isAvailable ? Colors.orange : Colors.green,
              ),
              title: Text(
                item.isAvailable ? 'Mark as Unavailable' : 'Mark as Available',
              ),
              onTap: () {
                Get.back();
                controller.toggleMenuItemAvailability(item);
              },
            ),

            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete Menu Item'),
              onTap: () {
                Get.back();
                controller.deleteMenuItem(item);
              },
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
