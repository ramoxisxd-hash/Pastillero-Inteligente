import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Modelo ────────────────────────────────────────────────────────
class Medicine {
  final String name;
  final int compartment;
  final int dosesPerDay;
  final List<String> times;

  Medicine({
    required this.name,
    required this.compartment,
    required this.dosesPerDay,
    required this.times,
  });

  // Serialización para guardar en SharedPreferences
  Map<String, dynamic> toJson() => {
        'name': name,
        'compartment': compartment,
        'dosesPerDay': dosesPerDay,
        'times': times,
      };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        name: json['name'],
        compartment: json['compartment'],
        dosesPerDay: json['dosesPerDay'],
        times: List<String>.from(json['times']),
      );
}

// ── InheritedWidget: estado global accesible desde cualquier pantalla ──
class MedicineProvider extends StatefulWidget {
  final Widget child;
  const MedicineProvider({super.key, required this.child});

  @override
  State<MedicineProvider> createState() => MedicineProviderState();

  // Acceso desde cualquier widget: MedicineProvider.of(context)
  static MedicineProviderState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_MedicineInherited>()!
        .state;
  }
}

class MedicineProviderState extends State<MedicineProvider> {
  List<Medicine> medicines = [];

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  // Carga desde disco
  Future<void> _loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('medicines');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      setState(() {
        medicines = decoded.map((e) => Medicine.fromJson(e)).toList();
      });
    }
  }

  // Guarda en disco
  Future<void> _saveMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(medicines.map((m) => m.toJson()).toList());
    await prefs.setString('medicines', encoded);
  }

  void addMedicine(Medicine m) {
    setState(() => medicines.add(m));
    _saveMedicines();
  }

  void deleteMedicine(int index) {
    setState(() => medicines.removeAt(index));
    _saveMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return _MedicineInherited(state: this, child: widget.child);
  }
}

class _MedicineInherited extends InheritedWidget {
  final MedicineProviderState state;
  const _MedicineInherited({required this.state, required super.child});

  @override
  bool updateShouldNotify(_MedicineInherited old) => true;
}

// ── Dashboard ─────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _colors = [
    Color(0xFF5B8DEF),
    Color(0xFF4CAF82),
    Color(0xFFFF8C42),
    Color(0xFF9B59B6),
  ];

  void _openAddMedicine(BuildContext context) async {
    final provider = MedicineProvider.of(context);
    if (provider.medicines.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 4 pastillas permitidas')),
      );
      return;
    }

    final result = await showModalBottomSheet<Medicine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMedicineSheet(),
    );

    if (result != null) provider.addMedicine(result);
  }

  @override
  Widget build(BuildContext context) {
    final provider = MedicineProvider.of(context);
    final medicines = provider.medicines;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mi Pastillero',
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFF1A1A2E)),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                SizedBox(width: 5),
                Text('Conectado',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500)),
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
            // Botón añadir
            GestureDetector(
              onTap: () => _openAddMedicine(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF5B8DEF), width: 1.5),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 32, color: Color(0xFF5B8DEF)),
                    SizedBox(height: 6),
                    Text('Añadir pastilla',
                        style: TextStyle(
                            color: Color(0xFF5B8DEF),
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text('Mis pastillas',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(width: 8),
                Text('(${medicines.length}/4)',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF888888))),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: medicines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_outlined,
                              size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No hay pastillas registradas',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: medicines.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final med = medicines[index];
                        return _MedicineCard(
                          medicine: med,
                          color: _colors[med.compartment - 1],
                          number: index + 1,
                          onDelete: () =>
                              provider.deleteMedicine(index),
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

// ── Tarjeta ───────────────────────────────────────────────────────
class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final Color color;
  final int number;
  final VoidCallback onDelete;

  const _MedicineCard({
    required this.medicine,
    required this.color,
    required this.number,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(
              child: Text('$number',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(medicine.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 3),
                Text(
                    'Comp. ${medicine.compartment}  •  ${medicine.dosesPerDay} toma(s)/día',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF888888))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: medicine.times
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(t,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: Color(0xFF888888), size: 20),
            onSelected: (value) {
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Eliminar',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────
class AddMedicineSheet extends StatefulWidget {
  const AddMedicineSheet({super.key});

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet> {
  final _nameController = TextEditingController();
  int _selectedCompartment = 1;
  int _selectedDoses = 1;
  final List<TimeOfDay> _times = [TimeOfDay.now()];

  Future<void> _pickTime(int index) async {
    final picked =
        await showTimePicker(context: context, initialTime: _times[index]);
    if (picked != null) setState(() => _times[index] = picked);
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre de la pastilla')),
      );
      return;
    }
    Navigator.pop(
      context,
      Medicine(
        name: _nameController.text.trim(),
        compartment: _selectedCompartment,
        dosesPerDay: _selectedDoses,
        times: _times.map((t) => t.format(context)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Añadir nueva pastilla',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 20),

            // Nombre
            const Text('Nombre de la pastilla',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Ej: Paracetamol',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFDDDDDD))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFDDDDDD))),
              ),
            ),
            const SizedBox(height: 16),

            // Compartimento
            const Text('Compartimiento',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (i) {
                final n = i + 1;
                final sel = _selectedCompartment == n;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCompartment = n),
                    child: Container(
                      margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF5B8DEF)
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text('$n',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : const Color(0xFF555555))),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Tomas
            const Text('Tomas al día',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(3, (i) {
                final n = i + 1;
                final sel = _selectedDoses == n;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDoses = n;
                        while (_times.length < n) _times.add(TimeOfDay.now());
                        while (_times.length > n) _times.removeLast();
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF4CAF82)
                              : const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text('$n',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : const Color(0xFF555555))),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Horarios
            const Text('Programar horarios',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const SizedBox(height: 8),
            ...List.generate(_selectedDoses, (i) {
              return GestureDetector(
                onTap: () => _pickTime(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 18, color: Color(0xFF888888)),
                      const SizedBox(width: 10),
                      Text('Toma ${i + 1}:  ${_times[i].format(context)}',
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8DEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Guardar pastilla',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}