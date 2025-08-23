import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/data/models/menu_category_model.dart';
import 'package:restaurant/app/services/menu_service.dart';

class MenuItemFormController extends GetxController {
  final MenuService _menuService = Get.find<MenuService>();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final preparationTimeController = TextEditingController();
  final sortOrderController = TextEditingController();

  final store = Rxn<dynamic>(); // Change to handle StoreModel
  final categories = <MenuCategoryModel>[].obs;
  final selectedCategoryId = ''.obs;
  final isAvailable = true.obs;
  final isVegetarian = false.obs;
  final isSpicy = false.obs;
  final isLoading = false.obs;
  // Add this property at the top of your controller
  final isEditing = false.obs;

  @override
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments ?? {};

    // Handle the arguments properly
    if (args is Map) {
      // If arguments is a Map with 'store' and 'categories' keys
      store.value = args['store'];
      categories.value = List<MenuCategoryModel>.from(args['categories'] ?? []);

      // Check if we're editing an existing item
      final editingItem = args['editingItem'];
      if (editingItem != null) {
        _populateFormForEditing(editingItem);
      }
    } else {
      // If arguments is just the StoreModel directly
      store.value = args;
      categories.value = [];
    }

    if (categories.isNotEmpty && selectedCategoryId.value.isEmpty) {
      selectedCategoryId.value = categories.first.id;
    }

    if (sortOrderController.text.isEmpty) {
      sortOrderController.text = '0';
    }
  }

  // Add this new method
  void _populateFormForEditing(dynamic item) {
    isEditing.value = true; // Add this line
    nameController.text = item.name ?? '';
    descriptionController.text = item.description ?? '';
    priceController.text = item.price?.toInt().toString() ?? '';
    preparationTimeController.text = item.preparationTime?.toString() ?? '';
    selectedCategoryId.value = item.categoryId ?? '';
    sortOrderController.text = item.sortOrder?.toString() ?? '0';
    isAvailable.value = item.isAvailable ?? true;
    isVegetarian.value = item.isVegetarian ?? false;
    isSpicy.value = item.isSpicy ?? false;
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    preparationTimeController.dispose();
    sortOrderController.dispose();
    super.onClose();
  }

  Future<void> saveMenuItem() async {
    if (!formKey.currentState!.validate()) return;

    if (selectedCategoryId.value.isEmpty) {
      Get.snackbar('Error', 'Please select a category');
      return;
    }

    try {
      isLoading.value = true;

      final menuItemData = {
        'store_id': store.value?.id,
        'category_id': selectedCategoryId.value,
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'preparation_time': preparationTimeController.text.isEmpty
            ? null
            : int.tryParse(preparationTimeController.text),
        'is_vegetarian': isVegetarian.value,
        'is_spicy': isSpicy.value,
        'is_available': isAvailable.value,
        'sort_order': int.tryParse(sortOrderController.text) ?? 0,
      };

      if (isEditing.value) {
        // Update existing item
        final editingItem = (Get.arguments as Map)['editingItem'];
        await _menuService.updateMenuItem(editingItem.id, menuItemData);
        Get.back(result: true);
        Get.snackbar('Success', 'Menu item updated successfully');
      } else {
        // Create new item
        await _menuService.createMenuItem(menuItemData);
        Get.back(result: true);
        Get.snackbar('Success', 'Menu item added successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save menu item: ${e.toString()}');
      print('Error saving menu item: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Item name is required';
    }
    if (value.trim().length < 2) {
      return 'Item name must be at least 2 characters';
    }
    return null;
  }

  String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Enter a valid price';
    }
    if (price <= 0) {
      return 'Price must be greater than 0';
    }
    return null;
  }

  String? validatePreparationTime(String? value) {
    if (value != null && value.isNotEmpty) {
      final time = int.tryParse(value);
      if (time == null) {
        return 'Enter a valid number';
      }
      if (time <= 0) {
        return 'Preparation time must be greater than 0';
      }
    }
    return null;
  }

  String? validateSortOrder(String? value) {
    if (value != null && value.isNotEmpty) {
      final sortOrder = int.tryParse(value);
      if (sortOrder == null) {
        return 'Enter a valid number';
      }
      if (sortOrder < 0) {
        return 'Sort order cannot be negative';
      }
    }
    return null;
  }

  void onCategoryChanged(String? categoryId) {
    if (categoryId != null) {
      selectedCategoryId.value = categoryId;
    }
  }
}
