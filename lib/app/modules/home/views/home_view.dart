import 'package:restaurant/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

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
          actions: [
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
