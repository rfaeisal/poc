import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../services/ksun_kiosk_service.dart';

class KsunPengaturanScreen extends ConsumerWidget {
  const KsunPengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      children: [
        Container(
          color: const Color(0xFF060C18),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: const Text(
            'PENGATURAN',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: Color(0xFF4A9EFF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        _SectionHeader(title: 'DIAGNOSTIK'),
        _FocusableSettingItem(
          icon: Icons.surround_sound,
          name: 'Echo Test',
          description: 'Test mic & speaker',
          trailing: const Icon(
            Icons.chevron_right,
            size: 10,
            color: Color(0xFF4A6A8A),
          ),
          onTap: () => context.push('/echo-test'),
        ),

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

        _SectionHeader(title: 'VOX'),
        _FocusableToggleItem(
          icon: Icons.graphic_eq,
          name: 'VOX',
          description: 'Transmit otomatis',
          value: settings.voxEnabled,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setVoxEnabled(v),
        ),

        _SectionHeader(title: 'LOKASI'),
        _FocusableToggleItem(
          icon: Icons.location_on,
          name: 'Lokasi',
          description: 'Share posisi di peta',
          value: settings.locationSharing,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setLocationSharing(v),
        ),

        _SectionHeader(title: 'AKUN'),
        _FocusableSettingItem(
          icon: Icons.logout,
          name: 'Logout',
          description:
              'Keluar ${ref.watch(authProvider).user?.profile.callsign ?? ""}',
          isDestructive: true,
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),

        const SizedBox(height: 4),
        _SectionHeader(title: 'SISTEM'),
        _FocusableSettingItem(
          icon: Icons.settings,
          name: 'Android Settings',
          description: 'WiFi, Bluetooth, dll',
          trailing: const Icon(
            Icons.chevron_right,
            size: 10,
            color: Color(0xFF4A6A8A),
          ),
          onTap: () => _openAndroidSettings(),
        ),

        const SizedBox(height: 4),
        _SectionHeader(title: 'APLIKASI'),
        _FocusableSettingItem(
          icon: Icons.exit_to_app,
          name: 'Keluar',
          description: 'Tutup aplikasi',
          isDestructive: true,
          onTap: () => _confirmExit(context),
        ),

        const SizedBox(height: 6),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final info = snapshot.data;
            final version = info != null
                ? 'v${info.version}+${info.buildNumber}'
                : '...';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Text(
                'POC-SMART $version',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _openAndroidSettings() {
    const platform = MethodChannel('com.fakhriez.poc_ptx/kiosk');
    platform.invokeMethod('openAndroidSettings');
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1E2E),
        title: const Text(
          'KELUAR',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE2E8F0),
          ),
        ),
        content: const Text(
          'Tutup aplikasi?',
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
                fontSize: 7,
                color: Color(0xFF4A9EFF),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              KsunKioskService.exitApp();
            },
            child: const Text(
              'KELUAR',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 7,
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFF0F1E2E) : Colors.transparent,
            border: Border(
              bottom: const BorderSide(color: Color(0xFF0A1020)),
              left: _focused
                  ? const BorderSide(color: Color(0xFF4A9EFF), width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: widget.isDestructive
                      ? const Color(0xFF1A0808)
                      : const Color(0xFF0F1E2E),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(
                  widget.icon,
                  size: 8,
                  color: widget.isDestructive
                      ? const Color(0xFFF87171)
                      : const Color(0xFF4A9EFF),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
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
                        fontSize: 9,
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: _focused ? const Color(0xFF0F1E2E) : Colors.transparent,
            border: Border(
              bottom: const BorderSide(color: Color(0xFF0A1020)),
              left: _focused
                  ? const BorderSide(color: Color(0xFF4A9EFF), width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E2E),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(widget.icon, size: 8,
                    color: const Color(0xFF4A9EFF)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
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
                        fontSize: 9,
                        color: Color(0xFF2A4A6A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 16,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
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
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: _focused ? const Color(0xFF0F1E2E) : Colors.transparent,
          border: Border(
            bottom: const BorderSide(color: Color(0xFF0A1020)),
            left: _focused
                ? const BorderSide(color: Color(0xFF4A9EFF), width: 2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E2E),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(widget.icon, size: 8,
                  color: const Color(0xFF4A9EFF)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
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
