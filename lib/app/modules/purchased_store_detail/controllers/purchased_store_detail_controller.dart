import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/data/models/store_model.dart';
import 'package:restaurant/app/data/models/menu_item_model.dart';
import 'package:restaurant/app/data/models/menu_category_model.dart';

class PurchasedStoreDetailController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMenu = false.obs;
  final Rx<StoreModel?> store = Rx<StoreModel?>(null);
  final RxList<MenuCategoryModel> categories = <MenuCategoryModel>[].obs;
  final RxList<MenuItemModel> menuItems = <MenuItemModel>[].obs;
  final RxString selectedCategoryId = ''.obs;

  // Computed properties
  List<MenuCategoryModel> get activeCategories =>
      categories.where((c) => c.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<MenuItemModel> get availableMenuItems =>
      menuItems.where((item) => item.isAvailable).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Map<String, List<MenuItemModel>> get groupedMenuItems {
    final Map<String, List<MenuItemModel>> grouped = {};

    for (final category in activeCategories) {
      grouped[category.id] = availableMenuItems
          .where((item) => item.categoryId == category.id)
          .toList();
    }

    // Add items without category
    final uncategorizedItems = availableMenuItems
        .where((item) => item.categoryId == null || item.categoryId!.isEmpty)
        .toList();

    if (uncategorizedItems.isNotEmpty) {
      grouped['uncategorized'] = uncategorizedItems;
    }

    return grouped;
  }

  @override
  void onInit() {
    super.onInit();
    // Get store from arguments
    final arguments = Get.arguments;
    if (arguments != null && arguments is StoreModel) {
      store.value = arguments;
      loadStoreData();
    }
  }

  Future<void> loadStoreData() async {
    if (store.value == null) return;

    try {
      isLoading.value = true;
      await Future.wait([loadMenuCategories(), loadMenuItems()]);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load store data: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMenuCategories() async {
    try {
      final response = await _supabase
          .from('menu_categories')
          .select()
          .eq('store_id', store.value!.id)
          .eq('is_active', true)
          .order('sort_order');

      categories.value = (response as List)
          .map((json) => MenuCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading categories: $e');
      rethrow;
    }
  }

  Future<void> loadMenuItems() async {
    try {
      isLoadingMenu.value = true;
      final response = await _supabase
          .from('menu_items')
          .select()
          .eq('store_id', store.value!.id)
          .eq('is_available', true)
          .order('sort_order');

      menuItems.value = (response as List)
          .map((json) => MenuItemModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading menu items: $e');
      rethrow;
    } finally {
      isLoadingMenu.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadStoreData();
  }

  void selectCategory(String categoryId) {
    selectedCategoryId.value = categoryId;
  }

  void onMenuItemTap(MenuItemModel item) {
    // Handle menu item tap - navigate to item detail or add to cart
    Get.snackbar(
      'Item Selected',
      '${item.name} - \$${item.price.toStringAsFixed(2)}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
