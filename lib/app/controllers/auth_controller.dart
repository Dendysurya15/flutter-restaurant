import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_get_x/app/routes/app_pages.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;

  Stream<User?> get streamtAuthStatus => auth.authStateChanges();

  void login(String email, String password) async {
    try {
      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (user.user!.emailVerified) {
        Get.offAllNamed(Routes.HOME);
      } else {
        Get.defaultDialog(
          title: "Verifikasi Email",
          middleText:
              "Kamu belum memverifikasi emailmu. Silakan cek emailmu. Apakah kamu ingin mengirim ulang email verifikasi?",
          onConfirm: () async {
            await user.user!.sendEmailVerification();
            Get.back();
          },
          textConfirm: "Ya, Kirim Ulang Email Verifikasi",
          textCancel: "Kembali",
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        Get.defaultDialog(
          title: "User Not Found",
          middleText: "No user found for that email. Please try again.",
        );
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        Get.defaultDialog(
          title: "Wrong Password",
          middleText:
              "Wrong password provided for that user. Please try again.",
        );
      }
    } catch (e) {
      print(e);
      Get.defaultDialog(
        title: "Error",
        middleText: "An error occurred while logging in. ${e.toString()}",
      );
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }

  void signup(String email, String password) async {
    try {
      UserCredential user = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (user.user!.emailVerified) {
        Get.offAll(Routes.HOME);
      } else {
        await user.user!.sendEmailVerification();
        Get.defaultDialog(
          title: "Verifikasi Email",
          middleText:
              "Kami telah mengirimkan email verifikasi ke $email. Silakan cek emailmu.",
          onConfirm: () {
            Get.back();
            Get.back();
          },
          textConfirm: "Ya, Saya akan cek email",
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        Get.defaultDialog(
          title: "Weak Password",
          middleText: "The password provided is too weak. Please try again.",
        );
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        Get.defaultDialog(
          title: "Email Already In Use",
          middleText:
              "The account already exists for that email. Please try a different email.",
        );
      }
    } catch (e) {
      print(e);
      Get.defaultDialog(
        title: "Error",
        middleText: "An error occurred while signing up. ${e.toString()}",
      );
    }
  }
}
