// dashboard_owner_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:toastification/toastification.dart';
// import 'package:restaurant/app/widgets/bottom_navigation/owner_bottom_nav.dart';
import '../controllers/dashboard_owner_controller.dart';

class DashboardOwnerView extends GetView<DashboardOwnerController> {
  const DashboardOwnerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.orange, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title + address
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "My Home",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text("Rio Nowakowska"),
                                Text("Zabiniec Street 12, Apartment 222"),
                                Text(
                                  "31-215 Kraków, Lesser Poland Voivodeship",
                                ),
                                Text("+48 791 234 567"),
                              ],
                            ),
                          ),

                          // Trailing rounded map
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.network(
                              "https://picsum.photos/200/300",
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // "Active" rounded status
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Fully rounded
                        ),
                        child: const Text(
                          "Active",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),

                    // Three-dot menu button
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ToastHelper.showToast(
                  context: context,
                  title: "Component updates available",
                  description: "Please update your components to continue.",
                  type: ToastificationType.warning,
                );
              },
              child: const Text('Perform Action'),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: OwnerBottomNav(), // Sticky navigation
    );
  }
}
