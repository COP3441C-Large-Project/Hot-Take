import 'package:flutter/material.dart';

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

  AuthMode _mode = AuthMode.login;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setMode(AuthMode mode) {
    if (_mode == mode) {
      return;
    }

    setState(() {
      _mode = mode;
    });
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return Scaffold(
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(
                    flex: 38,
                    child: _BrandPanel(
                      compact: false,
                      onSignIn: () => _setMode(AuthMode.login),
                    ),
                  ),
                  Expanded(
                    flex: 62,
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
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 360,
                      width: double.infinity,
                      child: _BrandPanel(
                        compact: true,
                        onSignIn: () => _setMode(AuthMode.login),
                      ),
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
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

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
            child: _AccentCircle(size: compact ? 120 : 170, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: _AccentCircle(size: compact ? 180 : 240, color: Colors.black.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(horizontalPadding, compact ? 28 : 42, horizontalPadding, compact ? 20 : 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      color: const Color(0xFFF7F5F2),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLogin ? 'sign in' : 'create account',
                style: const TextStyle(
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1714),
                ),
              ),
              const SizedBox(height: 18),
              _ModeTabs(
                mode: mode,
                onModeChanged: onModeChanged,
              ),
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
                        hintText: 'your handle',
                        textInputAction: TextInputAction.next,
                        onChanged: () => controller.clearError(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    _LabeledField(
                      label: 'EMAIL',
                      controller: emailController,
                      hintText: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: isLogin ? TextInputAction.next : TextInputAction.next,
                      onChanged: () => controller.clearError(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'PASSWORD',
                      controller: passwordController,
                      obscureText: true,
                      textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
                      onChanged: () => controller.clearError(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required.';
                        }
                        return null;
                      },
                    ),
                    if (!isLogin) ...[
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'CONFIRM PASSWORD',
                        controller: confirmPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onChanged: () => controller.clearError(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password.';
                          }

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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        onPressed: controller.isBusy ? null : onSubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE24B4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: controller.isBusy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : Text(isLogin ? 'sign in' : 'create account'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'your identity is never shared with matches',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
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

  const _TabButton({required this.label, required this.selected, required this.onTap});

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
            color: selected ? const Color(0xFF1A1714) : const Color(0xFF888780),
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
