import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


class BtService {
  BtService._();
  static final BtService instance = BtService._();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  bool _isConnected = false;

  // UUIDs del servicio BLE (deben coincidir con el ESP32)
  static const String serviceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String rxUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String txUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<List<ScanResult>> scanDevices() async {
    List<ScanResult> results = [];
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await for (final r in FlutterBluePlus.scanResults) {
      results = r;
    }
    return results;
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(license: License.commercial);
      _connectedDevice = device;

      final services = await device.discoverServices();
      for (final s in services) {
        if (s.uuid.toString().toUpperCase() == serviceUUID) {
          for (final c in s.characteristics) {
            final uuid = c.uuid.toString().toUpperCase();
            if (uuid == rxUUID) _rxCharacteristic = c;
            if (uuid == txUUID) _txCharacteristic = c;
          }
        }
      }
      _isConnected = true;
      return true;
    } catch (e) {
      print('Error conectando: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _isConnected = false;
  }

  Future<String?> sendCommand(String command) async {
    if (!_isConnected || _rxCharacteristic == null) return null;
    try {
      await _rxCharacteristic!.write(
        utf8.encode('$command\n'),
        withoutResponse: false,
      );

      if (_txCharacteristic != null) {
        await _txCharacteristic!.setNotifyValue(true);
        final data = await _txCharacteristic!.lastValueStream
            .timeout(const Duration(seconds: 5))
            .first;
        return utf8.decode(data).trim();
      }
      return null;
    } catch (e) {
      print('Error enviando: $e');
      return null;
    }
  }
}