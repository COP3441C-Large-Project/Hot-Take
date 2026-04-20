import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../controllers/auth_controller.dart';

enum AuthMode { login, register }

class AuthLandingPage extends StatefulWidget {
  final AuthController controller;

  const AuthLandingPage({super.key, required this.controller});

  @override
  State<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends State<AuthLandingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _forgotEmailController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  bool _showForgot = false;
  bool _showForgotSent = false;
  bool _isSendingReset = false;
  String? _forgotError;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  void _setMode(AuthMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    _formKey.currentState?.reset();
    widget.controller.clearError();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.controller.clearError();

    if (_mode == AuthMode.login) {
      await widget.controller.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      await widget.controller.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  Future<void> _sendForgotPassword() async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty) {
      setState(() => _forgotError = 'Email is required.');
      return;
    }

    setState(() {
      _isSendingReset = true;
      _forgotError = null;
    });

    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:3001/api/auth/forgot-password'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['error'] != null) {
        setState(() => _forgotError = body['error'] as String);
      } else {
        setState(() => _showForgotSent = true);
      }
    } catch (_) {
      setState(() => _forgotError = 'Unable to send reset email right now.');
    } finally {
      setState(() => _isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Forgot password sent ─────────────────────────────────────────────────
    if (_showForgotSent) {
      return _ForgotSentScreen(
        email: _forgotEmailController.text.trim(),
        onBack: () => setState(() {
          _showForgotSent = false;
          _showForgot = false;
          _forgotEmailController.clear();
        }),
      );
    }

    // ── Forgot password form ─────────────────────────────────────────────────
    if (_showForgot) {
      return _ForgotScreen(
        emailController: _forgotEmailController,
        error: _forgotError,
        isSending: _isSendingReset,
        onSend: _sendForgotPassword,
        onBack: () => setState(() {
          _showForgot = false;
          _forgotError = null;
        }),
      );
    }

    // ── Main auth screen ─────────────────────────────────────────────────────
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            child: _BrandPanel(
                              compact: false,
                              onSignIn: () => _setMode(AuthMode.login),
                            ),
                          ),
                          Expanded(
                            child: _AuthPanel(
                              mode: _mode,
                              controller: widget.controller,
                              formKey: _formKey,
                              usernameController: _usernameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController: _confirmPasswordController,
                              onModeChanged: _setMode,
                              onSubmit: _submit,
                              onForgotPassword: () => setState(() {
                                _showForgot = true;
                                _forgotError = null;
                              }),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _BrandPanel(
                            compact: true,
                            onSignIn: () => _setMode(AuthMode.login),
                          ),
                          _AuthPanel(
                            mode: _mode,
                            controller: widget.controller,
                            formKey: _formKey,
                            usernameController: _usernameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController: _confirmPasswordController,
                            onModeChanged: _setMode,
                            onSubmit: _submit,
                            onForgotPassword: () => setState(() {
                              _showForgot = true;
                              _forgotError = null;
                            }),
                          ),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Forgot password form screen ──────────────────────────────────────────────

class _ForgotScreen extends StatelessWidget {
  final TextEditingController emailController;
  final String? error;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onBack;

  const _ForgotScreen({
    required this.emailController,
    required this.error,
    required this.isSending,
    required this.onSend,
    required this.onBack,
  });

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
              const Text(
                'hot take.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1714),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'forgot password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1714),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "enter your email and we'll send a reset link.",
                style: TextStyle(fontSize: 14, color: Color(0xFF888780)),
              ),
              const SizedBox(height: 28),
              const Text(
                'EMAIL',
                style: TextStyle(
                  color: Color(0xFF888780),
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: const TextStyle(color: Color(0xFFAAA49C)),
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
                    borderSide: const BorderSide(
                      color: Color(0xFFE24B4A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: const TextStyle(
                    color: Color(0xFF8F2D2D),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSending ? null : onSend,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE24B4A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isSending ? 'sending...' : 'send reset link'),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onBack,
                child: const Text(
                  '← back to sign in',
                  style: TextStyle(
                    color: Color(0xFF888780),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF888780),
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

// ── Forgot password sent screen ──────────────────────────────────────────────

class _ForgotSentScreen extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _ForgotSentScreen({required this.email, required this.onBack});

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
              const Text(
                'hot take.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1714),
                ),
              ),
              const SizedBox(height: 48),
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
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888780),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'if an account exists for\n'),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        color: Color(0xFF1A1714),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(
                      text: ',\nwe sent a reset link. it expires in 1 hour.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              GestureDetector(
                onTap: onBack,
                child: const Text(
                  '← back to sign in',
                  style: TextStyle(
                    color: Color(0xFF888780),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF888780),
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

// ── Brand panel ──────────────────────────────────────────────────────────────

class _BrandPanel extends StatelessWidget {
  final bool compact;
  final VoidCallback onSignIn;

  const _BrandPanel({required this.compact, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? 20.0 : 32.0;
    final titleSize = compact ? 54.0 : 72.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE24B4A), Color(0xFFC93E3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: _AccentCircle(
              size: compact ? 120 : 170,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: _AccentCircle(
              size: compact ? 180 : 240,
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? 28 : 42,
              horizontalPadding,
              compact ? 20 : 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        height: 0.9,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Text(
                      'take.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        height: 0.9,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Match on shared interests. No profile photos. Less noise.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: compact ? 13 : 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _BrandChip(label: 'anonymous'),
                        _BrandChip(label: 'interest-based'),
                        _BrandChip(label: 'low pressure'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALREADY HAVE AN ACCOUNT?',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: onSignIn,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4A1B0C),
                        foregroundColor: const Color(0xFFEF9F27),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('sign in →'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'hot take · interest-based matchmaking',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auth panel ───────────────────────────────────────────────────────────────

class _AuthPanel extends StatelessWidget {
  final AuthMode mode;
  final AuthController controller;
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueChanged<AuthMode> onModeChanged;
  final Future<void> Function() onSubmit;
  final VoidCallback? onForgotPassword;

  const _AuthPanel({
    required this.mode,
    required this.controller,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onModeChanged,
    required this.onSubmit,
    this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F5F2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLogin ? 'sign in' : 'create account',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1714),
                ),
              ),
              const SizedBox(height: 18),
              _ModeTabs(mode: mode, onModeChanged: onModeChanged),
              const SizedBox(height: 24),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isLogin) ...[
                      _LabeledField(
                        label: 'USERNAME',
                        controller: usernameController,
                        onChanged: () => controller.clearError(),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Username is required.'
                                : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _LabeledField(
                      label: 'EMAIL',
                      controller: emailController,
                      onChanged: () => controller.clearError(),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Email is required.'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'PASSWORD',
                      controller: passwordController,
                      obscureText: true,
                      onChanged: () => controller.clearError(),
                      validator: (value) =>
                          (value == null || value.isEmpty)
                              ? 'Password is required.'
                              : null,
                    ),
                    if (!isLogin) ...[
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'CONFIRM PASSWORD',
                        controller: confirmPasswordController,
                        obscureText: true,
                        onChanged: () => controller.clearError(),
                        validator: (value) {
                          if (value != passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (controller.error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF3B1AF)),
                        ),
                        child: Text(
                          controller.error!,
                          style: const TextStyle(
                            color: Color(0xFF8F2D2D),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            controller.isBusy ? null : () => onSubmit(),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE24B4A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: controller.isBusy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isLogin ? 'sign in' : 'create account'),
                      ),
                    ),
                    if (isLogin) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: onForgotPassword,
                          child: const Text(
                            'forgot password?',
                            style: TextStyle(
                              color: Color(0xFF888780),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF888780),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mode tabs ────────────────────────────────────────────────────────────────

class _ModeTabs extends StatelessWidget {
  final AuthMode mode;
  final ValueChanged<AuthMode> onModeChanged;

  const _ModeTabs({required this.mode, required this.onModeChanged});

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'sign in',
              selected: isLogin,
              onTap: () => onModeChanged(AuthMode.login),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TabButton(
              label: 'register',
              selected: !isLogin,
              onTap: () => onModeChanged(AuthMode.register),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab button ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF1EFE8),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF1A1714)
                : const Color(0xFF888780),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Labeled field ────────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback onChanged;
  final String? Function(String?) validator;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.validator,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888780),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: (_) => onChanged(),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFAAA49C)),
          ),
        ),
      ],
    );
  }
}

// ── Brand chip ───────────────────────────────────────────────────────────────

class _BrandChip extends StatelessWidget {
  final String label;

  const _BrandChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Accent circle ────────────────────────────────────────────────────────────

class _AccentCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _AccentCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}