import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:restaurant/app/data/models/store_model.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:restaurant/app/services/store_service.dart';
import 'package:toastification/toastification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/services/auth_service.dart';

class StoreController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  // Text controllers
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final deliveryFeeController = TextEditingController();
  final minimumOrderController = TextEditingController();

  // Observable properties
  var isLoading = false.obs;
  var stores = <StoreModel>[].obs; // List of stores
  var deliveryAvailable = true.obs;
  var dineInAvailable = true.obs;
  var isStoreActive = true.obs;

  // Computed properties
  bool get hasStore => stores.isNotEmpty;
  StoreModel? get currentStore => stores.isNotEmpty ? stores.first : null;

  @override
  void onInit() {
    super.onInit();
    fetchStores(); // Load stores when controller initializes
  }

  // Fetch all stores for the current user
  Future<void> fetchStores() async {
    try {
      isLoading.value = true;
      final response = await StoreService.getUserStores();
      stores.value = response;
    } catch (e) {
      print("e ${e}");
      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Error',
          description: 'Failed to fetch stores: ${e.toString()}',
          type: ToastificationType.error,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Reset form for creating new store
  void resetForm() {
    nameController.clear();
    categoryController.clear();
    descriptionController.clear();
    addressController.clear();
    phoneController.clear();
    deliveryFeeController.clear();
    minimumOrderController.clear();

    deliveryAvailable.value = true;
    dineInAvailable.value = true;
    isStoreActive.value = true;
  }

  // Initialize form for editing existing store
  void initializeFormForEditing(StoreModel store) {
    nameController.text = store.name;
    categoryController.text = store.category;
    descriptionController.text = store.description ?? '';
    addressController.text = store.address ?? '';
    phoneController.text = store.phone ?? '';
    deliveryFeeController.text = store.deliveryFee?.toString() ?? '';
    minimumOrderController.text = store.minimumOrder?.toString() ?? '';

    deliveryAvailable.value = store.deliveryAvailable;
    dineInAvailable.value = store.dineInAvailable;
    isStoreActive.value = store.isActive;
  }

  // Create new store
  Future<void> createStore() async {
    print("masuk ");
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Create store data
      final storeData = {
        'name': nameController.text.trim(),
        'category': categoryController.text,
        'description': descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        'address': addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'delivery_available': deliveryAvailable.value,
        'dine_in_available': dineInAvailable.value,
        'delivery_fee': deliveryFeeController.text.trim().isEmpty
            ? null
            : double.tryParse(deliveryFeeController.text),
        'minimum_order': minimumOrderController.text.trim().isEmpty
            ? null
            : double.tryParse(minimumOrderController.text),
        'is_active': isStoreActive.value,
      };

      final newStore = await StoreService.createStore(storeData);
      stores.add(newStore);

      Get.back(); // Go back to store list

      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Success',
          description: 'Store created successfully!',
          type: ToastificationType.success,
        );
      }
    } catch (e) {
      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Error',
          description: 'Failed to create store: ${e.toString()}',
          type: ToastificationType.error,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Update existing store
  Future<void> updateStore(String storeId) async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Update store data
      final storeData = {
        'name': nameController.text.trim(),
        'category': categoryController.text,
        'description': descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        'address': addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'delivery_available': deliveryAvailable.value,
        'dine_in_available': dineInAvailable.value,
        'delivery_fee': deliveryFeeController.text.trim().isEmpty
            ? null
            : double.tryParse(deliveryFeeController.text),
        'minimum_order': minimumOrderController.text.trim().isEmpty
            ? null
            : double.tryParse(minimumOrderController.text),
        'is_active': isStoreActive.value,
      };

      final updatedStore = await StoreService.updateStore(storeId, storeData);

      // Update local list
      final index = stores.indexWhere((store) => store.id == storeId);
      if (index != -1) {
        stores[index] = updatedStore;
      }

      Get.back(); // Go back to store list

      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Success',
          description: 'Store updated successfully!',
          type: ToastificationType.success,
        );
      }
    } catch (e) {
      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Error',
          description: 'Failed to update store: ${e.toString()}',
          type: ToastificationType.error,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle store active status
  Future<void> toggleStoreStatus(String storeId) async {
    try {
      final store = stores.firstWhere((s) => s.id == storeId);
      final newStatus = !store.isActive;

      await StoreService.updateStoreStatus(storeId, newStatus);

      // Update local list
      final index = stores.indexWhere((s) => s.id == storeId);
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
      }

      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Success',
          description:
              'Store ${newStatus ? 'activated' : 'deactivated'} successfully!',
          type: ToastificationType.success,
        );
      }
    } catch (e) {
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

  // Delete store
  Future<void> deleteStore(String storeId) async {
    try {
      await StoreService.deleteStore(storeId);

      // Remove from local list
      stores.removeWhere((store) => store.id == storeId);

      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Success',
          description: 'Store deleted successfully!',
          type: ToastificationType.success,
        );
      }
    } catch (e) {
      if (Get.context != null) {
        ToastHelper.showToast(
          context: Get.context!,
          title: 'Error',
          description: 'Failed to delete store: ${e.toString()}',
          type: ToastificationType.error,
        );
      }
    }
  }
}
