import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restaurant/app/routes/app_pages.dart';
import 'package:get/get.dart';

class AuthService extends GetxController {
  final supabase = Supabase.instance.client;

  // Reactive variables
  final userRole = 'customer'.obs; // Make userRole reactive
  final isLoading = false.obs;
  final currentUserData = Rxn<User>(); // Reactive current user

  // Stream for auth state changes (like Firebase)
  Stream<AuthState> get streamAuthStatus => supabase.auth.onAuthStateChange;

  // Get current user
  User? get currentUser => supabase.auth.currentUser;

  // Get JWT Token (this is automatic!)
  String? get accessToken => supabase.auth.currentSession?.accessToken;

  // Get user role (now reactive)
  String get getUserRole => userRole.value;

  void resetPassword(String email) async {
    if (email != "" && GetUtils.isEmail(email)) {
      try {
        isLoading.value = true;
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
      } finally {
        isLoading.value = false;
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
      isLoading.value = true;
      print("Login with email: $email, password: $password");

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print("user: ${response.user}");
      print("JWT Token: ${response.session?.accessToken}");

      if (response.user != null) {
        // Update reactive user data
        currentUserData.value = response.user;

        // Check if email is verified (Supabase auto-verifies by default)
        if (response.user!.emailConfirmedAt != null) {
          // Create user profile with role if doesn't exist
          await _createUserRecord(response.user!);

          // Update reactive user role
          await _updateUserRole(response.user!);

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
        Get.defaultDialog(title: "Authentication Error", middleText: e.message);
      }
    } catch (e) {
      print("Non-Auth error: ${e.toString()}");
      Get.defaultDialog(
        title: "Unexpected Error",
        middleText: "Terjadi kesalahan saat login: ${e.toString()}",
      );
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    try {
      isLoading.value = true;
      await supabase.auth.signOut();

      // Reset reactive variables
      userRole.value = 'customer';
      currentUserData.value = null;

      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      print("Logout error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void signup(String email, String password, {String role = 'customer'}) async {
    try {
      isLoading.value = true;

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role, // Set user role during signup
        },
      );

      if (response.user != null) {
        // Update reactive user data
        currentUserData.value = response.user;

        if (response.user!.emailConfirmedAt != null) {
          // Email auto-confirmed
          await _createUserRecord(response.user!);

          // Update reactive user role
          await _updateUserRole(response.user!);

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
        Get.defaultDialog(title: "Signup Error", middleText: e.message);
      }
    } catch (e) {
      print(e);
      Get.defaultDialog(
        title: "Error",
        middleText: "An error occurred while signing up. ${e.toString()}",
      );
    } finally {
      isLoading.value = false;
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
          'full_name': user.userMetadata?['full_name'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('User record created successfully');
      } else {
        print('User record already exists');
      }
    } catch (e) {
      print('Error creating user record: $e');
    }
  }

  // Update reactive user role from user metadata or database
  Future<void> _updateUserRole(User user) async {
    try {
      // First try to get role from user metadata
      String role = user.userMetadata?['role'] ?? 'customer';

      // If no role in metadata, get from database
      if (role == 'customer') {
        final userData = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        if (userData != null && userData['role'] != null) {
          role = userData['role'];
        }
      }

      // Update reactive role
      userRole.value = role;
      print('User role updated to: $role');
    } catch (e) {
      print('Error updating user role: $e');
      userRole.value = 'customer'; // Default fallback
    }
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return userRole.value == role;
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

      // If updating current user's role, update reactive variable
      if (userId == currentUser?.id) {
        userRole.value = newRole;
      }

      print('User role updated successfully');
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Method to refresh user data
  Future<void> refreshUserData() async {
    final user = currentUser;
    if (user != null) {
      currentUserData.value = user;
      await _updateUserRole(user);
    }
  }

  // Method to check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Method to get user display name
  String get userDisplayName {
    final user = currentUser;
    if (user != null) {
      return user.userMetadata?['full_name'] ??
          user.email?.split('@')[0] ??
          'User';
    }
    return 'Guest';
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAuth();
  }

  void _initializeAuth() {
    // Listen to auth changes
    supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;

      if (user == null) {
        // User logged out
        userRole.value = 'customer';
        currentUserData.value = null;

        // Only navigate to login if not already there
        if (Get.currentRoute != Routes.LOGIN) {
          Get.offAllNamed(Routes.LOGIN);
        }
      } else {
        // User logged in
        currentUserData.value = user;
        await _updateUserRole(user);

        print(
          'Auth state changed - User: ${user.email}, Role: ${userRole.value}',
        );
      }
    });

    // Initialize current user if already logged in
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      currentUserData.value = currentUser;
      _updateUserRole(currentUser);
    }
  }

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
