import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/services/cart_service.dart';
import 'package:restaurant/app/widgets/cart_bottom_nav.dart';
import 'package:restaurant/app/modules/dashboard_customer/widgets/store_card.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import '../controllers/dashboard_customer_controller.dart';

class DashboardCustomerView extends GetView<DashboardCustomerController> {
  const DashboardCustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Restaurants'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: Obx(() {
        // Get store name from cart items by matching with filtered stores
        String? storeName;
        final cartService = CartService();
        final cartItems = cartService.cartItems;

        if (cartItems.isNotEmpty) {
          final firstItem = cartItems.first;
          final store = controller.filteredStores.firstWhereOrNull(
            (s) => s.id == firstItem.storeId,
          );
          storeName = store?.name;
        }

        return CartBottomNavWidget(currentStoreName: storeName);
      }),
      body: Column(
        children: [
          // Search Section
          Container(
            color: Colors.blue.shade600,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // Fake Search Bar (Navigation to Search Page)
                GestureDetector(
                  onTap: () => Get.toNamed(
                    Routes.SEARCH_PAGE_CUSTOMER,
                  ), // Navigate to search page
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          'Search restaurants, food...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Quick Filters
                SizedBox(
                  height: 35,
                  child: Obx(
                    () => ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip(
                          'All',
                          controller.selectedFilter.value == 'All',
                        ),
                        _buildFilterChip(
                          'Open Now',
                          controller.selectedFilter.value == 'Open Now',
                        ),
                        _buildFilterChip(
                          'Delivery',
                          controller.selectedFilter.value == 'Delivery',
                        ),
                        _buildFilterChip(
                          'Dine In',
                          controller.selectedFilter.value == 'Dine In',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Store List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredStores.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.store_mall_directory_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No restaurants found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshStores,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.filteredStores.length,
                  itemBuilder: (context, index) {
                    final store = controller.filteredStores[index];
                    return StoreCardWidget(
                      store: store,
                      onTap: () => controller.goToStoreDetail(store),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) => controller.setFilter(label),
        backgroundColor: Colors.white,
        selectedColor: Colors.blue.shade50,
        side: BorderSide(
          color: isSelected ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
    );
  }
}
