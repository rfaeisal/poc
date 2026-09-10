import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/auth/providers/auth_provider.dart';

class HyteraLoginScreen extends ConsumerStatefulWidget {
  const HyteraLoginScreen({super.key});

  @override
  ConsumerState<HyteraLoginScreen> createState() =>
      _HyteraLoginScreenState();
}

class _HyteraLoginScreenState extends ConsumerState<HyteraLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _checkingAutoLogin = true;

  @override
  void initState() {
    super.initState();
    Permission.microphone.request();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await ref.read(authProvider.notifier).tryAutoLogin();
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      context.go('/channel');
    } else {
      setState(() => _checkingAutoLogin = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      context.go('/channel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (_checkingAutoLogin) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F1A),
        body: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4ADE80),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo_poc_smart.jpeg',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'POC-SMART',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE2E8F0),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'DIGITAL HT NETWORK',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7.5,
                      color: Color(0xFF4A9EFF),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildLabel('EMAIL'),
                  const SizedBox(height: 3),
                  TextFormField(
                    controller: _emailController,
                    style: _inputTextStyle,
                    decoration: _inputDecoration('callsign@poc-smart.id'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 8),
                  _buildLabel('PASSWORD'),
                  const SizedBox(height: 3),
                  TextFormField(
                    controller: _passwordController,
                    style: _inputTextStyle,
                    decoration: _inputDecoration('••••••••').copyWith(
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 14,
                          color: const Color(0xFF4A6A8A),
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 20,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password wajib diisi' : null,
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      auth.error!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: Color(0xFFF87171),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6B3A),
                        foregroundColor: const Color(0xFFE2E8F0),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 12,
                              width: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF4A9EFF),
                              ),
                            )
                          : const Text(
                              'MASUK',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'POC-SMART v1.0.0 · TLS 1.3',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 6.5,
                      color: Color(0xFF2A4A6A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 7,
          color: Color(0xFF4A6A8A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TextStyle get _inputTextStyle => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 9,
        color: Color(0xFFE2E8F0),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: Color(0xFF4A6A8A),
        ),
        filled: true,
        fillColor: const Color(0xFF0F1E2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF1E2A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF1E2A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF4A9EFF)),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 7,
          color: Color(0xFFF87171),
        ),
      );
}
