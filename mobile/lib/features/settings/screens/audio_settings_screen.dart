import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class AudioSettingsScreen extends ConsumerWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Audio Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Microphone Gain',
              style: Theme.of(context).textTheme.titleSmall),
          Slider(
            value: settings.micGain,
            onChanged: notifier.setMicGain,
            divisions: 20,
            label: '${(settings.micGain * 100).round()}%',
          ),
          const SizedBox(height: 16),
          Text('Speaker Volume',
              style: Theme.of(context).textTheme.titleSmall),
          Slider(
            value: settings.speakerGain,
            onChanged: notifier.setSpeakerGain,
            divisions: 20,
            label: '${(settings.speakerGain * 100).round()}%',
          ),
          const Divider(height: 32),
          SwitchListTile(
            title: const Text('VOX (Voice Activated)'),
            subtitle: const Text(
              'Auto-transmit when you speak',
            ),
            value: settings.voxEnabled,
            onChanged: notifier.setVoxEnabled,
          ),
          if (settings.voxEnabled) ...[
            const SizedBox(height: 8),
            Text('VOX Sensitivity',
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: settings.voxThreshold,
              onChanged: notifier.setVoxThreshold,
              min: 0.05,
              max: 0.8,
              divisions: 15,
              label: '${(settings.voxThreshold * 100).round()}%',
            ),
            Text(
              'Lower = more sensitive (picks up quieter sounds)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
