import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../controllers/auth_controller.dart';

enum AuthMode { login, register }
enum _AuthStage { landing, form, forgot, forgotSent }

class _HotTakePalette {
  static const red = Color(0xFFE24B4A);
  static const orange = Color(0xFFEF9F27);
  static const brown = Color(0xFF4A1B0C);
  static const page = Color(0xFFF7F5F2);
  static const ink = Color(0xFF1A1714);
  static const muted = Color(0xFF888780);
  static const border = Color(0xFFD9D4CC);
}

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _forgotEmailController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  _AuthStage _stage = _AuthStage.landing;
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

  void _openForm(AuthMode mode) {
    setState(() {
      _mode = mode;
      _stage = _AuthStage.form;
      _forgotError = null;
    });
    _formKey.currentState?.reset();
    widget.controller.clearError();
  }

  void _setMode(AuthMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() => _mode = mode);
    _formKey.currentState?.reset();
    widget.controller.clearError();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.controller.clearError();

    if (_mode == AuthMode.login) {
      await widget.controller.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      return;
    }

    await widget.controller.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
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
        setState(() => _stage = _AuthStage.forgotSent);
      }
    } catch (_) {
      setState(() => _forgotError = 'Unable to send reset email right now.');
    } finally {
      setState(() => _isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _AuthStage.landing:
        return _LandingHeroScreen(
          onSignIn: () => _openForm(AuthMode.login),
          onSignUp: () => _openForm(AuthMode.register),
        );
      case _AuthStage.form:
        return _AuthFormScreen(
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
            _forgotError = null;
            _stage = _AuthStage.forgot;
          }),
          onBack: () => setState(() => _stage = _AuthStage.landing),
        );
      case _AuthStage.forgot:
        return _ForgotScreen(
          emailController: _forgotEmailController,
          error: _forgotError,
          isSending: _isSendingReset,
          onSend: _sendForgotPassword,
          onBack: () => setState(() {
            _forgotError = null;
            _stage = _AuthStage.form;
          }),
        );
      case _AuthStage.forgotSent:
        return _ForgotSentScreen(
          email: _forgotEmailController.text.trim(),
          onBack: () => setState(() {
            _forgotError = null;
            _forgotEmailController.clear();
            _stage = _AuthStage.form;
          }),
        );
    }
  }
}

class _LandingHeroScreen extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  const _LandingHeroScreen({required this.onSignIn, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HotTakePalette.red,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: _HotTakePalette.red,
                padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hot\ntake.',
                      style: GoogleFonts.dmMono(
                        color: Colors.white,
                        fontSize: 68,
                        height: 0.88,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'match based on shared interests.',
                      style: GoogleFonts.dmMono(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '────────────────────',
                      style: GoogleFonts.dmMono(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _Quip(
                      title: 'No Profiles',
                      body: 'anonymous by default',
                    ),
                    const SizedBox(height: 12),
                    const _Quip(
                      title: 'ML Matched',
                      body: 'by shared interests, not looks',
                    ),
                    const SizedBox(height: 12),
                    const _Quip(
                      title: 'Low Commitment',
                      body: "talk when you want. leave when you don't.",
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                color: _HotTakePalette.orange,
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALREADY HAVE AN ACCOUNT?',
                      style: GoogleFonts.dmMono(
                        color: _HotTakePalette.brown,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HoverActionButton(
                      label: 'sign in',
                      backgroundColor: _HotTakePalette.brown,
                      textColor: _HotTakePalette.orange,
                      onTap: onSignIn,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NEW USER?',
                      style: GoogleFonts.dmMono(
                        color: _HotTakePalette.brown,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HoverActionButton(
                      label: 'sign up',
                      backgroundColor: Colors.white,
                      textColor: _HotTakePalette.brown,
                      onTap: onSignUp,
                    ),
                    const Spacer(),
                    Center(
                      child: Text(
                        'hot take · interest-based matchmaking',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmMono(
                          color: _HotTakePalette.brown.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Quip extends StatelessWidget {
  final String title;
  final String body;

  const _Quip({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmMono(
            color: Colors.white.withValues(alpha: 0.76),
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: GoogleFonts.dmMono(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _AuthFormScreen extends StatelessWidget {
  final AuthMode mode;
  final AuthController controller;
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueChanged<AuthMode> onModeChanged;
  final Future<void> Function() onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onBack;

  const _AuthFormScreen({
    required this.mode,
    required this.controller,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onModeChanged,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;

    return Scaffold(
      backgroundColor: _HotTakePalette.page,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _HotTakePalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Text(
                        '← back',
                        style: GoogleFonts.dmMono(
                          color: _HotTakePalette.muted,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isLogin ? 'sign in' : 'create account',
                      style: GoogleFonts.dmMono(
                        color: _HotTakePalette.ink,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ModeTabs(mode: mode, onModeChanged: onModeChanged),
                    const SizedBox(height: 20),
                    Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isLogin) ...[
                            _LabeledField(
                              label: 'USERNAME',
                              controller: usernameController,
                              onChanged: controller.clearError,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Username is required.'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _LabeledField(
                            label: 'EMAIL',
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: controller.clearError,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Email is required.';
                              }
                              final emailPattern =
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (!emailPattern.hasMatch(email)) {
                                return 'Enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _LabeledField(
                            label: 'PASSWORD',
                            controller: passwordController,
                            obscureText: true,
                            onChanged: controller.clearError,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required.';
                              }
                              if (!isLogin) {
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters.';
                                }
                                final hasLetter =
                                    RegExp(r'[A-Za-z]').hasMatch(value);
                                final hasNumber = RegExp(r'\d').hasMatch(value);
                                if (!hasLetter || !hasNumber) {
                                  return 'Password must include letters and numbers.';
                                }
                              }
                              return null;
                            },
                          ),
                          if (!isLogin) ...[
                            const SizedBox(height: 12),
                            _LabeledField(
                              label: 'CONFIRM PASSWORD',
                              controller: confirmPasswordController,
                              obscureText: true,
                              onChanged: controller.clearError,
                              validator: (value) {
                                if (value != passwordController.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (controller.error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE9E8),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFF3B1AF),
                                ),
                              ),
                              child: Text(
                                controller.error!,
                                style: GoogleFonts.dmMono(
                                  color: const Color(0xFF8F2D2D),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: controller.isBusy ? null : onSubmit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _HotTakePalette.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: controller.isBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isLogin
                                          ? 'sign in'
                                          : 'create account',
                                      style: GoogleFonts.dmMono(),
                                    ),
                            ),
                          ),
                          if (isLogin) ...[
                            const SizedBox(height: 10),
                            Center(
                              child: GestureDetector(
                                onTap: onForgotPassword,
                                child: Text(
                                  'forgot password?',
                                  style: GoogleFonts.dmMono(
                                    color: _HotTakePalette.muted,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      backgroundColor: _HotTakePalette.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onBack,
                child: Text(
                  '← back to sign in',
                  style: GoogleFonts.dmMono(
                    color: _HotTakePalette.muted,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'forgot password',
                style: GoogleFonts.dmMono(
                  fontSize: 28,
                  color: _HotTakePalette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "enter your email and we'll send a reset link.",
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  color: _HotTakePalette.muted,
                ),
              ),
              const SizedBox(height: 24),
              _LabeledField(
                label: 'EMAIL',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: () {},
                validator: (_) => null,
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: GoogleFonts.dmMono(
                    color: const Color(0xFF8F2D2D),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSending ? null : onSend,
                  style: FilledButton.styleFrom(
                    backgroundColor: _HotTakePalette.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    isSending ? 'sending...' : 'send reset link',
                    style: GoogleFonts.dmMono(),
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

class _ForgotSentScreen extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _ForgotSentScreen({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HotTakePalette.page,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'check your email',
                style: GoogleFonts.dmMono(
                  fontSize: 28,
                  color: _HotTakePalette.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'if an account exists for $email, we sent a reset link. it expires in 1 hour.',
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  color: _HotTakePalette.muted,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onBack,
                child: Text(
                  '← back to sign in',
                  style: GoogleFonts.dmMono(
                    color: _HotTakePalette.muted,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
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
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF1EFE8),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmMono(
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
          style: GoogleFonts.dmMono(
            color: _HotTakePalette.muted,
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
          style: GoogleFonts.dmMono(color: _HotTakePalette.ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.dmMono(
              color: const Color(0xFFAAA49C),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _HotTakePalette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _HotTakePalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _HotTakePalette.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _HoverActionButton extends StatefulWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _HoverActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_HoverActionButton> createState() => _HoverActionButtonState();
}

class _HoverActionButtonState extends State<_HoverActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? const [
                    BoxShadow(
                      color: Color(0x3A4A1B0C),
                      blurRadius: 0,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.dmMono(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
