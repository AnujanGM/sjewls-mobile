import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

void main() {
  runApp(const SJewlsApp());
}

class SJewlsApp extends StatelessWidget {
  const SJewlsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SJewls',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Temporary logo placeholder
            Icon(
              Icons.diamond,
              size: 80,
              color: AppColors.gold,
            ),
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
            const CircularProgressIndicator(
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}