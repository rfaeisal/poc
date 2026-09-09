import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/talk_timer.dart';
import '../providers/echo_test_provider.dart';

class EchoTestScreen extends ConsumerWidget {
  const EchoTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final echoState = ref.watch(echoTestProvider);
    final notifier = ref.read(echoTestProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Echo Test'),
        actions: [
          if (echoState.status == EchoTestStatus.ready ||
              echoState.status == EchoTestStatus.transmitting ||
              echoState.status == EchoTestStatus.playing)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Stop',
              onPressed: () => notifier.stop(),
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Idle / Error: show start button
              if (echoState.status == EchoTestStatus.idle ||
                  echoState.status == EchoTestStatus.error) ...[
                Icon(
                  Icons.surround_sound,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Echo Test',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Test mic & speaker.\nTekan PTT, bicara, lepas, dengar suara Anda kembali.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (echoState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    echoState.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => notifier.start(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Mulai Echo Test'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],

              // Connecting
              if (echoState.status == EchoTestStatus.connecting) ...[
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Menghubungkan...',
                  style: theme.textTheme.titleMedium,
                ),
              ],

              // Ready / Transmitting / Playing: show PTT button
              if (echoState.status == EchoTestStatus.ready ||
                  echoState.status == EchoTestStatus.transmitting ||
                  echoState.status == EchoTestStatus.playing) ...[
                // Latency — always reserve space
                Opacity(
                  opacity: echoState.latencyMs != null ? 1.0 : 0.0,
                  child: _LatencyDisplay(
                    currentMs: echoState.latencyMs,
                    averageMs: echoState.averageLatency,
                  ),
                ),
                const SizedBox(height: 24),
                _EchoPttButton(
                  isTransmitting:
                      echoState.status == EchoTestStatus.transmitting,
                  isPlaying: echoState.status == EchoTestStatus.playing,
                  onPttDown: () => notifier.startTransmit(),
                  onPttUp: () => notifier.stopTransmit(),
                ),
                const SizedBox(height: 12),
                // Duration area — always same height
                SizedBox(
                  height: 44,
                  child: echoState.status == EchoTestStatus.transmitting
                      ? TalkTimer(
                          isActive: true,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : (echoState.status == EchoTestStatus.playing ||
                              echoState.transmitDuration != null)
                          ? _DurationComparison(
                              transmitDuration: echoState.transmitDuration,
                              playbackDuration: echoState.playbackDuration,
                            )
                          : const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                Text(
                  echoState.status == EchoTestStatus.transmitting
                      ? 'Bicara sekarang...'
                      : echoState.status == EchoTestStatus.playing
                          ? 'Mendengarkan echo...'
                          : 'Tekan & tahan untuk bicara',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: echoState.status == EchoTestStatus.transmitting
                        ? Colors.green
                        : echoState.status == EchoTestStatus.playing
                            ? Colors.orange
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EchoPttButton extends StatelessWidget {
  final bool isTransmitting;
  final bool isPlaying;
  final VoidCallback onPttDown;
  final VoidCallback onPttUp;

  const _EchoPttButton({
    required this.isTransmitting,
    this.isPlaying = false,
    required this.onPttDown,
    required this.onPttUp,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    if (isTransmitting) {
      color = Colors.green;
      icon = Icons.mic;
    } else if (isPlaying) {
      color = Colors.orange;
      icon = Icons.volume_up;
    } else {
      color = Theme.of(context).colorScheme.primary;
      icon = Icons.mic_none;
    }
    const size = 120.0;
    final active = isTransmitting || isPlaying;

    return GestureDetector(
      onTapDown: isPlaying ? null : (_) => onPttDown(),
      onTapUp: isPlaying ? null : (_) => onPttUp(),
      onTapCancel: isPlaying ? null : () => onPttUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: active ? 0.25 : 0.1),
          border: Border.all(
            color: color,
            width: active ? 4 : 2.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: 48, color: color),
      ),
    );
  }
}

class _LatencyDisplay extends StatelessWidget {
  final int? currentMs;
  final double? averageMs;
  const _LatencyDisplay({this.currentMs, this.averageMs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _MetricTile(
          label: 'Current',
          value: currentMs != null ? '${currentMs}ms' : '--',
          color: _latencyColor(currentMs),
        ),
        const SizedBox(width: 32),
        _MetricTile(
          label: 'Average',
          value: averageMs != null ? '${averageMs!.round()}ms' : '--',
          color: _latencyColor(averageMs?.round()),
        ),
      ],
    );
  }

  Color _latencyColor(int? ms) {
    if (ms == null) return Colors.grey;
    if (ms < 200) return Colors.green;
    if (ms < 500) return Colors.orange;
    return Colors.red;
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DurationComparison extends StatelessWidget {
  final Duration? transmitDuration;
  final Duration? playbackDuration;

  const _DurationComparison({this.transmitDuration, this.playbackDuration});

  String _format(Duration? d) {
    if (d == null) return '--';
    final s = d.inMilliseconds / 1000;
    return '${s.toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              _format(transmitDuration),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: Colors.green,
              ),
            ),
            Text('Bicara', style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          ],
        ),
        const SizedBox(width: 24),
        Icon(Icons.arrow_forward, size: 16,
            color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 24),
        Column(
          children: [
            Text(
              _format(playbackDuration),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: Colors.orange,
              ),
            ),
            Text('Echo', style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
          ],
        ),
      ],
    );
  }
}
