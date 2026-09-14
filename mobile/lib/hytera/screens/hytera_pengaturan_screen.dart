import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../services/hardware_key_service.dart';
import '../services/kiosk_service.dart';

class HyteraPengaturanScreen extends ConsumerWidget {
  const HyteraPengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      children: [
        // Header
        Container(
          color: const Color(0xFF060C18),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: const Text(
            'PENGATURAN',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Color(0xFF4A9EFF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        // DIAGNOSTIK
        _SectionHeader(title: 'DIAGNOSTIK'),
        _FocusableSettingItem(
          icon: Icons.surround_sound,
          name: 'Echo Test',
          description: 'Test mic & speaker, ukur latency',
          trailing: const Icon(
            Icons.chevron_right,
            size: 18,
            color: Color(0xFF4A6A8A),
          ),
          onTap: () => context.push('/echo-test'),
        ),

        // AUDIO
        _SectionHeader(title: 'AUDIO'),
        _FocusableGainItem(
          icon: Icons.volume_up,
          name: 'RX Gain',
          value: settings.speakerGain,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setSpeakerGain(v),
        ),
        _FocusableGainItem(
          icon: Icons.mic,
          name: 'TX Gain',
          value: settings.micGain,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setMicGain(v),
        ),

        // MAPPING TOMBOL FISIK
        _SectionHeader(title: 'MAPPING TOMBOL FISIK'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: const BoxDecoration(
            color: Color(0xFF060C18),
            border: Border(
              bottom: BorderSide(color: Color(0xFF0A1020)),
            ),
          ),
          child: const Text(
            'Ketuk → tekan tombol fisik. Tahan untuk hapus.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 6,
              color: Color(0xFF2A4A6A),
            ),
          ),
        ),
        _KeyMappingItem(
          icon: Icons.mic,
          name: 'Tombol PTT',
          description: 'Tahan untuk transmit',
          action: KeyAction.ptt,
        ),
        _KeyMappingItem(
          icon: Icons.keyboard_arrow_up,
          name: 'Channel Naik',
          description: 'Channel berikutnya',
          action: KeyAction.channelUp,
        ),
        _KeyMappingItem(
          icon: Icons.keyboard_arrow_down,
          name: 'Channel Turun',
          description: 'Channel sebelumnya',
          action: KeyAction.channelDown,
        ),

        // VOX
        _SectionHeader(title: 'VOX'),
        _FocusableToggleItem(
          icon: Icons.graphic_eq,
          name: 'VOX',
          description: 'Transmit otomatis oleh suara',
          value: settings.voxEnabled,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setVoxEnabled(v),
        ),

        // LOKASI
        _SectionHeader(title: 'LOKASI'),
        _FocusableToggleItem(
          icon: Icons.location_on,
          name: 'Share Location',
          description: 'Tampilkan posisi di peta',
          value: settings.locationSharing,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setLocationSharing(v),
        ),

        // BLUETOOTH
        _SectionHeader(title: 'BLUETOOTH'),
        _FocusableSettingItem(
          icon: Icons.bluetooth,
          name: 'Bluetooth PTT',
          description: settings.bluetoothDeviceName ?? 'Tidak terhubung',
          trailing: settings.bluetoothDeviceName != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Terhubung',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                )
              : null,
        ),

        // AKUN
        _SectionHeader(title: 'AKUN'),
        _FocusableSettingItem(
          icon: Icons.grid_view,
          name: 'Device Info',
          description: 'Diagnostics & debug info',
        ),
        _FocusableSettingItem(
          icon: Icons.logout,
          name: 'Logout',
          description:
              'Keluar dari ${ref.watch(authProvider).user?.profile.callsign ?? ""}',
          isDestructive: true,
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),

        const SizedBox(height: 8),
        _SectionHeader(title: 'APLIKASI'),
        _FocusableSettingItem(
          icon: Icons.exit_to_app,
          name: 'Keluar Aplikasi',
          description: 'Tutup aplikasi sepenuhnya',
          isDestructive: true,
          onTap: () => _confirmExit(context),
        ),

        const SizedBox(height: 12),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final info = snapshot.data;
            final version = info != null
                ? 'v${info.version} build ${info.buildNumber}'
                : '...';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              child: Text(
                'POC-SMART $version',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 6,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E2E),
        title: const Text(
          'KELUAR APLIKASI',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE2E8F0),
          ),
        ),
        content: const Text(
          'Aplikasi akan ditutup. PTT tidak aktif sampai dibuka kembali.',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 7,
            color: Color(0xFF94A3B8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'BATAL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: Color(0xFF4A9EFF),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              KioskService.exitApp();
            },
            child: const Text(
              'KELUAR',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF060910),
        border: Border(
          bottom: BorderSide(color: Color(0xFF0A1020)),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 7,
          color: Color(0xFF2A4A6A),
        ),
      ),
    );
  }
}

class _FocusableSettingItem extends StatefulWidget {
  final IconData icon;
  final String name;
  final String description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _FocusableSettingItem({
    required this.icon,
    required this.name,
    required this.description,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_FocusableSettingItem> createState() => _FocusableSettingItemState();
}

class _FocusableSettingItemState extends State<_FocusableSettingItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            widget.onTap != null &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onTap!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFF0F1E2E) : Colors.transparent,
            border: Border(
              bottom: const BorderSide(color: Color(0xFF0A1020)),
              left: _focused
                  ? const BorderSide(color: Color(0xFF4A9EFF), width: 3)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isDestructive
                      ? const Color(0xFF1A0808)
                      : const Color(0xFF0F1E2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isDestructive
                      ? const Color(0xFFF87171)
                      : const Color(0xFF4A9EFF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _focused
                            ? const Color(0xFFDBE4F0)
                            : widget.isDestructive
                                ? const Color(0xFFF87171)
                                : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 6,
                        color: Color(0xFF2A4A6A),
                      ),
                    ),
                  ],
                ),
              ),
              ?widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusableToggleItem extends StatefulWidget {
  final IconData icon;
  final String name;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FocusableToggleItem({
    required this.icon,
    required this.name,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_FocusableToggleItem> createState() => _FocusableToggleItemState();
}

class _FocusableToggleItemState extends State<_FocusableToggleItem> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onChanged(!widget.value);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFF0F1E2E) : Colors.transparent,
            border: Border(
              bottom: const BorderSide(color: Color(0xFF0A1020)),
              left: _focused
                  ? const BorderSide(color: Color(0xFF4A9EFF), width: 3)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(widget.icon, size: 14,
                    color: const Color(0xFF4A9EFF)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _focused
                            ? const Color(0xFFDBE4F0)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 6,
                        color: Color(0xFF2A4A6A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: widget.value
                      ? const Color(0xFF0F6E56)
                      : const Color(0xFF0F2040),
                  border: Border.all(
                    color: widget.value
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF1E3A5F),
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: widget.value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.value
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF2A4A6A),
                    ),
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

class _KeyMappingItem extends ConsumerStatefulWidget {
  final IconData icon;
  final String name;
  final String description;
  final KeyAction action;

  const _KeyMappingItem({
    required this.icon,
    required this.name,
    required this.description,
    required this.action,
  });

  @override
  ConsumerState<_KeyMappingItem> createState() => _KeyMappingItemState();
}

class _KeyMappingItemState extends ConsumerState<_KeyMappingItem> {
  bool _listening = false;
  bool _focused = false;
  Timer? _listenTimer;

  void _startListening() {
    setState(() => _listening = true);
    HardwareKeyboard.instance.addHandler(_handleKey);
    _listenTimer?.cancel();
    _listenTimer = Timer(const Duration(seconds: 5), _cancelListening);
  }

  void _cancelListening() {
    if (!_listening) return;
    setState(() => _listening = false);
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _listenTimer?.cancel();
    _listenTimer = null;
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent && _listening) {
      ref
          .read(hardwareKeyProvider.notifier)
          .saveBinding(widget.action, event.logicalKey);
      _listenTimer?.cancel();
      _listenTimer = null;
      setState(() => _listening = false);
      HardwareKeyboard.instance.removeHandler(_handleKey);
      return true;
    }
    return false;
  }

  void _clearBinding() {
    ref.read(hardwareKeyProvider.notifier).clearBinding(widget.action);
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    if (_listening) {
      HardwareKeyboard.instance.removeHandler(_handleKey);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bindings = ref.watch(hardwareKeyProvider);
    final label = bindings.labelFor(widget.action);
    final hasBinding = bindings.keyFor(widget.action) != null;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            !_listening &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          _startListening();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _listening ? null : _startListening,
        onLongPress: hasBinding ? _clearBinding : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFF0F1E2E) : Colors.transparent,
            border: Border(
              bottom: const BorderSide(color: Color(0xFF0A1020)),
              left: _focused
                  ? const BorderSide(color: Color(0xFF4A9EFF), width: 3)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(widget.icon, size: 14,
                    color: const Color(0xFF4A9EFF)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _focused
                            ? const Color(0xFFDBE4F0)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 6,
                        color: Color(0xFF2A4A6A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _listening
                      ? const Color(0xFF1A1500)
                      : const Color(0xFF0F1E2E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _listening
                        ? const Color(0xFFFBBF24)
                        : hasBinding
                            ? const Color(0xFF1E4A8A)
                            : const Color(0xFF1E3A5F),
                  ),
                ),
                child: Text(
                  _listening
                      ? 'TEKAN...'
                      : hasBinding
                          ? label
                          : '---',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: _listening
                        ? const Color(0xFFFBBF24)
                        : hasBinding
                            ? const Color(0xFF4A9EFF)
                            : const Color(0xFF2A4A6A),
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

class _FocusableGainItem extends StatefulWidget {
  final IconData icon;
  final String name;
  final double value;
  final ValueChanged<double> onChanged;

  const _FocusableGainItem({
    required this.icon,
    required this.name,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_FocusableGainItem> createState() => _FocusableGainItemState();
}

class _FocusableGainItemState extends State<_FocusableGainItem> {
  bool _focused = false;

  String get _label {
    final db = (widget.value * 20 - 10).round();
    return '${db >= 0 ? "+" : ""}$db dB';
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowRight) {
          final next = (widget.value + 0.05).clamp(0.0, 1.0);
          widget.onChanged(next);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft) {
          final next = (widget.value - 0.05).clamp(0.0, 1.0);
          widget.onChanged(next);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: _focused ? const Color(0xFF0F1E2E) : Colors.transparent,
          border: Border(
            bottom: const BorderSide(color: Color(0xFF0A1020)),
            left: _focused
                ? const BorderSide(color: Color(0xFF4A9EFF), width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E2E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(widget.icon, size: 14,
                  color: const Color(0xFF4A9EFF)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _focused
                      ? const Color(0xFFDBE4F0)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            Text(
              _focused ? '◄ $_label ►' : _label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 7,
                color: Color(0xFF4A9EFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
