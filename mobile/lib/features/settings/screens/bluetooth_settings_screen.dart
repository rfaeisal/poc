import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class BluetoothSettingsScreen extends ConsumerStatefulWidget {
  const BluetoothSettingsScreen({super.key});

  @override
  ConsumerState<BluetoothSettingsScreen> createState() =>
      _BluetoothSettingsScreenState();
}

class _BluetoothSettingsScreenState
    extends ConsumerState<BluetoothSettingsScreen> {
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadBondedDevices();
  }

  Future<void> _loadBondedDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      if (mounted) setState(() => _devices = devices);
    } catch (_) {}
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isScanning = true;
      _devices = [];
    });

    try {
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      if (mounted) setState(() => _devices = bonded);
    } catch (_) {}

    if (mounted) setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth PTT'),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startDiscovery,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.bluetoothDeviceName != null) ...[
            ListTile(
              leading: const Icon(Icons.bluetooth_connected, color: Colors.blue),
              title: Text(settings.bluetoothDeviceName!),
              subtitle: const Text('Connected PTT device'),
              trailing: TextButton(
                onPressed: () => notifier.setBluetoothDevice(null, null),
                child: const Text('Disconnect'),
              ),
            ),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Paired Devices',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? Center(
                    child: Text(
                      _isScanning
                          ? 'Scanning...'
                          : 'No paired devices found.\nPair a device in Android Bluetooth settings first.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isSelected =
                          device.address == settings.bluetoothDeviceId;

                      return ListTile(
                        leading: Icon(
                          Icons.bluetooth,
                          color: isSelected ? Colors.blue : null,
                        ),
                        title: Text(device.name ?? 'Unknown'),
                        subtitle: Text(device.address),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : null,
                        onTap: () {
                          notifier.setBluetoothDevice(
                            device.address,
                            device.name ?? device.address,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
