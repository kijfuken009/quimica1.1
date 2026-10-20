import 'package:flutter/material.dart';
import 'game_level_screen.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Academia de Retos")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _gameTile(context, "Nivel 1: El Buscador", "Encuentra elementos por su símbolo", Icons.search, true),
          _gameTile(context, "Nivel 2: Peso Atómico", "Ordena los elementos por masa", Icons.scale, false),
          _gameTile(context, "Nivel 3: Maestro de Gases", "Identifica los gases nobles", Icons.air, false),
          _gameTile(context, "Nivel 4: Alquimista", "Combina elementos correctamente", Icons.science, false),
        ],
      ),
    );
  }

  Widget _gameTile(BuildContext context, String title, String desc, IconData icon, bool isUnlocked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Icon(icon, color: isUnlocked ? Colors.indigo : Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: Icon(
          isUnlocked ? Icons.play_arrow : Icons.lock,
          color: isUnlocked ? Colors.green : Colors.red
        ),
        onTap: isUnlocked
          ? () {
              // Definimos el reto según el título del juego
              String instruction = "";
              String correctAns = "";

              if (title == "Nivel 1: El Buscador") {
                instruction = "Símbolo del Hidrógeno:";
                correctAns = "H";
              } else if (title == "Nivel 2: Peso Atómico") {
                instruction = "Símbolo del Helio:";
                correctAns = "He";
              } else if (title == "Nivel 3: Maestro de Gases") {
                instruction = "Símbolo del Neón:";
                correctAns = "Ne";
              } else {
                instruction = "Símbolo del Oxígeno:";
                correctAns = "O";
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GameLevelScreen(
                    gameTitle: title,
                    instruction: instruction,
                    correctAnswer: correctAns,
                  ),
                ),
              );
            }
          : null,
      ),
    );
  }
}