import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/talk_timer.dart';
import '../../features/echo_test/providers/echo_test_provider.dart';

class KsunEchoTestScreen extends ConsumerStatefulWidget {
  static bool isActive = false;

  const KsunEchoTestScreen({super.key});

  @override
  ConsumerState<KsunEchoTestScreen> createState() =>
      _KsunEchoTestScreenState();
}

class _KsunEchoTestScreenState extends ConsumerState<KsunEchoTestScreen> {
  @override
  void initState() {
    super.initState();
    KsunEchoTestScreen.isActive = true;
    Future.microtask(() => ref.read(echoTestProvider.notifier).start());
  }

  @override
  void dispose() {
    KsunEchoTestScreen.isActive = false;
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: const BoxDecoration(
              color: Color(0xFF060C18),
              border: Border(
                bottom: BorderSide(color: Color(0xFF0A1020)),
              ),
            ),
            child: const Text(
              'ECHO TEST',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: Color(0xFF4A9EFF),
                fontWeight: FontWeight.w700,
              ),
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
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFF4A9EFF),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'MENGHUBUNGKAN...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
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
          const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
          const SizedBox(height: 4),
          Text(
            echo.error ?? 'Gagal',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
              color: Color(0xFFEF4444),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => ref.read(echoTestProvider.notifier).start(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1E2E),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF1E4A8A)),
              ),
              child: const Text(
                'COBA LAGI',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 7,
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
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFF4A9EFF),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'MEMULAI...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 7,
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
        if (echo.latencyMs != null)
          Text(
            '${echo.latencyMs} ms RTT',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: _latencyColor(echo.latencyMs),
            ),
          ),
        const SizedBox(height: 3),

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
            width: 28,
            height: 28,
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
              size: 12,
              color: isTransmitting
                  ? const Color(0xFF4ADE80)
                  : isPlaying
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF4A9EFF),
            ),
          ),
        ),
        const SizedBox(height: 3),

        if (isTransmitting)
          TalkTimer(
            isActive: true,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4ADE80),
            ),
          )
        else if (echo.transmitDuration != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _fmtDuration(echo.transmitDuration),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4ADE80),
                ),
              ),
              const Text(
                '→',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Color(0xFF4A6A8A),
                ),
              ),
              Text(
                _fmtDuration(echo.playbackDuration),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFBBF24),
                ),
              ),
            ],
          ),

        const SizedBox(height: 2),
        Text(
          isTransmitting
              ? 'Bicara...'
              : isPlaying
                  ? 'Echo...'
                  : 'Tekan & tahan',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 7,
            color: isTransmitting
                ? const Color(0xFF4ADE80)
                : isPlaying
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF4A6A8A),
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
