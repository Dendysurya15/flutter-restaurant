import 'package:restaurant/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';
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
            // 👉 Show history only for customers
            if (userRole.toLowerCase() == "customer")
              Obx(() {
                final dashboardC = Get.find<DashboardCustomerController>();
                // Access the observable list directly, not the getter
                final pendingCount =
                    PaymentTimerService.to.activePayments.length;

                return Stack(
                  children: [
                    IconButton(
                      onPressed: dashboardC.goToOrdersHistory,
                      icon: const Icon(Icons.history),
                    ),
                    if (pendingCount > 0)
                      Positioned(
                        right: 4,
                        top: 3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
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
                  ],
                );
              }),

            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authC.logout(),
            ),
          ],
        ),
        body: Obx(() => pages[controller.selectedIndex.value]),
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
