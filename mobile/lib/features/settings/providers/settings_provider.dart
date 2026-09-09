import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class AppSettings {
  final double micGain;
  final double speakerGain;
  final bool voxEnabled;
  final double voxThreshold;
  final String? bluetoothDeviceId;
  final String? bluetoothDeviceName;
  final bool locationSharing;

  const AppSettings({
    this.micGain = 0.8,
    this.speakerGain = 0.8,
    this.voxEnabled = false,
    this.voxThreshold = 0.3,
    this.bluetoothDeviceId,
    this.bluetoothDeviceName,
    this.locationSharing = false,
  });

  AppSettings copyWith({
    double? micGain,
    double? speakerGain,
    bool? voxEnabled,
    double? voxThreshold,
    String? bluetoothDeviceId,
    String? bluetoothDeviceName,
    bool clearBluetooth = false,
    bool? locationSharing,
  }) =>
      AppSettings(
        micGain: micGain ?? this.micGain,
        speakerGain: speakerGain ?? this.speakerGain,
        voxEnabled: voxEnabled ?? this.voxEnabled,
        voxThreshold: voxThreshold ?? this.voxThreshold,
        bluetoothDeviceId:
            clearBluetooth ? null : (bluetoothDeviceId ?? this.bluetoothDeviceId),
        bluetoothDeviceName:
            clearBluetooth ? null : (bluetoothDeviceName ?? this.bluetoothDeviceName),
        locationSharing: locationSharing ?? this.locationSharing,
      );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      micGain: prefs.getDouble('micGain') ?? 0.8,
      speakerGain: prefs.getDouble('speakerGain') ?? 0.8,
      voxEnabled: prefs.getBool('voxEnabled') ?? false,
      voxThreshold: prefs.getDouble('voxThreshold') ?? 0.3,
      bluetoothDeviceId: prefs.getString('bluetoothDeviceId'),
      bluetoothDeviceName: prefs.getString('bluetoothDeviceName'),
      locationSharing: prefs.getBool('locationSharing') ?? false,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('micGain', state.micGain);
    await prefs.setDouble('speakerGain', state.speakerGain);
    await prefs.setBool('voxEnabled', state.voxEnabled);
    await prefs.setDouble('voxThreshold', state.voxThreshold);
    if (state.bluetoothDeviceId != null) {
      await prefs.setString('bluetoothDeviceId', state.bluetoothDeviceId!);
    } else {
      await prefs.remove('bluetoothDeviceId');
    }
    if (state.bluetoothDeviceName != null) {
      await prefs.setString('bluetoothDeviceName', state.bluetoothDeviceName!);
    } else {
      await prefs.remove('bluetoothDeviceName');
    }
    await prefs.setBool('locationSharing', state.locationSharing);
  }

  void setMicGain(double value) {
    state = state.copyWith(micGain: value);
    _save();
  }

  void setSpeakerGain(double value) {
    state = state.copyWith(speakerGain: value);
    _save();
  }

  void setVoxEnabled(bool value) {
    state = state.copyWith(voxEnabled: value);
    _save();
  }

  void setVoxThreshold(double value) {
    state = state.copyWith(voxThreshold: value);
    _save();
  }

  void setBluetoothDevice(String? id, String? name) {
    if (id == null) {
      state = state.copyWith(clearBluetooth: true);
    } else {
      state = state.copyWith(bluetoothDeviceId: id, bluetoothDeviceName: name);
    }
    _save();
  }

  void setLocationSharing(bool value) {
    state = state.copyWith(locationSharing: value);
    _save();
  }
}
