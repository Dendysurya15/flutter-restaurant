import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/data/models/store_model.dart';
import 'dart:async';

class DashboardCustomerController extends GetxController {
  final supabase = Supabase.instance.client;

  // Search and filtering
  final searchController = TextEditingController();
  final searchText = ''.obs;
  final selectedFilter = 'All'.obs;

  // Store data
  final stores = <StoreModel>[].obs;
  final filteredStores = <StoreModel>[].obs;
  final isLoading = false.obs;

  // Remove the old getter and replace with this:
  int get pendingOrdersCount => PaymentTimerService.to.totalPendingPayments;
  Timer? _pendingOrdersTimer;

  @override
  void onInit() {
    super.onInit();
    loadStores();

    // Listen to search changes
    searchController.addListener(() {
      searchText.value = searchController.text;
      applyFilters();
    });

    // Listen to filter changes
    ever(selectedFilter, (_) => applyFilters());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Navigate to orders history
  void goToOrdersHistory() {
    Get.toNamed(Routes.HISTORY_ORDERS);
  }

  // Your existing methods remain the same...
  Future<void> loadStores() async {
    try {
      isLoading.value = true;

      final response = await supabase
          .from('stores')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      stores.value = (response as List)
          .map((json) => StoreModel.fromJson(json))
          .toList();

      applyFilters();
    } catch (e) {
      print('Error loading stores: $e');
      Get.snackbar(
        'Error',
        'Failed to load restaurants: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void searchStores(String query) {
    searchText.value = query;
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void applyFilters() {
    var filtered = stores.where((store) {
      // Search filter
      final matchesSearch =
          searchText.value.isEmpty ||
          store.name.toLowerCase().contains(searchText.value.toLowerCase()) ||
          store.category.toLowerCase().contains(
            searchText.value.toLowerCase(),
          ) ||
          (store.description?.toLowerCase().contains(
                searchText.value.toLowerCase(),
              ) ??
              false);

      if (!matchesSearch) return false;

      // Category/type filters
      switch (selectedFilter.value) {
        case 'Open Now':
          return store.isOpenNow;
        case 'Delivery':
          return store.deliveryAvailable;
        case 'Dine In':
          return store.dineInAvailable;
        case 'All':
        default:
          return true;
      }
    }).toList();

    // Sort by status (open stores first) then by name
    filtered.sort((a, b) {
      if (a.isOpenNow && !b.isOpenNow) return -1;
      if (!a.isOpenNow && b.isOpenNow) return 1;
      return a.name.compareTo(b.name);
    });

    filteredStores.value = filtered;
  }

  Future<void> refreshStores() async {
    await loadStores();
  }

  // Navigate to store detail (you can implement this later)
  void goToStoreDetail(StoreModel store) {
    Get.toNamed(Routes.PURCHASED_STORE_DETAIL, arguments: store);
  }

  // Get stores by category (for future category filtering)
  List<String> get availableCategories {
    return stores.map((store) => store.category).toSet().toList()..sort();
  }

  // Get quick stats
  Map<String, int> get storeStats {
    return {
      'total': stores.length,
      'open': stores.where((s) => s.isOpenNow).length,
      'delivery': stores.where((s) => s.deliveryAvailable).length,
      'dineIn': stores.where((s) => s.dineInAvailable).length,
    };
  }
}
