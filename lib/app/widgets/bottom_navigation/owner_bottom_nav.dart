import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:restaurant/app/widgets/notification/custom_toast.dart';

class OwnerBottomNavController extends GetxController {
  var selectedIndex = 0.obs;
  var pendingOrdersCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _updateSelectedIndex();
  }

  void changeTab(int index) {
    selectedIndex.value = index;

    switch (index) {
      case 0:
        Get.offAllNamed(Routes.DASHBOARD_OWNER);
        break;
      case 1:
        CustomToast.info(title: 'Coming Soon', message: 'Orders page');
        break;
      case 2:
        Get.offAllNamed(Routes.STORE);
        break;
      case 3:
        CustomToast.info(title: 'Coming Soon', message: 'Profile page');
        break;
    }
  }

  void _updateSelectedIndex() {
    switch (Get.currentRoute) {
      case Routes.DASHBOARD_OWNER:
        selectedIndex.value = 0;
        break;
      case Routes.STORE:
        selectedIndex.value = 2;
        break;
    }
  }
}

class OwnerBottomNav extends StatelessWidget {
  OwnerBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    // Create controller if it doesn't exist, or find existing one
    final navController = Get.put(OwnerBottomNavController(), permanent: true);

    return Obx(
      () => BottomNavigationBar(
        currentIndex: navController.selectedIndex.value,
        onTap: navController.changeTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Store'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
