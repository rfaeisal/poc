import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';

class HyteraSplashScreen extends ConsumerStatefulWidget {
  const HyteraSplashScreen({super.key});

  @override
  ConsumerState<HyteraSplashScreen> createState() =>
      _HyteraSplashScreenState();
}

class _HyteraSplashScreenState extends ConsumerState<HyteraSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await ref.read(authProvider.notifier).tryAutoLogin();
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.isAuthenticated) {
      context.go('/channel');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0F1E2E),
                border: Border.all(
                  color: const Color(0xFF1E4A8A),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.cell_tower,
                size: 20,
                color: Color(0xFF4A9EFF),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'POC-PTX',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE2E8F0),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'DIGITAL HT NETWORK',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 7.5,
                color: Color(0xFF4A6A8A),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF4A9EFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
