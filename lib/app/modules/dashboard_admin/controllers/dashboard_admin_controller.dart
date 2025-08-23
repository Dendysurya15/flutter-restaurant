import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardAdminController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Dashboard stats
  final totalStores = 0.obs;
  final activeStores = 0.obs;
  final inactiveStores = 0.obs;
  final totalOwners = 0.obs;
  final recentActivities = <Map<String, dynamic>>[].obs;

  // Loading states
  final isLoadingStats = false.obs;
  final isLoadingActivities = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    await Future.wait([loadStats(), loadRecentActivities()]);
  }

  Future<void> loadStats() async {
    try {
      isLoadingStats.value = true;

      // Get total stores
      final storesResponse = await _supabase
          .from('stores')
          .select('id, is_active');

      totalStores.value = storesResponse.length;
      activeStores.value = storesResponse
          .where((store) => store['is_active'] == true)
          .length;
      inactiveStores.value = totalStores.value - activeStores.value;

      // Get total owners
      final usersResponse = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'owner');

      totalOwners.value = usersResponse.length;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load dashboard stats: ${e.toString()}');
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> loadRecentActivities() async {
    try {
      isLoadingActivities.value = true;

      // Get recent store activities (created, updated, status changes)
      final response = await _supabase
          .from('stores')
          .select('id, name, is_active, created_at, updated_at')
          .order('updated_at', ascending: false)
          .limit(10);

      recentActivities.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load recent activities: ${e.toString()}',
      );
    } finally {
      isLoadingActivities.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
    Get.snackbar('Success', 'Dashboard data refreshed');
  }
}
