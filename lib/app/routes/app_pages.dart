import 'package:get/get.dart';

import '../modules/admin_manage_store/bindings/admin_manage_store_binding.dart';
import '../modules/admin_manage_store/views/admin_manage_store_view.dart';
import '../modules/cart_item/bindings/cart_item_binding.dart';
import '../modules/cart_item/views/cart_item_view.dart';
import '../modules/dashboard_admin/bindings/dashboard_admin_binding.dart';
import '../modules/dashboard_admin/views/dashboard_admin_view.dart';
import '../modules/dashboard_customer/bindings/dashboard_customer_binding.dart';
import '../modules/dashboard_customer/views/dashboard_customer_view.dart';
import '../modules/dashboard_customer/views/search_customer_view.dart';
import '../modules/dashboard_owner/bindings/dashboard_owner_binding.dart';
import '../modules/dashboard_owner/views/dashboard_owner_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/purchased_store_detail/bindings/purchased_store_detail_binding.dart';
import '../modules/purchased_store_detail/views/purchased_store_detail_view.dart';
import '../modules/reset_password/bindings/reset_password_binding.dart';
import '../modules/reset_password/views/reset_password_view.dart';
import '../modules/signup/bindings/signup_binding.dart';
import '../modules/signup/views/signup_view.dart';
import '../modules/store/bindings/store_binding.dart';
import '../modules/store/views/category_form_view.dart';
import '../modules/store/views/menu_item_form_view.dart';
import '../modules/store/views/store_detail_view.dart';
import '../modules/store/views/store_form_view.dart';
import '../modules/store/views/store_view.dart';

// Add these new imports

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(name: _Paths.HOME, page: () => HomeView(), binding: HomeBinding()),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.SIGNUP,
      page: () => const SignupView(),
      binding: SignupBinding(),
    ),
    GetPage(
      name: _Paths.RESET_PASSWORD,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: _Paths.STORE,
      page: () => const StoreView(),
      binding: StoreBinding(),
    ),
    GetPage(
      name: _Paths.STORE_FORM,
      page: () => const StoreFormView(),
      binding: StoreBinding(),
    ),
    // Add these new routes
    GetPage(
      name: _Paths.STORE_DETAIL,
      page: () => const StoreDetailView(),
      binding: StoreBinding(), // Use same binding since we updated it
    ),
    GetPage(
      name: _Paths.CATEGORY_FORM,
      page: () => const CategoryFormView(),
      binding: StoreBinding(), // Use same binding
    ),
    GetPage(
      name: _Paths.MENU_ITEM_FORM,
      page: () => const MenuItemFormView(),
      binding: StoreBinding(), // Use same binding
    ),
    GetPage(
      name: _Paths.DASHBOARD_OWNER,
      page: () => const DashboardOwnerView(),
      binding: DashboardOwnerBinding(),
    ),
    GetPage(
      name: _Paths.ADMIN_MANAGE_STORE,
      page: () => const AdminManageStoreView(),
      binding: AdminManageStoreBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD_ADMIN,
      page: () => DashboardAdminView(),
      binding: DashboardAdminBinding(),
    ),
    GetPage(
      name: _Paths.SEARCH_PAGE_CUSTOMER,
      page: () => const SearchCustomerView(),
      binding: DashboardCustomerBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.PURCHASED_STORE_DETAIL,
      page: () => const PurchasedStoreDetailView(),
      binding: PurchasedStoreDetailBinding(),
    ),
    GetPage(
      name: _Paths.CART_ITEM,
      page: () => const CartItemView(),
      binding: CartItemBinding(),
    ),
  ];
}
