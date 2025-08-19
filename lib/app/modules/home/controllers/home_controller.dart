import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/modules/dashboard_owner/views/dashboard_owner_view.dart';
import 'package:restaurant/app/modules/store/views/store_view.dart';

class HomeController extends GetxController {
  final selectedIndex = 0.obs;

  final Map<String, List<Widget>> pageConfig = {
    "owner": [
      DashboardOwnerView(), // replace with your actual view
      StoreView(),
    ],
    "customer": [
      DashboardOwnerView(),
      StoreView(), // from your GetX CLI "store" module
    ],
  };

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
