import 'package:restaurant/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';
import 'package:restaurant/app/services/customer_order_counter_service.dart';
import '../controllers/home_controller.dart';
import 'package:restaurant/app/modules/dashboard_customer/controllers/dashboard_customer_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    AuthService authC = Get.find<AuthService>();

    return Obx(() {
      final userRole = authC.userRole.value;

      // Define bottom nav items based on role
      final bottomNavItem = _getBottomNavItems(userRole);

      final pages =
          controller.pageConfig[userRole] ?? controller.pageConfig["customer"]!;

      return Scaffold(
        appBar: AppBar(
          title: Text('Welcome ${authC.userRole.value.toUpperCase()}'),
          centerTitle: true,
          backgroundColor: Colors.yellow,
          actions: [
            // Show history only for customers
            if (userRole.toLowerCase() == "customer")
              Obx(() {
                final dashboardC = Get.find<DashboardCustomerController>();
                final orderCounterService =
                    Get.find<CustomerOrderCounterService>();

                // Get visual update indicator
                final hasNewUpdates = orderCounterService.hasNewUpdates.value;
                final pendingCount = dashboardC.pendingOrdersCount;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      // Animated pulsing background when there are updates
                      if (hasNewUpdates)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                      // The actual icon button
                      IconButton(
                        onPressed: () {
                          dashboardC.goToOrdersHistory();
                        },
                        icon: Icon(
                          Icons.history,
                          color: hasNewUpdates ? Colors.orange : Colors.black,
                          size: 28,
                        ),
                      ),

                      // Badge with count (if any)
                      if (pendingCount > 0)
                        Positioned(
                          right: 4,
                          top: 3,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: hasNewUpdates ? Colors.orange : Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: hasNewUpdates
                                  ? [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      // Pulsing dot overlay when there are new updates
                    ],
                  ),
                );
              }),

            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authC.logout(),
            ),
          ],
        ),
        body: Column(
          children: [
            // New Update Banner for customers only
            if (userRole.toLowerCase() == "customer")
              Obx(() {
                final orderCounterService =
                    Get.find<CustomerOrderCounterService>();
                final hasNewUpdates = orderCounterService.hasNewUpdates.value;

                if (!hasNewUpdates) {
                  return const SizedBox.shrink();
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade100, Colors.orange.shade50],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.orange.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have new order updates! Check your order history.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final dashboardC =
                              Get.find<DashboardCustomerController>();
                          dashboardC.goToOrdersHistory();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: const Text('View'),
                      ),
                      IconButton(
                        onPressed: () {
                          orderCounterService.clearNewUpdates();
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.orange.shade600,
                          size: 20,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                );
              }),

            // Main content
            Expanded(child: Obx(() => pages[controller.selectedIndex.value])),
          ],
        ),
        bottomNavigationBar: userRole.toLowerCase() == "customer"
            ? null
            : Obx(
                () => BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  items: bottomNavItem,
                  currentIndex: controller.selectedIndex.value,
                  selectedItemColor: _getSelectedColor(userRole),
                  unselectedItemColor: Colors.grey,
                  onTap: (index) {
                    controller.selectedIndex.value = index;
                  },
                ),
              ),
      );
    });
  }

  List<BottomNavigationBarItem> _getBottomNavItems(String userRole) {
    switch (userRole.toLowerCase()) {
      case "owner":
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "My Stores"),
        ];
      case "admin":
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: "Manage Stores",
          ),
        ];
      default: // customer
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Stores"),
        ];
    }
  }

  Color _getSelectedColor(String userRole) {
    switch (userRole.toLowerCase()) {
      case "owner":
        return Colors.orange;
      case "admin":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
