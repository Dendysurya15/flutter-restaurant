import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/modules/dashboard_admin/controllers/dashboard_admin_controller.dart';

class DashboardAdminView extends GetView<DashboardAdminController> {
  @override
  Widget build(BuildContext context) {
    Get.put(DashboardAdminController());

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refreshDashboard,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Dashboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Monitor and manage all stores',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Stats cards
              Obx(() {
                if (controller.isLoadingStats.value) {
                  return Center(child: CircularProgressIndicator());
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      'Total Stores',
                      controller.totalStores.value.toString(),
                      Icons.store,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Active Stores',
                      controller.activeStores.value.toString(),
                      Icons.store_mall_directory,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Inactive Stores',
                      controller.inactiveStores.value.toString(),
                      Icons.store_mall_directory_outlined,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Total Owners',
                      controller.totalOwners.value.toString(),
                      Icons.people,
                      Colors.purple,
                    ),
                  ],
                );
              }),

              SizedBox(height: 24),

              // Recent activities
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Store Activities',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => Get.toNamed('/admin/manage-stores'),
                    icon: Icon(Icons.arrow_forward),
                    label: Text('View All'),
                  ),
                ],
              ),
              SizedBox(height: 12),

              Obx(() {
                if (controller.isLoadingActivities.value) {
                  return Center(child: CircularProgressIndicator());
                }

                if (controller.recentActivities.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_activity,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text('No recent activities'),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  child: Column(
                    children: controller.recentActivities.take(5).map((
                      activity,
                    ) {
                      final isActive = activity['is_active'] ?? false;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? Colors.green[100]
                              : Colors.red[100],
                          child: Icon(
                            Icons.store,
                            color: isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          activity['name'] ?? 'Unknown Store',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Status: ${isActive ? 'Active' : 'Inactive'}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDate(activity['updated_at']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 2),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),

              SizedBox(height: 24),

              // Quick actions
              Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: () => Get.toNamed('/admin/manage-stores'),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.manage_accounts,
                                size: 32,
                                color: Colors.blue,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Manage Stores',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        onTap: controller.refreshDashboard,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.refresh,
                                size: 32,
                                color: Colors.green,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Refresh Data',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
