import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/modules/purchased_store_detail/widgets/item_display.dart';
import 'package:restaurant/app/modules/purchased_store_detail/controllers/purchased_store_detail_controller.dart';
import 'package:restaurant/app/widgets/cart_bottom_nav.dart';

class PurchasedStoreDetailView extends GetView<PurchasedStoreDetailController> {
  const PurchasedStoreDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.store.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final store = controller.store.value!;

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                floating: false,
                pinned: true,
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    store.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  background: _buildHeaderBackground(store),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // Handle favorite action
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      // Handle share action
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(child: _buildStoreInfoCard(store)),
              if (controller.isLoading.value)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else
                ..._buildMenuSections(),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        final store = controller.store.value;
        return CartBottomNavWidget(
          currentStoreId: store?.id,
          currentStoreName: store?.name,
        );
      }),
    );
  }

  Widget _buildHeaderBackground(store) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (store.imageUrl != null && store.imageUrl!.isNotEmpty)
            Image.network(
              store.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildImagePlaceholder(),
            )
          else
            _buildImagePlaceholder(),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(Icons.store, size: 80, color: Colors.grey.shade500),
    );
  }

  Widget _buildStoreInfoCard(store) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            store.category,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: store.isOpenNow ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      store.currentStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (store.description != null &&
                  store.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  store.description!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              // Store Details Row
              Row(
                children: [
                  if (store.address != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        store.address!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Service Options
              Row(
                children: [
                  if (store.deliveryAvailable) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delivery_dining,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Delivery',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (store.dineInAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restaurant,
                            size: 16,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dine In',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (store.getTodayHours() != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Today: ${store.getTodayHours()}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
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

  List<Widget> _buildMenuSections() {
    final groupedItems = controller.groupedMenuItems;
    final List<Widget> slivers = [];

    if (groupedItems.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No menu items available',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return slivers;
    }

    // Add sections for each category
    for (final category in controller.activeCategories) {
      final items = groupedItems[category.id] ?? [];
      if (items.isEmpty) continue;

      slivers.add(
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                child: Container(
                  height: 50,
                  color: Colors.grey.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${items.length})',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return ItemDisplayWidget(
                  item: item,
                  onTap: () => controller.onMenuItemTap(item),
                );
              }, childCount: items.length),
            ),
          ],
        ),
      );
    }

    // Add uncategorized items if any
    final uncategorizedItems = groupedItems['uncategorized'] ?? [];
    if (uncategorizedItems.isNotEmpty) {
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            child: Container(
              height: 50,
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Other Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${uncategorizedItems.length})',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = uncategorizedItems[index];
            return ItemDisplayWidget(
              item: item,
              onTap: () => controller.onMenuItemTap(item),
            );
          }, childCount: uncategorizedItems.length),
        ),
      );
    }

    // Add bottom padding
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));

    return slivers;
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 50;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
