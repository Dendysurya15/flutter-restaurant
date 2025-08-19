import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/controllers/auth_controller.dart';
import 'package:restaurant/app/data/models/store_model.dart';

// Add these properties and methods to your existing StoreController

class StoreController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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

  // ADD THESE NEW METHODS:

  // Fetch all stores for the current user
  Future<void> fetchStores() async {
    try {
      isLoading.value = true;

      // Replace with your actual API call
      final response = await StoreService.getUserStores();
      stores.value = response;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch stores: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
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
    deliveryFeeController.text = store.deliveryFee.toString();
    minimumOrderController.text = store.minimumOrder.toString();

    deliveryAvailable.value = store.deliveryAvailable;
    dineInAvailable.value = store.dineInAvailable;
    isStoreActive.value = store.isActive;
  }

  // UPDATE YOUR EXISTING createStore method:
  Future<void> createStore() async {
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
        'delivery_fee': double.tryParse(deliveryFeeController.text) ?? 0.0,
        'minimum_order': double.tryParse(minimumOrderController.text) ?? 0.0,
        'is_active': isStoreActive.value,
      };

      // Replace with your actual API call
      final newStore = await StoreService.createStore(storeData);
      stores.add(newStore);

      Get.back(); // Go back to store list
      Get.snackbar(
        'Success',
        'Store created successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create store: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // UPDATE YOUR EXISTING updateStore method:
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
        'delivery_fee': double.tryParse(deliveryFeeController.text) ?? 0.0,
        'minimum_order': double.tryParse(minimumOrderController.text) ?? 0.0,
        'is_active': isStoreActive.value,
      };

      // Replace with your actual API call
      final updatedStore = await StoreService.updateStore(storeId, storeData);

      // Update local list
      final index = stores.indexWhere((store) => store.id == storeId);
      if (index != -1) {
        stores[index] = updatedStore;
      }

      Get.back(); // Go back to store list
      Get.snackbar(
        'Success',
        'Store updated successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update store: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ADD THESE NEW METHODS:

  // Toggle store active status
  Future<void> toggleStoreStatus(String storeId) async {
    try {
      final store = stores.firstWhere((s) => s.id == storeId);
      final newStatus = !store.isActive;

      // Replace with your actual API call
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

      Get.snackbar(
        'Success',
        'Store ${newStatus ? 'activated' : 'deactivated'} successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update store status: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  // Delete store
  Future<void> deleteStore(String storeId) async {
    try {
      // Replace with your actual API call
      await StoreService.deleteStore(storeId);

      // Remove from local list
      stores.removeWhere((store) => store.id == storeId);

      Get.snackbar(
        'Success',
        'Store deleted successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete store: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}

// ADD THESE SERVICE METHODS (replace with your actual API calls):
class StoreService {
  static Future<List<StoreModel>> getUserStores() async {
    // Replace with actual API call
    // Example: return await ApiService.get('/stores');
    throw UnimplementedError('Replace with your API call');
  }

  static Future<StoreModel> createStore(Map<String, dynamic> storeData) async {
    // Replace with actual API call
    // Example: return await ApiService.post('/stores', storeData);
    throw UnimplementedError('Replace with your API call');
  }

  static Future<StoreModel> updateStore(
    String storeId,
    Map<String, dynamic> storeData,
  ) async {
    // Replace with actual API call
    // Example: return await ApiService.put('/stores/$storeId', storeData);
    throw UnimplementedError('Replace with your API call');
  }

  static Future<void> updateStoreStatus(String storeId, bool isActive) async {
    // Replace with actual API call
    // Example: await ApiService.patch('/stores/$storeId/status', {'is_active': isActive});
    throw UnimplementedError('Replace with your API call');
  }

  static Future<void> deleteStore(String storeId) async {
    // Replace with actual API call
    // Example: await ApiService.delete('/stores/$storeId');
    throw UnimplementedError('Replace with your API call');
  }
}
