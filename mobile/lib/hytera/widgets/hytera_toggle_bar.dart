import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/settings_provider.dart';

class HyteraToggleBar extends ConsumerWidget {
  const HyteraToggleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final bool voxOn = settings.voxEnabled;
    final bool btOn = settings.bluetoothDeviceName != null;
    const bool encOn = false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleChip(
          label: 'VOX',
          isOn: voxOn,
          onTap: () => notifier.setVoxEnabled(!voxOn),
        ),
        const SizedBox(width: 5),
        _ToggleChip(
          label: 'BT',
          isOn: btOn,
          onTap: null,
        ),
        const SizedBox(width: 5),
        _ToggleChip(
          label: 'ENC',
          isOn: encOn,
          onTap: null,
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isOn;
  final VoidCallback? onTap;

  const _ToggleChip({
    required this.label,
    required this.isOn,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(
            color: isOn
                ? const Color(0xFF1E5A2A)
                : const Color(0xFF1E2A3A),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 7,
            color: isOn
                ? const Color(0xFF4ADE80)
                : const Color(0xFF4A6A8A),
          ),
        ),
      ),
    );
  }
}
