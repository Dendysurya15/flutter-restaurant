import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/data/models/menu_category_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/services/menu_service.dart';
import '../views/category_form_view.dart';
import '../views/menu_item_form_view.dart';

class StoreDetailController extends GetxController {
  final MenuService _menuService = Get.find<MenuService>();

  // Store data - change this to use StoreModel
  final store = Rxn<dynamic>(); // Use dynamic or your StoreModel type

  // Categories and menu items
  final categories = <MenuCategoryModel>[].obs;
  final menuItems = <MenuItemModel>[].obs;
  final filteredMenuItems = <MenuItemModel>[].obs;

  // Selected filter
  final selectedCategoryId = 'all'.obs;

  // Loading states
  final isLoadingCategories = false.obs;
  final isLoadingMenuItems = false.obs;

  @override
  void onInit() {
    super.onInit();
    store.value = Get.arguments; // Get the StoreModel directly
    loadCategories();
    loadMenuItems();
  }

  Future<void> loadCategories() async {
    try {
      isLoadingCategories.value = true;
      final storeId = store.value?.id; // Access id from StoreModel
      if (storeId == null) {
        throw Exception('Store ID is required');
      }

      final result = await _menuService.getCategories(storeId);
      categories.value = result;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load categories: ${e.toString()}');
      print('Error loading categories: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> loadMenuItems() async {
    try {
      isLoadingMenuItems.value = true;
      final storeId = store.value?.id; // Access id from StoreModel
      if (storeId == null) {
        throw Exception('Store ID is required');
      }

      final result = await _menuService.getMenuItems(storeId);
      menuItems.value = result;
      applyFilter();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load menu items: ${e.toString()}');
      print('Error loading menu items: $e');
    } finally {
      isLoadingMenuItems.value = false;
    }
  }

  void applyFilter() {
    if (selectedCategoryId.value == 'all') {
      filteredMenuItems.value = menuItems;
    } else {
      filteredMenuItems.value = menuItems
          .where((item) => item.categoryId == selectedCategoryId.value)
          .toList();
    }
  }

  void onCategoryFilterChanged(String categoryId) {
    selectedCategoryId.value = categoryId;
    applyFilter();
  }

  Future<void> goToAddCategory() async {
    final result = await Get.toNamed(
      Routes.CATEGORY_FORM,
      arguments: store.value,
    );
    if (result == true) {
      await loadCategories();
    }
  }

  Future<void> goToAddMenuItem() async {
    if (categories.isEmpty) {
      Get.snackbar(
        'Cannot Add Menu Item',
        'Please add at least one category first',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final result = await Get.toNamed(
      Routes.MENU_ITEM_FORM,
      arguments: {'store': store.value, 'categories': categories},
    );

    if (result == true) {
      await loadMenuItems();
    }
  }

  Future<void> refreshData() async {
    await Future.wait([loadCategories(), loadMenuItems()]);
  }

  Future<void> toggleMenuItemAvailability(MenuItemModel item) async {
    try {
      await _menuService.toggleMenuItemAvailability(item.id, !item.isAvailable);
      await loadMenuItems();
      Get.snackbar(
        'Success',
        '${item.name} is now ${!item.isAvailable ? 'available' : 'unavailable'}',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update menu item: ${e.toString()}');
    }
  }

  Future<void> deleteMenuItem(MenuItemModel item) async {
    try {
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete Menu Item'),
          content: Text('Are you sure you want to delete "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _menuService.deleteMenuItem(item.id);
        await loadMenuItems();
        Get.snackbar('Success', '${item.name} has been deleted');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete menu item: ${e.toString()}');
    }
  }
}
