import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum KeyAction { ptt, channelUp, channelDown }

class KeyBindings {
  final LogicalKeyboardKey? pttKey;
  final LogicalKeyboardKey? channelUpKey;
  final LogicalKeyboardKey? channelDownKey;

  const KeyBindings({
    this.pttKey,
    this.channelUpKey,
    this.channelDownKey,
  });

  KeyBindings copyWithAction(KeyAction action, LogicalKeyboardKey? key) {
    switch (action) {
      case KeyAction.ptt:
        return KeyBindings(pttKey: key, channelUpKey: channelUpKey, channelDownKey: channelDownKey);
      case KeyAction.channelUp:
        return KeyBindings(pttKey: pttKey, channelUpKey: key, channelDownKey: channelDownKey);
      case KeyAction.channelDown:
        return KeyBindings(pttKey: pttKey, channelUpKey: channelUpKey, channelDownKey: key);
    }
  }

  LogicalKeyboardKey? keyFor(KeyAction action) {
    switch (action) {
      case KeyAction.ptt:
        return pttKey;
      case KeyAction.channelUp:
        return channelUpKey;
      case KeyAction.channelDown:
        return channelDownKey;
    }
  }

  KeyAction? actionFor(LogicalKeyboardKey key) {
    if (pttKey != null && key == pttKey) return KeyAction.ptt;
    if (channelUpKey != null && key == channelUpKey) return KeyAction.channelUp;
    if (channelDownKey != null && key == channelDownKey) return KeyAction.channelDown;
    return null;
  }

  String labelFor(KeyAction action) {
    final key = keyFor(action);
    if (key == null) return '';
    if (key == LogicalKeyboardKey.space) return 'SPACE';
    if (key == LogicalKeyboardKey.audioVolumeUp) return 'VOL +';
    if (key == LogicalKeyboardKey.audioVolumeDown) return 'VOL -';
    if (key == LogicalKeyboardKey.arrowUp) return 'UP';
    if (key == LogicalKeyboardKey.arrowDown) return 'DOWN';
    return key.keyLabel.isNotEmpty ? key.keyLabel.toUpperCase() : 'KEY ${key.keyId}';
  }
}

class HardwareKeyNotifier extends StateNotifier<KeyBindings> {
  static const _prefixKey = 'hytera_keybind_';
  static const _pttTailMs = 300;
  DateTime? _pttDownTime;
  Timer? _pttTailTimer;

  void Function()? onPttDown;
  void Function()? onPttUp;
  void Function()? onChannelUp;
  void Function()? onChannelDown;

  HardwareKeyNotifier() : super(const KeyBindings());

  Future<void> loadBindings() async {
    final prefs = await SharedPreferences.getInstance();
    final pttId = prefs.getInt('${_prefixKey}ptt');
    final upId = prefs.getInt('${_prefixKey}channelUp');
    final downId = prefs.getInt('${_prefixKey}channelDown');

    state = KeyBindings(
      pttKey: pttId != null ? LogicalKeyboardKey(pttId) : null,
      channelUpKey: upId != null ? LogicalKeyboardKey(upId) : null,
      channelDownKey: downId != null ? LogicalKeyboardKey(downId) : null,
    );
  }

  Future<void> saveBinding(KeyAction action, LogicalKeyboardKey key) async {
    state = state.copyWithAction(action, key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefixKey${action.name}', key.keyId);
  }

  Future<void> clearBinding(KeyAction action) async {
    state = state.copyWithAction(action, null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefixKey${action.name}');
  }

  void resetPttState() {
    _pttTailTimer?.cancel();
    if (_pttDownTime != null) {
      onPttUp?.call();
    }
    _pttDownTime = null;
  }

  bool handleKeyEvent(KeyEvent event) {
    final action = state.actionFor(event.logicalKey);
    if (action == null) return false;

    switch (action) {
      case KeyAction.ptt:
        if (event is KeyDownEvent) {
          _pttTailTimer?.cancel();
          if (_pttDownTime == null) {
            _pttDownTime = DateTime.now();
            onPttDown?.call();
          }
        } else if (event is KeyUpEvent) {
          _pttDownTime = null;
          _pttTailTimer?.cancel();
          _pttTailTimer = Timer(const Duration(milliseconds: _pttTailMs), () {
            onPttUp?.call();
          });
        }
        return true;

      case KeyAction.channelUp:
        if (event is KeyDownEvent) onChannelUp?.call();
        return true;

      case KeyAction.channelDown:
        if (event is KeyDownEvent) onChannelDown?.call();
        return true;
    }
  }
}

final hardwareKeyProvider =
    StateNotifierProvider<HardwareKeyNotifier, KeyBindings>((ref) {
  final notifier = HardwareKeyNotifier();
  notifier.loadBindings();
  return notifier;
});
