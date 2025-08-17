import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final supabase = Supabase.instance.client;

  // Stream for auth state changes (like Firebase)
  Stream<AuthState> get streamAuthStatus => supabase.auth.onAuthStateChange;

  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Get JWT Token (this is automatic!)
  String? get accessToken => supabase.auth.currentSession?.accessToken;

  // Get user role
  String get userRole => currentUser?.userMetadata?['role'] ?? 'customer';

  void resetPassword(String email) async {
    print("Reset Password for $email");
    if (email != "" && GetUtils.isEmail(email)) {
      try {
        await supabase.auth.resetPasswordForEmail(email);
        Get.defaultDialog(
          title: "Email Terkirim",
          middleText:
              "Kami telah mengirimkan email untuk mereset password ke $email.",
          onConfirm: () {
            Get.back();
            Get.back();
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

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print("user: ${response.user}");
      print("JWT Token: ${response.session?.accessToken}"); // Your token!

      if (response.user != null) {
        // Check if email is verified (Supabase auto-verifies by default)
        if (response.user!.emailConfirmedAt != null) {
          // Create user profile with role if doesn't exist
          await _createUserRecord(response.user!);
          Get.offAllNamed(Routes.HOME);
        } else {
          Get.defaultDialog(
            title: "Verifikasi Email",
            middleText:
                "Kamu belum memverifikasi emailmu. Silakan cek emailmu. Apakah kamu ingin mengirim ulang email verifikasi?",
            onConfirm: () async {
              await supabase.auth.resend(type: OtpType.signup, email: email);
              Get.back();
            },
            textConfirm: "Ya, Kirim Ulang Email Verifikasi",
            textCancel: "Kembali",
          );
        }
      }
    } on AuthException catch (e) {
      print("AuthException: ${e.message}");
      if (e.message.contains('Invalid login credentials')) {
        Get.defaultDialog(
          title: "Login Gagal",
          middleText: "Email atau password salah. Silakan coba lagi.",
        );
      } else if (e.message.contains('Email not confirmed')) {
        Get.defaultDialog(
          title: "Email Belum Diverifikasi",
          middleText: "Silakan verifikasi email terlebih dahulu.",
        );
      } else {
        Get.defaultDialog(
          title: "Authentication Error",
          middleText: "${e.message}",
        );
      }
    } catch (e) {
      print("Non-Auth error: ${e.toString()}");
      Get.defaultDialog(
        title: "Unexpected Error",
        middleText: "Terjadi kesalahan saat login: ${e.toString()}",
      );
    }
  }

  void logout() async {
    await supabase.auth.signOut();
    Get.offAllNamed(Routes.LOGIN);
  }

  void signup(String email, String password, {String role = 'customer'}) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role, // Set user role during signup
        },
      );

      if (response.user != null) {
        if (response.user!.emailConfirmedAt != null) {
          // Email auto-confirmed
          await _createUserRecord(response.user!);
          Get.offAllNamed(Routes.HOME);
        } else {
          // Email verification required
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
      }
    } on AuthException catch (e) {
      if (e.message.contains('Password should be at least 6 characters')) {
        Get.defaultDialog(
          title: "Weak Password",
          middleText: "Password harus minimal 6 karakter. Silakan coba lagi.",
        );
      } else if (e.message.contains('User already registered')) {
        Get.defaultDialog(
          title: "Email Already In Use",
          middleText:
              "Email sudah terdaftar. Silakan gunakan email lain atau login.",
        );
      } else {
        Get.defaultDialog(title: "Signup Error", middleText: "${e.message}");
      }
    } catch (e) {
      print(e);
      Get.defaultDialog(
        title: "Error",
        middleText: "An error occurred while signing up. ${e.toString()}",
      );
    }
  }

  // Create user record in database with role
  Future<void> _createUserRecord(User user) async {
    try {
      final existingUser = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        await supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'role': user.userMetadata?['role'] ?? 'customer',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error creating user record: $e');
    }
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return userRole == role;
  }

  // Check if user is admin
  bool get isAdmin => hasRole('admin');

  // Check if user is owner
  bool get isOwner => hasRole('owner');

  // Check if user is customer
  bool get isCustomer => hasRole('customer');

  // Check if user has admin or owner privileges
  bool get hasManagerAccess => isAdmin || isOwner;

  // Update user role (admin only)
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await supabase.from('users').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes
    supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user == null) {
        Get.offAllNamed(Routes.LOGIN);
      }
    });
  }
}
