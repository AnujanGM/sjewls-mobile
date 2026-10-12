import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sjewls_mobile/features/auth/presentation/home_screen.dart';
import 'package:sjewls_mobile/features/auth/presentation/otp_screen.dart';
import 'package:sjewls_mobile/features/auth/presentation/registration_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../core/theme/app_colors.dart';

// This is the single source of truth for all navigation
final GoRouter appRouter = GoRouter(
  initialLocation: '/',          // App starts here
  routes: [
    // Splash
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Login
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    // OTP
    GoRoute(
      path: '/otp',
      name: 'otp',
      builder: (context, state){
        final extra = state.extra as Map<String, dynamic>?; // Cast extra to a Map
        return OtpScreen(
          contact: extra?['contact'] ?? '', // Use the contact from extra or default to an empty string
          isPhone: extra?['isPhone'] ?? true, // Use the isPhone from extra or default to true
        );
      }
    ),
    // Registration
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    // Home (placeholder)
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    // We will add Home, Chitu, Jewellery etc. later
  ],
);

// Temporary Splash (we will move it later)
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto navigate to Login after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.diamond, size: 80, color: AppColors.gold),
            const SizedBox(height: 24),
            Text(
              'SARANGA',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            Text(
              'JEWELLERY',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}