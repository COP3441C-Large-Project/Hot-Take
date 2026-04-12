import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';

class HomePlaceholderPage extends StatelessWidget {
  final AuthController controller;

  const HomePlaceholderPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final user = controller.user;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F5F2), Color(0xFFFFEFE2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You are in.',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Signed in as ${user?.username ?? 'a user'}',
                          style: const TextStyle(fontSize: 16, color: Color(0xFF5C5752)),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'This is the signed-in placeholder. Next, we can route here into interests, matches, or chat.',
                          style: TextStyle(fontSize: 15, height: 1.4),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: controller.logout,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE24B4A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Log out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
