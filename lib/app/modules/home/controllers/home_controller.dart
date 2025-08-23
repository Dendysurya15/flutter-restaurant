import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant/app/helper/toast_helper.dart';
import 'package:restaurant/app/modules/admin_manage_store/views/admin_manage_store_view.dart';
import 'package:restaurant/app/modules/dashboard_admin/views/dashboard_admin_view.dart';
import 'package:restaurant/app/modules/dashboard_owner/views/dashboard_owner_view.dart';
import 'package:restaurant/app/modules/store/views/store_view.dart';
import 'package:toastification/toastification.dart';

class HomeController extends GetxController {
  final selectedIndex = 0.obs;

  final Map<String, List<Widget>> pageConfig = {
    "owner": [DashboardOwnerView(), StoreView()],
    "admin": [DashboardAdminView(), AdminManageStoreView()],
    "customer": [DashboardOwnerView(), StoreView()],
  };
}
