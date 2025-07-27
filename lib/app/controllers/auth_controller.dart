import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_get_x/app/routes/app_pages.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;

  Stream<User?> get streamtAuthStatus => auth.authStateChanges();

  void resetPassword(String email) async {
    print("Reset Password for $email");
    if (email != "" && GetUtils.isEmail(email)) {
      try {
        await auth.sendPasswordResetEmail(email: email);
        Get.defaultDialog(
          title: "Email Terkirim",
          middleText:
              "Kami telah mengirimkan email untuk mereset password ke $email.",
          onConfirm: () {
            Get.back();
            Get.back(); // Navigate back to the previous screen
          },
          textConfirm: "Ya, Aku mengerti",
        );
      } catch (e) {
        print(e);
        Get.defaultDialog(
          title: "Error",
          middleText:
              "An error occurred while sending reset email. ${e.toString()}",
        );
      }
    } else {
      Get.defaultDialog(
        title: "Email Kosong",
        middleText: "Silakan masukkan email yang valid.",
      );
    }
  }

  void login(String email, String password) async {
    try {
      print("Login with email: $email, password: $password");

      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      print("user: ${user.user!}");

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
      print("FirebaseAuthException code: ${e.code}");
      if (e.code == 'invalid-credential') {
        Get.defaultDialog(
          title: "User Not Found",
          middleText: "Email tidak ditemukan. Silakan coba lagi.",
        );
      } else if (e.code == 'wrong-password') {
        Get.defaultDialog(
          title: "Wrong Password",
          middleText: "Password salah. Silakan coba lagi.",
        );
      } else {
        print("FirebaseAuthException: ${e.message}");
        Get.defaultDialog(
          title: "Authentication Error",
          middleText: "${e.message}",
        );
      }
    } catch (e) {
      print("Non-Firebase error: ${e.toString()}");
      Get.defaultDialog(
        title: "Unexpected Error",
        middleText: "Terjadi kesalahan saat login: ${e.toString()}",
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
