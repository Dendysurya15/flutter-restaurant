import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/controllers/auth_controller.dart';
import 'package:restaurant/app/utils/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'app/routes/app_pages.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final authC = Get.put(AuthController(), permanent: true);

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
