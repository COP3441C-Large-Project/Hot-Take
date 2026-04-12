import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'screens/auth_landing_page.dart';
import 'screens/home_placeholder_page.dart';

class HotTakeApp extends StatelessWidget {
  final AuthController controller;

  const HotTakeApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hot Take',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE24B4A),
          brightness: Brightness.light,
          surface: const Color(0xFFF7F5F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1714),
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD9D4CC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD9D4CC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isRestoring) {
            return const _BootScreen();
          }

          if (controller.isAuthenticated) {
            return HomePlaceholderPage(controller: controller);
          }

          return AuthLandingPage(controller: controller);
        },
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFE24B4A),
            ),
            SizedBox(height: 16),
            Text('Loading Hot Take...'),
          ],
        ),
      ),
    );
  }
}
