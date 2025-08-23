import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/data/models/store_model.dart';

class SearchStoreController extends GetxController {
  final supabase = Supabase.instance.client;
  late SharedPreferences _prefs;

  // Search and filtering
  final searchController = TextEditingController();
  final searchText = ''.obs;
  final selectedCategory = ''.obs;

  // Store data
  final stores = <StoreModel>[].obs;
  final filteredStores = <StoreModel>[].obs;
  final isLoading = false.obs;

  // Search history
  final searchHistory = <String>[].obs;
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  @override
  void onInit() {
    super.onInit();
    _prefs = Get.find<SharedPreferences>();
    loadStores();
    loadSearchHistory();

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

  // Load search history from SharedPreferences
  void loadSearchHistory() {
    final history = _prefs.getStringList(_searchHistoryKey) ?? [];
    searchHistory.value = history;
  }

  // Save search history to SharedPreferences
  Future<void> saveSearchHistory() async {
    await _prefs.setStringList(_searchHistoryKey, searchHistory);
  }

  // Add search term to history
  void addToSearchHistory(String searchTerm) {
    if (searchTerm.trim().isEmpty) return;

    final trimmedTerm = searchTerm.trim();

    // Remove if already exists
    searchHistory.remove(trimmedTerm);

    // Add to beginning
    searchHistory.insert(0, trimmedTerm);

    // Keep only latest 10 items
    if (searchHistory.length > _maxHistoryItems) {
      searchHistory.removeRange(_maxHistoryItems, searchHistory.length);
    }

    // Save to storage
    saveSearchHistory();
  }

  // Clear search history
  void clearSearchHistory() {
    searchHistory.clear();
    _prefs.remove(_searchHistoryKey);
  }

  // Remove specific history item
  void removeFromHistory(String term) {
    searchHistory.remove(term);
    saveSearchHistory();
  }

  // Use history item for search
  void searchFromHistory(String term) {
    searchController.text = term;
    searchText.value = term;
    applyFilters();
  }

  void searchStores(String query) {
    searchText.value = query;

    // Add to history when user actually searches (not just types)
    if (query.trim().isNotEmpty) {
      addToSearchHistory(query);
    }
  }

  void selectCategory(String category) {
    selectedCategory.value = category;

    // If no search text, set it to the category name for better UX
    if (searchText.value.isEmpty) {
      searchController.text = category;
      searchText.value = category;
    }

    // Add category to search history
    addToSearchHistory(category);
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
