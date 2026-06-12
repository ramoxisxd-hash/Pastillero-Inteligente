import 'package:flutter/material.dart';
import 'control_screen.dart';
import 'connection_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // IndexedStack mantiene vivos todos los widgets,
  // así el estado de DashboardScreen nunca se destruye
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          ControlScreen(),
          ConnectionScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_remote_outlined),
            selectedIcon: Icon(Icons.settings_remote),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi_outlined),
            selectedIcon: Icon(Icons.wifi),
            label: 'Conexión',
          ),
        ],
      ),
    );
  }
}