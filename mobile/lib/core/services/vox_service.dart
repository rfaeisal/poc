import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final voxServiceProvider = Provider<VoxService>((ref) => VoxService());

class VoxService {
  bool _active = false;
  double _threshold = 0.3;
  Timer? _silenceTimer;
  void Function()? onVoxStart;
  void Function()? onVoxStop;
  bool _isTransmitting = false;

  bool get isActive => _active;

  void configure({required double threshold}) {
    _threshold = threshold;
  }

  void start() {
    _active = true;
    _isTransmitting = false;
  }

  void stop() {
    _active = false;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    if (_isTransmitting) {
      _isTransmitting = false;
      onVoxStop?.call();
    }
  }

  void onAudioLevel(double level) {
    if (!_active) return;

    if (level > _threshold) {
      _silenceTimer?.cancel();
      _silenceTimer = null;

      if (!_isTransmitting) {
        _isTransmitting = true;
        onVoxStart?.call();
      }
    } else if (_isTransmitting) {
      _silenceTimer ??= Timer(const Duration(seconds: 1), () {
        _isTransmitting = false;
        _silenceTimer = null;
        onVoxStop?.call();
      });
    }
  }

  void dispose() {
    stop();
  }
}
