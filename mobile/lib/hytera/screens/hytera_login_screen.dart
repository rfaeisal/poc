import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../services/kiosk_service.dart';

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
  final _emailFocus = FocusNode(debugLabel: 'email');
  final _passwordFocus = FocusNode(debugLabel: 'password');
  final _buttonFocus = FocusNode(debugLabel: 'masuk');
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emailFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _buttonFocus.dispose();
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
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4ADE80),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) KioskService.exitApp();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: KeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKeyEvent: (event) {
            if (event is! KeyDownEvent) return;
            final key = event.logicalKey;

            if (key == LogicalKeyboardKey.arrowDown) {
              if (_emailFocus.hasFocus) {
                _passwordFocus.requestFocus();
              } else if (_passwordFocus.hasFocus) {
                _buttonFocus.requestFocus();
              }
            } else if (key == LogicalKeyboardKey.arrowUp) {
              if (_buttonFocus.hasFocus) {
                _passwordFocus.requestFocus();
              } else if (_passwordFocus.hasFocus) {
                _emailFocus.requestFocus();
              }
            } else if (_buttonFocus.hasFocus &&
                (key == LogicalKeyboardKey.select ||
                    key == LogicalKeyboardKey.enter ||
                    key == LogicalKeyboardKey.numpadEnter ||
                    key == LogicalKeyboardKey.gameButtonA)) {
              _login();
            }
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo_poc_smart.jpeg',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'POC-SMART',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE2E8F0),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'DIGITAL HT NETWORK',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: Color(0xFF4A9EFF),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('EMAIL'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        autofocus: true,
                        style: _inputTextStyle,
                        decoration: _inputDecoration('callsign@poc-smart.id'),
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            _passwordFocus.requestFocus(),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Email wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      _buildLabel('PASSWORD'),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        style: _inputTextStyle,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: _inputDecoration('••••••••').copyWith(
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 18,
                              color: const Color(0xFF4A6A8A),
                            ),
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 24,
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Password wajib diisi'
                            : null,
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          auth.error!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9,
                            color: Color(0xFFF87171),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: _MasukButton(
                          focusNode: _buttonFocus,
                          isLoading: auth.isLoading,
                          onPressed: _login,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'POC-SMART v1.0.0',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 7,
                          color: Color(0xFF2A4A6A),
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
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: Color(0xFF4A6A8A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TextStyle get _inputTextStyle => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 11,
        color: Color(0xFFE2E8F0),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          color: Color(0xFF4A6A8A),
        ),
        filled: true,
        fillColor: const Color(0xFF0F1E2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
          borderSide: const BorderSide(color: Color(0xFF4A9EFF), width: 2),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 8,
          color: Color(0xFFF87171),
        ),
      );
}

class _MasukButton extends StatefulWidget {
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onPressed;

  const _MasukButton({
    required this.focusNode,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_MasukButton> createState() => _MasukButtonState();
}

class _MasukButtonState extends State<_MasukButton> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      focusNode: widget.focusNode,
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _focused ? const Color(0xFF238B4A) : const Color(0xFF1B6B3A),
        foregroundColor: const Color(0xFFE2E8F0),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: _focused
              ? const BorderSide(color: Color(0xFF4ADE80), width: 2)
              : BorderSide.none,
        ),
        elevation: 0,
      ),
      child: widget.isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4A9EFF),
              ),
            )
          : const Text(
              'MASUK',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
    );
  }
}
