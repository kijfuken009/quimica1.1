import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/teacher_provider.dart';
import '../periodic_table/table_screen.dart';
import '../ai_chat/chat_screen.dart';
import '../games/games_menu_screen.dart';
import '../reactions/reactions_screen.dart';
import '../settings/settings_screens.dart';
import '../teacher/teacher_roster_screen.dart';
import '../teacher/teacher_exam_builder_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacherProv = Provider.of<TeacherProvider>(context);
    final bool isTeacher = teacherProv.isTeacherMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTeacher
              ? "ChemIA - Panel Docente"
              : "ChemIA - Panel Principal",
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          _menuItem(context, "Tabla Periódica", Icons.grid_view, Colors.blue,
              const TableScreen()),
          _menuItem(context, "Reacciones", Icons.science, Colors.teal,
              const ReactionsScreen()),
          _menuItem(context, "IA Tutor", Icons.psychology, Colors.purple,
              const ChatScreen()),
          _menuItem(context, "Mini Juegos", Icons.gamepad, Colors.orange,
              const GamesMenuScreen()),
          _menuItem(context, "Ajustes", Icons.settings, Colors.grey,
              const SettingsScreen()),
          if (isTeacher) ...[
            _menuItem(
              context,
              "Pizarra Alumnos",
              Icons.assignment_ind,
              Colors.indigo,
              const TeacherRosterScreen(),
            ),
            _menuItem(
              context,
              "Crear Evaluación",
              Icons.qr_code_2,
              Colors.green,
              const TeacherExamBuilderScreen(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, IconData icon,
      Color color, Widget screen) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}