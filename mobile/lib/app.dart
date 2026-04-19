import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'controllers/matches_controller.dart';
import 'screens/auth_landing_page.dart';
import 'screens/matches_page.dart';
import 'services/matches_api.dart';
import 'services/socket_service.dart';

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
            borderSide:
                const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isRestoring) {
            return const _BootScreen();
          }

          // Show "check your email" after register
          if (controller.pendingVerification) {
            return _VerificationPendingScreen(controller: controller);
          }

          if (controller.isAuthenticated) {
            return _AppShell(controller: controller);
          }

          return AuthLandingPage(controller: controller);
        },
      ),
    );
  }
}

// ── Boot splash ──────────────────────────────────────────────────────────────

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFE24B4A)),
            SizedBox(height: 16),
            Text('Loading Hot Take...'),
          ],
        ),
      ),
    );
  }
}

// ── Email verification pending ───────────────────────────────────────────────

class _VerificationPendingScreen extends StatelessWidget {
  final AuthController controller;

  const _VerificationPendingScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand
              const Text(
                'hot take.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1714),
                ),
              ),
              const SizedBox(height: 48),

              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: Color(0xFFE24B4A),
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'check your email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1714),
                ),
              ),
              const SizedBox(height: 12),

              // Email address
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888780),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                        text:
                            'we sent a verification link to\n'),
                    TextSpan(
                      text: controller.pendingVerificationEmail ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1A1714),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(
                        text:
                            '.\n\nclick it to activate your account, then come back and sign in.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Spam note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EFE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "didn't get it? check your spam folder.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888780),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const Spacer(),

              // Try again / back to sign in
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => controller.dismissVerification(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFD9D4CC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'back to sign in',
                    style: TextStyle(color: Color(0xFF888780)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main app shell with bottom navbar ───────────────────────────────────────

class _AppShell extends StatefulWidget {
  final AuthController controller;

  const _AppShell({required this.controller});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _selectedIndex = 3; // default to matches tab

  late final MatchesController _matchesController;
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();

    final token = widget.controller.token!;
    final userId = widget.controller.user!.id;

    _matchesController = MatchesController(
      api: MatchesApi(),
      token: token,
      userId: userId,
    );

    _socketService = SocketService(token: token, userId: userId);
    _socketService.attach(_matchesController);
    _socketService.connect('http://127.0.0.1:3001');
  }

  @override
  void dispose() {
    _socketService.disconnect();
    _matchesController.dispose();
    super.dispose();
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const _PlaceholderPage(label: 'home');
      case 1:
        return const _PlaceholderPage(label: 'how it works');
      case 2:
        return const _PlaceholderPage(label: 'interests');
      case 3:
        return MatchesPage(
          matchesController: _matchesController,
          authController: widget.controller,
          socketService: _socketService,
        );
      case 4:
        return const _PlaceholderPage(label: 'chat');
      default:
        return const _PlaceholderPage(label: 'home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE9E8),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFE24B4A)),
            label: 'home',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info, color: Color(0xFFE24B4A)),
            label: 'how it works',
          ),
          NavigationDestination(
            icon: Icon(Icons.interests_outlined),
            selectedIcon: Icon(Icons.interests, color: Color(0xFFE24B4A)),
            label: 'interests',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite, color: Color(0xFFE24B4A)),
            label: 'matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFFE24B4A)),
            label: 'chat',
          ),
        ],
      ),
    );
  }
}

// ── Placeholder for unbuilt tabs ─────────────────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  final String label;

  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          color: Color(0xFF888780),
        ),
      ),
    );
  }
}