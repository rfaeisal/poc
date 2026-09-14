import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ptt/providers/ptt_provider.dart';
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

  static const _routes = ['/channel', '/pengaturan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initKiosk();
    _setupHardwareKeys();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_globalKeyHandler);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setupHardwareKeys() {
    final notifier = ref.read(hardwareKeyProvider.notifier);
    notifier.onPttDown = () {
      if (_currentIndex != 0) {
        _onTabTap(0);
      }
      ref.read(pttProvider.notifier).startTransmit();
    };
    notifier.onPttUp = () {
      ref.read(pttProvider.notifier).stopTransmit();
    };
    HardwareKeyboard.instance.addHandler(_globalKeyHandler);
  }

  bool _globalKeyHandler(KeyEvent event) {
    return ref.read(hardwareKeyProvider.notifier).handleKeyEvent(event);
  }

  Future<void> _initKiosk() async {
    await KioskService.enableKiosk();
    await KioskService.pinApp();
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

    if ((key == LogicalKeyboardKey.goBack ||
            key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.browserBack) &&
        _currentIndex != 0) {
      _onTabTap(0);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) KioskService.exitApp();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: FocusScope(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
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
