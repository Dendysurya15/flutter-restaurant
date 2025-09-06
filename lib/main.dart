import 'package:restaurant/app/modules/cart_item/controllers/cart_item_controller.dart';
import 'package:restaurant/app/services/cart_service.dart';
import 'package:restaurant/app/services/order_service.dart';
import 'package:restaurant/app/services/payment_service.dart';
import 'package:restaurant/app/services/payment_timer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/services/auth_service.dart';
import 'package:restaurant/app/utils/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart'; // Add this
import 'app/routes/app_pages.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  Get.put(prefs, permanent: true);

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Midtrans SDK
  MidtransSDK.init(
    config: MidtransConfig(
      clientKey: dotenv.env['MIDTRANS_CLIENT_KEY']!,
      merchantBaseUrl: dotenv.env['MIDTRANS_MERCHANT_BASE_URL']!,
      colorTheme: ColorTheme(
        colorPrimary: Colors.blue,
        colorPrimaryDark: Colors.blue.shade800,
        colorSecondary: Colors.blueAccent,
      ),
    ),
  );

  final cartService = CartService();
  await cartService.init();
  Get.put(cartService, permanent: true);
  // Add these lines:
  Get.put(OrderService(), permanent: true);
  Get.put(PaymentService(), permanent: true);
  Get.put(PaymentTimerService(), permanent: true);
  Get.put(CartItemController(), permanent: true);

  runApp(MyApp());
}

// Rest of your code stays exactly the same
class MyApp extends StatelessWidget {
  final authC = Get.put(AuthService(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: authC.streamAuthStatus,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.active) {
          final session = asyncSnapshot.data?.session;
          final user = session?.user;

          return ToastificationWrapper(
            child: GetMaterialApp(
              title: 'Restaurant App with Supabase',
              debugShowCheckedModeBanner: false,
              initialRoute: user != null && user.emailConfirmedAt != null
                  ? Routes.HOME
                  : Routes.LOGIN,
              getPages: AppPages.routes,
              theme: ThemeData(primarySwatch: Colors.blue),
            ),
          );
        }
        return LoadingView();
      },
    );
  }
}
