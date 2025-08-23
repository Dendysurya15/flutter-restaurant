import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/modules/dashboard_customer/controllers/search_store_controller.dart';
import 'package:restaurant/app/modules/dashboard_customer/widgets/store_card.dart';

class SearchCustomerView extends GetView<SearchStoreController> {
  const SearchCustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          controller: controller.searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search restaurants, food...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: Colors.white70),
          ),
          onChanged: controller.searchStores,
          onSubmitted: controller.searchStores,
        ),
      ),
      body: Obx(() {
        // Show search results if user has searched
        if (controller.searchText.value.isNotEmpty) {
          return _buildSearchResults();
        }

        // Show search history and categories by default
        return _buildDefaultView();
      }),
    );
  }

  Widget _buildDefaultView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Search History
          Obx(() {
            if (controller.searchHistory.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Recent Searches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: controller.clearSearchHistory,
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 45,
                  padding: const EdgeInsets.only(left: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.searchHistory.length,
                    itemBuilder: (context, index) {
                      final searchTerm = controller.searchHistory[index];
                      return _buildHistoryChip(searchTerm);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),

          // Categories Grid
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Browse Categories',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: RestaurantCategories.categories.length,
            itemBuilder: (context, index) {
              final category = RestaurantCategories.categories[index];
              return _buildCategoryCard(category);
            },
          ),
          const SizedBox(height: 32), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildHistoryChip(String searchTerm) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.searchFromHistory(searchTerm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                searchTerm,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => controller.removeFromHistory(searchTerm),
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String category) {
    return GestureDetector(
      onTap: () => controller.selectCategory(category),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            // Category Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: _getCategoryColor(category).withOpacity(0.1),
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  size: 40,
                  color: _getCategoryColor(category),
                ),
              ),
            ),

            // Category Name
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Search Info
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Obx(
                () => Text(
                  'Found ${controller.filteredStores.length} restaurants',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (controller.selectedCategory.isNotEmpty)
                Chip(
                  label: Text(
                    controller.selectedCategory.value,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onDeleted: controller.clearCategory,
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade200),
                ),
            ],
          ),
        ),

        // Results List
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
                      Icons.search_off,
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
                      'Try a different search term',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.filteredStores.length,
              itemBuilder: (context, index) {
                final store = controller.filteredStores[index];
                return StoreCardWidget(
                  store: store,
                  onTap: () => controller.goToStoreDetail(store),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fast food':
        return Colors.red;
      case 'fine dining':
        return Colors.purple;
      case 'casual dining':
        return Colors.orange;
      case 'cafe':
        return Colors.brown;
      case 'bakery':
        return Colors.amber;
      case 'pizza':
        return Colors.deepOrange;
      case 'asian cuisine':
        return Colors.green;
      case 'italian':
        return Colors.green.shade700;
      case 'mexican':
        return Colors.lime;
      case 'indian':
        return Colors.deepOrange.shade700;
      case 'chinese':
        return Colors.red.shade700;
      case 'japanese':
        return Colors.pink;
      case 'thai':
        return Colors.teal;
      case 'mediterranean':
        return Colors.blue;
      case 'american':
        return Colors.indigo;
      case 'seafood':
        return Colors.cyan;
      case 'steakhouse':
        return Colors.brown.shade700;
      case 'vegetarian/vegan':
        return Colors.lightGreen;
      case 'breakfast & brunch':
        return Colors.yellow.shade700;
      case 'desserts':
        return Colors.pink.shade300;
      case 'ice cream':
        return Colors.blue.shade300;
      case 'juice bar':
        return Colors.green.shade400;
      case 'food truck':
        return Colors.grey.shade600;
      case 'catering':
        return Colors.blueGrey;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fast food':
        return Icons.fastfood;
      case 'fine dining':
        return Icons.restaurant_menu;
      case 'casual dining':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'bakery':
        return Icons.cake;
      case 'pizza':
        return Icons.local_pizza;
      case 'asian cuisine':
        return Icons.ramen_dining;
      case 'italian':
        return Icons.local_dining;
      case 'mexican':
        return Icons.food_bank;
      case 'chinese':
        return Icons.ramen_dining;
      case 'japanese':
        return Icons.set_meal;
      case 'thai':
        return Icons.rice_bowl;
      case 'mediterranean':
        return Icons.kebab_dining;
      case 'american':
        return Icons.lunch_dining;
      case 'seafood':
        return Icons.set_meal;
      case 'steakhouse':
        return Icons.outdoor_grill;
      case 'vegetarian/vegan':
        return Icons.eco;
      case 'breakfast & brunch':
        return Icons.free_breakfast;
      case 'desserts':
        return Icons.cake;
      case 'ice cream':
        return Icons.icecream;
      case 'juice bar':
        return Icons.local_drink;
      case 'food truck':
        return Icons.local_shipping;
      case 'catering':
        return Icons.event_seat;
      default:
        return Icons.restaurant;
    }
  }
}

class RestaurantCategories {
  static const List<String> categories = [
    'Fast Food',
    'Fine Dining',
    'Casual Dining',
    'Cafe',
    'Bakery',
    'Pizza',
    'Asian Cuisine',
    'Italian',
    'Mexican',
    'Indian',
    'Chinese',
    'Japanese',
    'Thai',
    'Mediterranean',
    'American',
    'Seafood',
    'Steakhouse',
    'Vegetarian/Vegan',
    'Breakfast & Brunch',
    'Desserts',
    'Ice Cream',
    'Juice Bar',
    'Food Truck',
    'Catering',
    'Other',
  ];
}
