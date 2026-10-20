import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/game_service.dart';
import '../../../providers/user_provider.dart';
import 'game_level_screen.dart';

class GamesMenuScreen extends StatelessWidget {
  const GamesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Academia de Química"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const Text("Puntaje Acumulado", style: TextStyle(fontSize: 14)),
                const SizedBox(height: 5),
                Text(
                  "${user?.totalPoints ?? 0} pts",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildGameCard(
                  context,
                  level: 1,
                  title: "Nivel 1: Símbolos Básicos",
                  description: "Descubre los elementos más esenciales.",
                  icon: Icons.science,
                ),
                _buildGameCard(
                  context,
                  level: 2,
                  title: "Nivel 2: Alcalinos y Terrosos",
                  description: "Grupos 1 y 2 de la tabla periódica.",
                  icon: Icons.electric_bolt,
                ),
                _buildGameCard(
                  context,
                  level: 3,
                  title: "Nivel 3: Gases Nobles y No Metales",
                  description: "Elementos estables y reactivos clave.",
                  icon: Icons.bubble_chart,
                ),
                _buildGameCard(
                  context,
                  level: 4,
                  title: "Nivel 4: Maestro Químico",
                  description: "El desafío integral con propiedades avanzadas.",
                  icon: Icons.emoji_events,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    BuildContext context, {
    required int level,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final bool isUnlocked = (user?.unlockedLevel ?? 1) >= level;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isUnlocked ? 2 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isUnlocked ? Colors.indigo.withValues(alpha: 0.15) : Colors.grey[300],
          child: Icon(icon, color: isUnlocked ? Colors.indigo : Colors.grey[600]),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? Colors.black87 : Colors.grey[600],
          ),
        ),
        subtitle: Text(description),
        trailing: Icon(
          isUnlocked ? Icons.play_arrow_rounded : Icons.lock_outline,
          color: isUnlocked ? Colors.green : Colors.grey,
        ),
        onTap: isUnlocked
            ? () async {
                final gameService = GameService();
                final questions = await gameService.loadRandomQuestions(level);

                if (questions.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error al cargar las preguntas del nivel")),
                  );
                  return;
                }

                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameLevelScreen(
                      gameTitle: title,
                      levelNumber: level,
                      questions: questions,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}