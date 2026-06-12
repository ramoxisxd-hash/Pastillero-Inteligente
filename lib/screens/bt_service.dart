import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';

class BtService {
  BtService._();
  static final BtService instance = BtService._();

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  String _buffer = '';

  bool get isConnected =>
      _connection != null && (_connection?.isConnected ?? false);
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      final devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (e) {
      print('Error obteniendo pareados: $e');
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      final conn = await BluetoothConnection.toAddress(device.address);
      _connection = conn;
      _connectedDevice = device;
      _buffer = '';
      return true;
    } catch (e) {
      print('Error conectando: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
    _connectedDevice = null;
    _buffer = '';
  }

  Future<String?> sendCommand(String command) async {
    if (!isConnected) return null;
    try {
      _connection!.output
          .add(Uint8List.fromList(utf8.encode('$command\n')));
      await _connection!.output.allSent;

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      _buffer = '';

      await for (final data in _connection!.input!) {
        _buffer += utf8.decode(data);
        if (_buffer.contains('\n')) {
          final line = _buffer.split('\n').first.trim();
          _buffer = '';
          return line;
        }
        if (DateTime.now().isAfter(deadline)) break;
      }
      return null;
    } catch (e) {
      print('Error enviando: $e');
      return null;
    }
  }
}