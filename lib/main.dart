import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_get_x/app/controllers/auth_controller.dart';
import 'package:firebase_auth_get_x/app/modules/home/views/home_view.dart';
import 'package:firebase_auth_get_x/app/modules/login/controllers/login_controller.dart';
import 'package:firebase_auth_get_x/app/modules/login/views/login_view.dart';
import 'package:firebase_auth_get_x/app/utils/loading.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final authC = Get.put(AuthController(), permanent: true);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authC.streamtAuthStatus,
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.connectionState == ConnectionState.active) {
          return GetMaterialApp(
            title: 'Firebase Auth with GetX',
            initialRoute: asyncSnapshot.data != null
                ? AppPages.INITIAL
                : Routes.LOGIN,
            getPages: AppPages.routes,
            // home: asyncSnapshot.data != null
            //     ? const HomeView()
            //     : const LoginView(),
            theme: ThemeData(primarySwatch: Colors.blue),
          );
        }
        return LoadingView();
      },
    );
  }
}
