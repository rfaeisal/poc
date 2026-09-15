import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/permission_service.dart';
import '../../features/auth/providers/auth_provider.dart';

class KsunLoginScreen extends ConsumerStatefulWidget {
  const KsunLoginScreen({super.key});

  @override
  ConsumerState<KsunLoginScreen> createState() =>
      _KsunLoginScreenState();
}

class _KsunLoginScreenState extends ConsumerState<KsunLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'itikomsmart@gmail.com');
  final _passwordController = TextEditingController(text: 'test1234');
  final _emailFocus = FocusNode(debugLabel: 'email');
  final _passwordFocus = FocusNode(debugLabel: 'password');
  final _buttonFocus = FocusNode(debugLabel: 'masuk');
  final _settingsFocus = FocusNode(debugLabel: 'settings');
  bool _obscurePassword = true;
  bool _checkingAutoLogin = true;

  @override
  void initState() {
    super.initState();
    PermissionService.requestMicrophone();
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
    _settingsFocus.dispose();
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
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFF4ADE80),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {},
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
              } else if (_buttonFocus.hasFocus) {
                _settingsFocus.requestFocus();
              }
            } else if (key == LogicalKeyboardKey.arrowUp) {
              if (_settingsFocus.hasFocus) {
                _buttonFocus.requestFocus();
              } else if (_buttonFocus.hasFocus) {
                _passwordFocus.requestFocus();
              } else if (_passwordFocus.hasFocus) {
                _emailFocus.requestFocus();
              }
            } else if ((key == LogicalKeyboardKey.select ||
                    key == LogicalKeyboardKey.enter ||
                    key == LogicalKeyboardKey.numpadEnter ||
                    key == LogicalKeyboardKey.gameButtonA)) {
              if (_buttonFocus.hasFocus) {
                _login();
              } else if (_settingsFocus.hasFocus) {
                const MethodChannel('com.fakhriez.poc_ptx/kiosk')
                    .invokeMethod('openAndroidSettings');
              }
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        'POC\nSMART',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE2E8F0),
                          letterSpacing: 1,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 5,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            autofocus: true,
                            style: _inputTextStyle,
                            decoration: _inputDecoration('Email'),
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
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            style: _inputTextStyle,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: _inputDecoration('Password'),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Password wajib diisi'
                                : null,
                          ),
                          if (auth.error != null) ...[
                            const SizedBox(height: 2),
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
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: _MasukButton(
                              focusNode: _buttonFocus,
                              isLoading: auth.isLoading,
                              onPressed: _login,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Focus(
                            focusNode: _settingsFocus,
                            child: Builder(
                              builder: (context) {
                                final focused = Focus.of(context).hasFocus;
                                return GestureDetector(
                                  onTap: () {
                                    const MethodChannel('com.fakhriez.poc_ptx/kiosk')
                                        .invokeMethod('openAndroidSettings');
                                  },
                                  child: Text(
                                    'Setting',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 7,
                                      color: focused
                                          ? const Color(0xFF4A9EFF)
                                          : const Color(0xFF4A6A8A),
                                      decoration: TextDecoration.underline,
                                      decorationColor: focused
                                          ? const Color(0xFF4A9EFF)
                                          : const Color(0xFF4A6A8A),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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

  TextStyle get _inputTextStyle => const TextStyle(
        fontFamily: 'monospace',
        fontSize: 8,
        color: Color(0xFFE2E8F0),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 7,
          color: Color(0xFF4A6A8A),
        ),
        filled: true,
        fillColor: const Color(0xFF0F1E2E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFF1E2A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFF1E2A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: const BorderSide(color: Color(0xFF4A9EFF), width: 2),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 7,
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
        padding: const EdgeInsets.symmetric(vertical: 3),
        minimumSize: const Size(double.infinity, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: _focused
              ? const BorderSide(color: Color(0xFF4ADE80), width: 2)
              : BorderSide.none,
        ),
        elevation: 0,
      ),
      child: widget.isLoading
          ? const SizedBox(
              height: 10,
              width: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF4A9EFF),
              ),
            )
          : const Text(
              'MASUK',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
    );
  }
}
