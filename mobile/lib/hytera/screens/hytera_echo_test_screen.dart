import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/talk_timer.dart';
import '../../features/echo_test/providers/echo_test_provider.dart';

class HyteraEchoTestScreen extends ConsumerStatefulWidget {
  const HyteraEchoTestScreen({super.key});

  @override
  ConsumerState<HyteraEchoTestScreen> createState() =>
      _HyteraEchoTestScreenState();
}

class _HyteraEchoTestScreenState extends ConsumerState<HyteraEchoTestScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(echoTestProvider.notifier).start());
  }

  @override
  void dispose() {
    ref.read(echoTestProvider.notifier).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final echo = ref.watch(echoTestProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF060C18),
              border: Border(
                bottom: BorderSide(color: Color(0xFF0A1020)),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  'ECHO TEST',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: Color(0xFF4A9EFF),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: _buildContent(echo),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EchoTestState echo) {
    if (echo.status == EchoTestStatus.connecting) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4A9EFF),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'MENGHUBUNGKAN...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Color(0xFF4A9EFF),
            ),
          ),
        ],
      );
    }

    if (echo.status == EchoTestStatus.error) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 24, color: Color(0xFFEF4444)),
          const SizedBox(height: 8),
          Text(
            echo.error ?? 'Gagal',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: Color(0xFFEF4444),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => ref.read(echoTestProvider.notifier).start(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E2E),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF1E4A8A)),
              ),
              child: const Text(
                'COBA LAGI',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A9EFF),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (echo.status == EchoTestStatus.idle) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4A9EFF),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'MEMULAI...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: Color(0xFF4A9EFF),
            ),
          ),
        ],
      );
    }

    final isTransmitting = echo.status == EchoTestStatus.transmitting;
    final isPlaying = echo.status == EchoTestStatus.playing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Latency — fixed height so button never shifts
        SizedBox(
          height: 38,
          child: echo.latencyMs != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${echo.latencyMs} ms',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _latencyColor(echo.latencyMs),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ROUND TRIP',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 7,
                        color: Color(0xFF2A4A6A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // PTT Button
        GestureDetector(
          onTapDown: isPlaying
              ? null
              : (_) => ref.read(echoTestProvider.notifier).startTransmit(),
          onTapUp: isPlaying
              ? null
              : (_) => ref.read(echoTestProvider.notifier).stopTransmit(),
          onTapCancel: isPlaying
              ? null
              : () => ref.read(echoTestProvider.notifier).stopTransmit(),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTransmitting
                  ? const Color(0xFF0A2010)
                  : isPlaying
                      ? const Color(0xFF1A1500)
                      : const Color(0xFF0F2040),
              border: Border.all(
                color: isTransmitting
                    ? const Color(0xFF4ADE80)
                    : isPlaying
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF1E4A8A),
                width: 2,
              ),
            ),
            child: Icon(
              isTransmitting
                  ? Icons.mic
                  : isPlaying
                      ? Icons.volume_up
                      : Icons.mic_none,
              size: 22,
              color: isTransmitting
                  ? const Color(0xFF4ADE80)
                  : isPlaying
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF4A9EFF),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Duration — fixed height
        SizedBox(
          height: 20,
          child: isTransmitting
              ? TalkTimer(
                  isActive: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4ADE80),
                  ),
                )
              : (echo.transmitDuration != null)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _fmtDuration(echo.transmitDuration),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                        const Text(
                          ' → ',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Color(0xFF4A6A8A),
                          ),
                        ),
                        Text(
                          _fmtDuration(echo.playbackDuration),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFBBF24),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
        ),
        const SizedBox(height: 4),

        // Status text — fixed height
        SizedBox(
          height: 14,
          child: Text(
            isTransmitting
                ? 'Bicara sekarang...'
                : isPlaying
                    ? 'Mendengarkan echo...'
                    : 'Tekan & tahan untuk bicara',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: isTransmitting
                  ? const Color(0xFF4ADE80)
                  : isPlaying
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF4A6A8A),
            ),
          ),
        ),
      ],
    );
  }

  Color _latencyColor(int? ms) {
    if (ms == null) return const Color(0xFF4A6A8A);
    if (ms < 200) return const Color(0xFF4ADE80);
    if (ms < 500) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
  }

  String _fmtDuration(Duration? d) {
    if (d == null) return '--';
    final s = d.inMilliseconds / 1000;
    return '${s.toStringAsFixed(1)}s';
  }
}
