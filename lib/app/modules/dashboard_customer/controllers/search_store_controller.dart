import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/data/models/store_model.dart';

class SearchStoreController extends GetxController {
  final supabase = Supabase.instance.client;

  // Search and filtering
  final searchController = TextEditingController();
  final searchText = ''.obs;
  final selectedCategory = ''.obs;

  // Store data
  final stores = <StoreModel>[].obs;
  final filteredStores = <StoreModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStores();

    // Listen to search changes
    searchController.addListener(() {
      searchText.value = searchController.text;
    });

    // Listen to changes
    ever(searchText, (_) => applyFilters());
    ever(selectedCategory, (_) => applyFilters());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadStores() async {
    try {
      isLoading.value = true;

      // Get all active stores
      final response = await supabase
          .from('stores')
          .select('*')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      stores.value = (response as List)
          .map((json) => StoreModel.fromJson(json))
          .toList();
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
  }

  void selectCategory(String category) {
    selectedCategory.value = category;

    // If no search text, set it to the category name for better UX
    if (searchText.value.isEmpty) {
      searchController.text = category;
      searchText.value = category;
    }
  }

  void clearCategory() {
    selectedCategory.value = '';
    applyFilters();
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

      // Category filter
      final matchesCategory =
          selectedCategory.value.isEmpty ||
          store.category.toLowerCase() == selectedCategory.value.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    // Sort by status (open stores first) then by name
    filtered.sort((a, b) {
      if (a.isOpenNow && !b.isOpenNow) return -1;
      if (!a.isOpenNow && b.isOpenNow) return 1;
      return a.name.compareTo(b.name);
    });

    filteredStores.value = filtered;
  }

  // Navigate to store detail
  void goToStoreDetail(StoreModel store) {
    // TODO: Navigate to store menu/detail page
    Get.snackbar(
      'Store Selected',
      'Opening ${store.name}...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
