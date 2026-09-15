import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/echo_test/providers/echo_test_provider.dart';
import '../../features/ptt/providers/ptt_provider.dart';
import 'ksun_echo_test_screen.dart';
import '../services/ksun_kiosk_service.dart';
import '../widgets/ksun_navbar.dart';

class KsunMainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const KsunMainScreen({super.key, required this.child});

  @override
  ConsumerState<KsunMainScreen> createState() => _KsunMainScreenState();
}

class _KsunMainScreenState extends ConsumerState<KsunMainScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const _routes = ['/channel', '/pengaturan'];

  static const _pttNativeChannel = MethodChannel('com.fakhriez.poc_ptx/ptt_native');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _setupNativePttChannel();
  }

  @override
  void dispose() {
    _pttNativeChannel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setupNativePttChannel() {
    _pttNativeChannel.invokeMethod('setPttKeyCode', {'keyCode': 261});
    _pttNativeChannel.setMethodCallHandler((call) async {
      final onEchoTest = KsunEchoTestScreen.isActive;

      if (call.method == 'pttDown') {
        if (onEchoTest) {
          ref.read(echoTestProvider.notifier).startTransmit();
        } else {
          if (_currentIndex != 0) _onTabTap(0);
          ref.read(pttProvider.notifier).startTransmit();
        }
      } else if (call.method == 'pttUp') {
        if (onEchoTest) {
          ref.read(echoTestProvider.notifier).stopTransmit();
        } else {
          ref.read(pttProvider.notifier).stopTransmit();
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      KsunKioskService.bringToFront();
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft && _currentIndex > 0) {
      _onTabTap(_currentIndex - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight &&
        _currentIndex < _routes.length - 1) {
      _onTabTap(_currentIndex + 1);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onTabTap(0);
        } else {
          KsunKioskService.exitApp();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: FocusScope(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            children: [
              Expanded(child: widget.child),
              KsunNavbar(
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
