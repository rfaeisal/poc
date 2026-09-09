import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bluetoothPttServiceProvider =
    Provider<BluetoothPttService>((ref) => BluetoothPttService());

enum BluetoothPttState { disconnected, connecting, connected }

class BluetoothPttService {
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSubscription;
  BluetoothPttState _state = BluetoothPttState.disconnected;

  void Function()? onButtonPressed;
  void Function()? onButtonReleased;

  final _stateController = StreamController<BluetoothPttState>.broadcast();
  Stream<BluetoothPttState> get stateStream => _stateController.stream;
  BluetoothPttState get state => _state;

  Future<void> connect(String address) async {
    if (_state == BluetoothPttState.connecting) return;

    _setState(BluetoothPttState.connecting);
    try {
      _connection =
          await BluetoothConnection.toAddress(address);
      _setState(BluetoothPttState.connected);

      _inputSubscription = _connection!.input?.listen(
        _handleInput,
        onDone: () => _setState(BluetoothPttState.disconnected),
        onError: (_) => _setState(BluetoothPttState.disconnected),
      );
    } catch (_) {
      _setState(BluetoothPttState.disconnected);
    }
  }

  void _handleInput(Uint8List data) {
    if (data.isEmpty) return;
    // Convention: 0x01 = button press, 0x00 = button release
    for (final byte in data) {
      if (byte == 0x01) {
        onButtonPressed?.call();
      } else if (byte == 0x00) {
        onButtonReleased?.call();
      }
    }
  }

  Future<void> disconnect() async {
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    _connection?.dispose();
    _connection = null;
    _setState(BluetoothPttState.disconnected);
  }

  void _setState(BluetoothPttState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    disconnect();
    _stateController.close();
  }
}
