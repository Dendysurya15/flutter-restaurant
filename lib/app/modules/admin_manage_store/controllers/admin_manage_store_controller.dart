import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:restaurant/app/data/models/store_model.dart';

class AdminManageStoreController extends GetxController {
  final supabase = Supabase.instance.client;

  // Reactive variables
  final stores = <StoreModel>[].obs;
  final filteredStores = <StoreModel>[].obs;
  final isLoading = false.obs;
  final searchController = TextEditingController();
  final searchText = ''.obs;

  // DataTable2 sorting (NEW)
  final sortColumnIndex = 0.obs;
  final sortAscending = true.obs;

  // Pagination (keeping your existing implementation)
  final currentPage = 1.obs;
  final itemsPerPage = 10;
  final totalItems = 0.obs;
  final totalPages = 0.obs;

  // DataTable2 pagination (NEW - for when you switch to DataTable2)
  final rowsPerPage = 10.obs;
  final availableRowsPerPage = [5, 10, 20, 50].obs;

  // Filters
  final selectedCategory = 'All'.obs;
  final selectedStatus = 'All'.obs;
  final categories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadStores();
    loadCategories();

    // Listen to search text changes
    searchController.addListener(() {
      searchText.value = searchController.text;
      filterStores();
    });

    // Listen to filter changes
    ever(selectedCategory, (_) => filterStores());
    ever(selectedStatus, (_) => filterStores());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadStores() async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('stores')
          .select('*')
          .order('created_at', ascending: false);

      stores.value = (response as List)
          .map((json) => StoreModel.fromJson(json))
          .toList();

      totalItems.value = stores.length;
      filterStores();
    } catch (e) {
      print('Error loading stores: $e');
      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Error',
          description: 'Failed to load stores: ${e.toString()}',
          type: ToastificationType.error,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCategories() async {
    try {
      final response = await supabase
          .from('stores')
          .select('category')
          .neq('category', '');

      final uniqueCategories = <String>{'All'};
      for (final item in response) {
        if (item['category'] != null &&
            item['category'].toString().isNotEmpty) {
          uniqueCategories.add(item['category'].toString());
        }
      }

      categories.value = uniqueCategories.toList()..sort();
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  void filterStores() {
    var filtered = stores.where((store) {
      final matchesSearch =
          store.name.toLowerCase().contains(searchText.value.toLowerCase()) ||
          (store.address?.toLowerCase().contains(
                searchText.value.toLowerCase(),
              ) ??
              false) ||
          (store.phone?.toLowerCase().contains(
                searchText.value.toLowerCase(),
              ) ??
              false); // Added phone search

      final matchesCategory =
          selectedCategory.value == 'All' ||
          store.category == selectedCategory.value;

      final matchesStatus =
          selectedStatus.value == 'All' ||
          (selectedStatus.value == 'Active' && store.isActive) ||
          (selectedStatus.value == 'Inactive' && !store.isActive);

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    // Apply sorting (NEW)
    _sortStores(filtered);

    filteredStores.value = filtered;
    totalItems.value = filtered.length;
    totalPages.value = (totalItems.value / itemsPerPage).ceil();

    // Reset to first page if current page is out of bounds
    if (currentPage.value > totalPages.value && totalPages.value > 0) {
      currentPage.value = 1;
    }
  }

  // NEW: Sorting functionality for DataTable2
  void _sortStores(List<StoreModel> storeList) {
    switch (sortColumnIndex.value) {
      case 0: // Store Name
        storeList.sort(
          (a, b) => sortAscending.value
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name),
        );
        break;
      case 1: // Category
        storeList.sort(
          (a, b) => sortAscending.value
              ? a.category.compareTo(b.category)
              : b.category.compareTo(a.category),
        );
        break;
      case 2: // Address
        storeList.sort(
          (a, b) => sortAscending.value
              ? (a.address ?? '').compareTo(b.address ?? '')
              : (b.address ?? '').compareTo(a.address ?? ''),
        );
        break;
      case 3: // Status
        storeList.sort(
          (a, b) => sortAscending.value
              ? a.isActive.toString().compareTo(b.isActive.toString())
              : b.isActive.toString().compareTo(a.isActive.toString()),
        );
        break;
      case 4: // Created Date
        storeList.sort(
          (a, b) => sortAscending.value
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
        break;
    }
  }

  // NEW: Sort method for DataTable2
  void sort(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
    filterStores();
  }

  // Your existing pagination methods (keep these for compatibility)
  List<StoreModel> getPaginatedStores() {
    final startIndex = (currentPage.value - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredStores.length,
    );

    if (startIndex >= filteredStores.length) return [];
    return filteredStores.sublist(startIndex, endIndex);
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
    }
  }

  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
    }
  }

  // NEW: DataTable2 rows per page handler
  void updateRowsPerPage(int? newRowsPerPage) {
    if (newRowsPerPage != null) {
      rowsPerPage.value = newRowsPerPage;
    }
  }

  Future<void> toggleStoreStatus(StoreModel store) async {
    try {
      final newStatus = !store.isActive;

      await supabase
          .from('stores')
          .update({'is_active': newStatus})
          .eq('id', store.id);

      // Update local data
      final index = stores.indexWhere((s) => s.id == store.id);
      if (index != -1) {
        final updatedStore = StoreModel(
          id: store.id,
          ownerId: store.ownerId,
          name: store.name,
          category: store.category,
          description: store.description,
          imageUrl: store.imageUrl,
          address: store.address,
          phone: store.phone,
          openingHours: store.openingHours,
          deliveryAvailable: store.deliveryAvailable,
          dineInAvailable: store.dineInAvailable,
          deliveryFee: store.deliveryFee,
          minimumOrder: store.minimumOrder,
          isActive: newStatus,
          createdAt: store.createdAt,
          updatedAt: DateTime.now(),
        );

        stores[index] = updatedStore;
        filterStores();
      }

      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Success',
          description:
              'Store ${newStatus ? 'activated' : 'deactivated'} successfully',
          type: ToastificationType.success,
        );
      }
    } catch (e) {
      print('Error toggling store status: $e');
      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Error',
          description: 'Failed to update store status: ${e.toString()}',
          type: ToastificationType.error,
        );
      }
    }
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
  }

  void resetFilters() {
    selectedCategory.value = 'All';
    selectedStatus.value = 'All';
    clearSearch();
  }

  Future<void> refreshStores() async {
    await loadStores();
  }

  // NEW: Additional utility methods for better UX

  // Get stores with specific status
  List<StoreModel> getActiveStores() {
    return stores.where((store) => store.isActive).toList();
  }

  List<StoreModel> getInactiveStores() {
    return stores.where((store) => !store.isActive).toList();
  }

  // Get stores by category
  List<StoreModel> getStoresByCategory(String category) {
    return stores.where((store) => store.category == category).toList();
  }

  // Search suggestions (for future autocomplete feature)
  List<String> getSearchSuggestions() {
    final suggestions = <String>{};
    for (final store in stores) {
      suggestions.add(store.name);
      if (store.address != null) suggestions.add(store.address!);
      suggestions.add(store.category);
    }
    return suggestions.toList()..sort();
  }

  // Quick stats for dashboard
  Map<String, int> getStoreStats() {
    return {
      'total': stores.length,
      'active': getActiveStores().length,
      'inactive': getInactiveStores().length,
      'categories': categories.length - 1, // Subtract 'All'
    };
  }
}
