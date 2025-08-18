import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerBottomNavController extends GetxController {
  var selectedIndex = 0.obs;
  var unreadNotificationsCount = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void updateNotificationsCount(int count) {
    unreadNotificationsCount.value = count;
  }
}

class CustomerBottomNav extends StatelessWidget {
  final CustomerBottomNavController navController = Get.put(
    CustomerBottomNavController(),
  );

  CustomerBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: navController.selectedIndex.value,
        onTap: navController.changeTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: _buildHistoryIcon(), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHistoryIcon() {
    return Stack(
      children: [
        Icon(Icons.history),
        if (navController.unreadNotificationsCount.value > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '${navController.unreadNotificationsCount.value}',
                style: TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
