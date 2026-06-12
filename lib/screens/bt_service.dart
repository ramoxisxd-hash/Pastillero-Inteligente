import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BtService {
  BtService._();
  static final BtService instance = BtService._();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  bool _isConnected = false;

  // ✅ UUIDs con Guid para v1.x
  static final Guid _serviceGuid = Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid _rxGuid      = Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid _txGuid      = Guid("6E400003-B5A3-F393-E0A9-E50E24DCCA9E");

  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // ✅ Solicitar permisos en runtime
  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  // ✅ Escanear dispositivos BLE
  Future<List<ScanResult>> scanDevices() async {
    List<ScanResult> results = [];
    try {
      final granted = await _requestPermissions();
      if (!granted) {
        print('Permisos BLE denegados');
        return [];
      }

      // Verificar que el Bluetooth esté encendido
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('Bluetooth apagado');
        return [];
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      await Future.delayed(const Duration(seconds: 8));
      results = await FlutterBluePlus.scanResults.first;
    } catch (e) {
      print('Error escaneando: $e');
    }
    return results;
  }

  // ✅ Conectar al dispositivo
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      final services = await device.discoverServices();
      for (final s in services) {
        // ✅ Comparación con Guid directamente
        if (s.uuid == _serviceGuid) {
          for (final c in s.characteristics) {
            if (c.uuid == _rxGuid) _rxCharacteristic = c;
            if (c.uuid == _txGuid) _txCharacteristic = c;
          }
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        print('No se encontraron las características BLE');
        await disconnect();
        return false;
      }

      // ✅ Activar notificaciones del TX al momento de conectar
      await _txCharacteristic!.setNotifyValue(true);
      _isConnected = true;
      return true;
    } catch (e) {
      print('Error conectando: $e');
      return false;
    }
  }

  // ✅ Desconectar
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice  = null;
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _isConnected      = false;
  }

  // ✅ Enviar comando y esperar respuesta
  Future<String?> sendCommand(String command) async {
    if (!_isConnected || _rxCharacteristic == null) return null;
    try {
      await _rxCharacteristic!.write(
        utf8.encode('$command\n'),
        withoutResponse: false,
      );

      // Esperar respuesta por TX con timeout
      final data = await _txCharacteristic!.lastValueStream
          .where((d) => d.isNotEmpty)
          .timeout(const Duration(seconds: 5))
          .first;
      return utf8.decode(data).trim();
    } catch (e) {
      print('Error enviando comando: $e');
      return null;
    }
  }
}