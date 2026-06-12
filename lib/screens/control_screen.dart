import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'bt_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final BtService _bt = BtService.instance;
  final List<bool> _dispensing = [false, false, false, false];
  String _statusMessage = 'Listo para dispensar';
  bool _isSuccess = true;

  Future<void> _dispense(int index) async {
    if (!_bt.isConnected) {
      setState(() {
        _statusMessage = 'Sin conexión Bluetooth';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _dispensing[index] = true;
      _statusMessage = 'Dispensando compartimento ${index + 1}...';
      _isSuccess = true;
    });

    final resp = await _bt.sendCommand('DISPENSAR:${index + 1}');
    final ok = resp != null && resp.startsWith('OK');

    setState(() {
      _dispensing[index] = false;
      _statusMessage = ok
          ? 'Dispensado OK — compartimento ${index + 1}'
          : 'Error al dispensar compartimento ${index + 1}';
      _isSuccess = ok;
    });
  }

  Future<void> _reset() async {
    if (!_bt.isConnected) {
      setState(() {
        _statusMessage = 'Sin conexión Bluetooth';
        _isSuccess = false;
      });
      return;
    }

    setState(() => _statusMessage = 'Reiniciando servos...');
    final resp = await _bt.sendCommand('RESET');
    final ok = resp != null && resp.startsWith('OK');

    setState(() {
      _statusMessage =
          ok ? 'Posición inicial restaurada' : 'Error al reiniciar';
      _isSuccess = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final medicines = MedicineProvider.of(context).medicines;
    final Map<int, String> slotNames = {
      for (final m in medicines) m.compartment: m.name
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Control',
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
              color: _bt.isConnected
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.circle,
                    size: 8,
                    color: _bt.isConnected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800)),
                const SizedBox(width: 5),
                Text(
                  _bt.isConnected ? 'Conectado' : 'Sin conexión',
                  style: TextStyle(
                    fontSize: 12,
                    color: _bt.isConnected
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
            const Text('COMPARTIMENTOS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                    letterSpacing: 0.8)),
            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final slot = index + 1;
                final name = slotNames[slot];
                final isDispensing = _dispensing[index];
                return _CompartmentCard(
                  slot: slot,
                  medicineName: name,
                  isDispensing: isDispensing,
                  onDispense: !isDispensing
                      ? () => _dispense(index)
                      : null,
                );
              },
            ),

            const SizedBox(height: 16),

            // Barra de estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 18,
                    color: _isSuccess
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estado: $_statusMessage',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isSuccess
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFB71C1C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botón reset
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset posición',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF555555),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(
                      color: Color(0xFFDDDDDD), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de compartimento ──────────────────────────────────────
class _CompartmentCard extends StatelessWidget {
  final int slot;
  final String? medicineName;
  final bool isDispensing;
  final VoidCallback? onDispense;

  const _CompartmentCard({
    required this.slot,
    required this.medicineName,
    required this.isDispensing,
    this.onDispense,
  });

  static const _colors = [
    Color(0xFF5B8DEF),
    Color(0xFF4CAF82),
    Color(0xFFFF8C42),
    Color(0xFF9B59B6),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[slot - 1];
    final hasmed = medicineName != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasmed
              ? color.withOpacity(0.4)
              : const Color(0xFFEEEEEE),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$slot',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medicineName ?? 'Sin asignar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        hasmed ? FontWeight.w600 : FontWeight.normal,
                    color: hasmed
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFBBBBBB),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDispense,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasmed ? color : const Color(0xFFF0F0F0),
                foregroundColor:
                    hasmed ? Colors.white : const Color(0xFFCCCCCC),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: isDispensing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Dispensar',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}