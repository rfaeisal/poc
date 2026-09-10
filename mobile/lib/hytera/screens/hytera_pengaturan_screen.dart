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
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: const Text(
            'PENGATURAN',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Color(0xFF4A9EFF),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // DIAGNOSTIK
        _SectionHeader(title: 'DIAGNOSTIK'),
        _SettingItem(
          icon: Icons.surround_sound,
          name: 'Echo Test',
          description: 'Test mic & speaker, ukur latency',
          trailing: const Icon(
            Icons.chevron_right,
            size: 14,
            color: Color(0xFF4A6A8A),
          ),
          onTap: () => context.go('/echo-test'),
        ),

        // AUDIO
        _SectionHeader(title: 'AUDIO'),
        _SettingItem(
          icon: Icons.volume_up,
          name: 'RX Gain',
          description: 'Volume suara masuk',
          trailing: Text(
            _gainLabel(settings.speakerGain),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: Color(0xFF4A9EFF),
            ),
          ),
        ),
        _SliderRow(
          value: settings.speakerGain,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setSpeakerGain(v),
          minLabel: '-10 dB',
          maxLabel: '+10 dB',
        ),
        _SettingItem(
          icon: Icons.mic,
          name: 'TX Gain',
          description: 'Volume mikrofon',
          trailing: Text(
            _gainLabel(settings.micGain),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: Color(0xFF4A9EFF),
            ),
          ),
        ),
        _SliderRow(
          value: settings.micGain,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setMicGain(v),
          minLabel: '-10 dB',
          maxLabel: '+10 dB',
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
            'Ketuk badge → tekan tombol fisik untuk set. Tahan lama badge untuk hapus.',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 6.5,
              color: Color(0xFF2A4A6A),
              height: 1.4,
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
        _ToggleItem(
          icon: Icons.graphic_eq,
          name: 'VOX',
          description: 'Transmit otomatis oleh suara',
          value: settings.voxEnabled,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setVoxEnabled(v),
        ),

        // LOKASI
        _SectionHeader(title: 'LOKASI'),
        _ToggleItem(
          icon: Icons.location_on,
          name: 'Share Location',
          description: 'Tampilkan posisi di peta',
          value: settings.locationSharing,
          onChanged: (v) =>
              ref.read(settingsProvider.notifier).setLocationSharing(v),
        ),

        // BLUETOOTH
        _SectionHeader(title: 'BLUETOOTH'),
        _SettingItem(
          icon: Icons.bluetooth,
          name: 'Bluetooth PTT',
          description: settings.bluetoothDeviceName ?? 'Tidak terhubung',
          trailing: settings.bluetoothDeviceName != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
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
                        fontSize: 8,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                  ],
                )
              : null,
        ),

        // AKUN
        _SectionHeader(title: 'AKUN'),
        _SettingItem(
          icon: Icons.grid_view,
          name: 'Device Info',
          description: 'Diagnostics & debug info',
        ),
        _SettingItem(
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
        _SettingItem(
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
                'POC-PTX $version',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
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
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE2E8F0),
          ),
        ),
        content: const Text(
          'Aplikasi akan ditutup sepenuhnya. PTT tidak akan aktif sampai aplikasi dibuka kembali.',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: Color(0xFF94A3B8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'BATAL',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
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
                fontSize: 9,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _gainLabel(double value) {
    final db = (value * 20 - 10).round();
    return '${db >= 0 ? "+" : ""}$db dB';
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
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingItem({
    required this.icon,
    required this.name,
    required this.description,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF0A1020)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDestructive
                    ? const Color(0xFF1A0808)
                    : const Color(0xFF0F1E2E),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                size: 11,
                color: isDestructive
                    ? const Color(0xFFF87171)
                    : const Color(0xFF4A9EFF),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? const Color(0xFFF87171)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 7,
                      color: Color(0xFF2A4A6A),
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.icon,
    required this.name,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF0A1020)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E2E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 11, color: const Color(0xFF4A9EFF)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
                    color: Color(0xFF2A4A6A),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 22,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: value
                    ? const Color(0xFF0F6E56)
                    : const Color(0xFF0F2040),
                border: Border.all(
                  color: value
                      ? const Color(0xFF1D9E75)
                      : const Color(0xFF1E3A5F),
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF2A4A6A),
                  ),
                ),
              ),
            ),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF0A1020)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E2E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(widget.icon, size: 11, color: const Color(0xFF4A9EFF)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
                    color: Color(0xFF2A4A6A),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _listening ? null : _startListening,
            onLongPress: hasBinding ? _clearBinding : null,
            child: Container(
              constraints: const BoxConstraints(minWidth: 40),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _listening
                      ? const Color(0xFFFBBF24)
                      : hasBinding
                          ? const Color(0xFF4A9EFF)
                          : const Color(0xFF2A4A6A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String minLabel;
  final String maxLabel;

  const _SliderRow({
    required this.value,
    required this.onChanged,
    required this.minLabel,
    required this.maxLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: const BoxDecoration(
        color: Color(0xFF060C18),
        border: Border(
          bottom: BorderSide(color: Color(0xFF0A1020)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  color: Color(0xFF2A4A6A),
                ),
              ),
              Text(
                maxLabel,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
                  color: Color(0xFF4A9EFF),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF4A9EFF),
              inactiveTrackColor: const Color(0xFF0F2040),
              thumbColor: const Color(0xFF4A9EFF),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 2,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

