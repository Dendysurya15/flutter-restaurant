import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/modules/admin_manage_store/controllers/admin_manage_store_controller.dart';

class SearchTableWidget extends GetView<AdminManageStoreController> {
  const SearchTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar (Full Width)
        TextField(
          controller: controller.searchController,
          decoration: InputDecoration(
            hintText: 'Search stores by name, address, or phone...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: Obx(
              () => controller.searchText.value.isNotEmpty
                  ? IconButton(
                      onPressed: controller.clearSearch,
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      tooltip: 'Clear search',
                    )
                  : const SizedBox.shrink(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onSubmitted: (value) {
            controller.filterStores();
          },
        ),

        const SizedBox(height: 12),

        // Filters and Actions Row
        Row(
          children: [
            // Category Filter
            Expanded(
              child: Obx(
                () => Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedCategory.value,
                      hint: const Text('Category'),
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                      items: controller.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            style: TextStyle(
                              fontWeight: category == 'All'
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedCategory.value = value;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Status Filter
            Expanded(
              child: Obx(
                () => Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedStatus.value,
                      hint: const Text('Status'),
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                      items: ['All', 'Active', 'Inactive'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (status != 'All') ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: status == 'Active'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontWeight: status == 'All'
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedStatus.value = value;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Reset Button
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: IconButton(
                onPressed: controller.resetFilters,
                icon: Icon(
                  Icons.refresh,
                  color: Colors.grey.shade600,
                  size: 18,
                ),
                tooltip: 'Reset filters',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Results Summary and Active Filters
        Row(
          children: [
            // Results Summary
            Expanded(
              child: Obx(() {
                final totalStores = controller.stores.length;
                final filteredCount = controller.filteredStores.length;
                final hasFilters =
                    controller.selectedCategory.value != 'All' ||
                    controller.selectedStatus.value != 'All' ||
                    controller.searchText.value.isNotEmpty;

                return Text(
                  hasFilters
                      ? 'Showing $filteredCount of $totalStores stores'
                      : 'Total $totalStores stores',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }),
            ),
          ],
        ),

        // Active Filters (if any)
        const SizedBox(height: 8),
        Obx(() {
          final activeFilters = <Widget>[];

          if (controller.searchText.value.isNotEmpty) {
            activeFilters.add(
              _FilterChip(
                label: 'Search: "${controller.searchText.value}"',
                onDeleted: controller.clearSearch,
              ),
            );
          }

          if (controller.selectedCategory.value != 'All') {
            activeFilters.add(
              _FilterChip(
                label: controller.selectedCategory.value,
                onDeleted: () => controller.selectedCategory.value = 'All',
              ),
            );
          }

          if (controller.selectedStatus.value != 'All') {
            activeFilters.add(
              _FilterChip(
                label: controller.selectedStatus.value,
                onDeleted: () => controller.selectedStatus.value = 'All',
              ),
            );
          }

          if (activeFilters.isEmpty) return const SizedBox.shrink();

          return Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...activeFilters,
                if (activeFilters.length > 1)
                  TextButton(
                    onPressed: controller.resetFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                      foregroundColor: Colors.red.shade600,
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _FilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      deleteIcon: const Icon(Icons.close, size: 12),
      onDeleted: onDeleted,
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
