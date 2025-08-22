import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/services/menu_service.dart';

class CategoryFormController extends GetxController {
  final MenuService _menuService = Get.find<MenuService>();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final sortOrderController = TextEditingController();

  final store = Rxn<dynamic>(); // Change to handle StoreModel
  final isActive = true.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    store.value = Get.arguments; // Get the StoreModel directly
    sortOrderController.text = '0';
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    sortOrderController.dispose();
    super.onClose();
  }

  Future<void> saveCategory() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final categoryData = {
        'store_id': store.value?.id, // Access id from StoreModel
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        'sort_order': int.tryParse(sortOrderController.text) ?? 0,
        'is_active': isActive.value,
      };

      await _menuService.createCategory(categoryData);

      Get.back(result: true);
      Get.snackbar('Success', 'Category added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save category: ${e.toString()}');
      print('Error saving category: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }
    if (value.trim().length < 2) {
      return 'Category name must be at least 2 characters';
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
}
