import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'bt_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final BtService _bt = BtService.instance;
  bool _loading = false;
  List<BluetoothDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadPaired();
  }

  Future<void> _loadPaired() async {
    setState(() => _loading = true);
    final devices = await _bt.getPairedDevices();
    setState(() {
      _devices = devices;
      _loading = false;
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _loading = true);
    final ok = await _bt.connect(device);
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Conectado a ${device.name}'
            : 'No se pudo conectar. Verifica que el ESP32 esté encendido'),
        backgroundColor:
            ok ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
      ),
    );
    setState(() {});
  }

  Future<void> _disconnect() async {
    await _bt.disconnect();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final connected = _bt.isConnected;
    final deviceName = _bt.connectedDevice?.name ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Conexión',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Color(0xFF1A1A2E))),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: connected
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.circle,
                    size: 8,
                    color: connected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800)),
                const SizedBox(width: 5),
                Text(
                  connected ? 'Conectado' : 'Sin conexión',
                  style: TextStyle(
                    fontSize: 12,
                    color: connected
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Dispositivo conectado actualmente ─────
            if (connected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF4CAF82).withOpacity(0.4),
                      width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF82).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bluetooth_connected,
                          color: Color(0xFF4CAF82), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deviceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E))),
                          const Text('Dispositivo conectado',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4CAF82))),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _disconnect,
                      child: const Text('Desconectar',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Título + botón refrescar ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DISPOSITIVOS PAREADOS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF888888),
                        letterSpacing: 0.8)),
                TextButton.icon(
                  onPressed: _loading ? null : _loadPaired,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Actualizar'),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5B8DEF)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Instrucción de pareo ──────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Color(0xFF4527A0)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Primero paréalo desde Ajustes → Bluetooth del celular. El PIN es 1234. Luego vuelve aquí y tócalo para conectar.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF4527A0)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Lista ─────────────────────────────────
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_devices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.bluetooth_disabled,
                          size: 52, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No hay dispositivos pareados',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(
                          'Ve a Ajustes → Bluetooth y paréa el ESP32 primero',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final name = device.name ?? 'Desconocido';
                    final isEsp = name.contains('ESP32') ||
                        name.contains('Pastillero');
                    final isActive =
                        _bt.connectedDevice?.address == device.address;

                    return ListTile(
                      leading: Icon(
                        isActive
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth,
                        color: isActive
                            ? const Color(0xFF4CAF82)
                            : isEsp
                                ? const Color(0xFF5B8DEF)
                                : const Color(0xFF888888),
                      ),
                      title: Text(name,
                          style: TextStyle(
                            fontWeight: isEsp
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isActive
                                ? const Color(0xFF4CAF82)
                                : const Color(0xFF1A1A2E),
                          )),
                      subtitle: Text(device.address,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888))),
                      trailing: isActive
                          ? const Icon(Icons.check_circle,
                              color: Color(0xFF4CAF82), size: 20)
                          : const Icon(Icons.chevron_right,
                              color: Color(0xFF888888)),
                      onTap: isActive ? null : () => _connect(device),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}