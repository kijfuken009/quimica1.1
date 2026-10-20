import 'package:flutter/material.dart';
import '../periodic_table/table_screen.dart';
import '../ai_chat/chat_screen.dart';
import '../games/games_menu_screen.dart';
import '../settings/settings_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ChemIA - Panel Principal")),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _menuItem(context, "Tabla Periódica", Icons.grid_view, Colors.blue, const TableScreen()),
          _menuItem(context, "IA Tutor", Icons.psychology, Colors.purple, const ChatScreen()),
          _menuItem(context, "Mini Juegos", Icons.gamepad, Colors.orange, const GamesMenuScreen()),
          _menuItem(context, "Ajustes", Icons.settings, Colors.grey, const SettingsScreen()),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, IconData icon, Color color, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}