import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_screen.dart'; // para MedicineProvider

void main() {
  runApp(const PastilleroApp());
}

class PastilleroApp extends StatelessWidget {
  const PastilleroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MedicineProvider(
      child: MaterialApp(
        title: 'Pastillero Inteligente',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D9E75),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}