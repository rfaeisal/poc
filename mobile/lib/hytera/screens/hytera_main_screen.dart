import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/hardware_key_service.dart';
import '../services/kiosk_service.dart';
import '../widgets/hytera_navbar.dart';

class HyteraMainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const HyteraMainScreen({super.key, required this.child});

  @override
  ConsumerState<HyteraMainScreen> createState() => _HyteraMainScreenState();
}

class _HyteraMainScreenState extends ConsumerState<HyteraMainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const _routes = ['/channel', '/pesan', '/pengaturan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initKiosk();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initKiosk() async {
    await KioskService.enableKiosk();
    await KioskService.pinApp();
    await KioskService.showOnLockScreen();
    await KioskService.keepScreenOn();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      KioskService.enableKiosk();
    } else if (state == AppLifecycleState.paused) {
      ref.read(hardwareKeyProvider.notifier).resetPttState();
      KioskService.bringToFront();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        if (_currentIndex != i) setState(() => _currentIndex = i);
        break;
      }
    }
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: FocusScope(
          autofocus: true,
          child: Column(
            children: [
              Expanded(child: widget.child),
              HyteraNavbar(
                currentIndex: _currentIndex,
                onTap: _onTabTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
