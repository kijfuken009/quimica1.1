import 'package:flutter/material.dart';

class GameLevelScreen extends StatefulWidget {
  final String gameTitle;
  final String instruction;
  final String correctAnswer;

  const GameLevelScreen({super.key, 
    required this.gameTitle,
    required this.instruction,
    required this.correctAnswer
  });

  @override
  State<GameLevelScreen> createState() => _GameLevelScreenState();
}

class _GameLevelScreenState extends State<GameLevelScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _showResult = false;
  bool _isCorrect = false;

  void _checkAnswer() {
    setState(() {
      _showResult = true;
      _isCorrect = _answerController.text.trim().toLowerCase() ==
                   widget.correctAnswer.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.gameTitle)),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isCorrect ? Icons.emoji_events : Icons.science,
              size: 80,
              color: _isCorrect ? Colors.amber : Colors.indigo
            ),
            const SizedBox(height: 20),
            Text(
              widget.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: "Tu respuesta",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle),
                  onPressed: _checkAnswer,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_showResult)
              _buildResultCard(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Volver al Menú"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isCorrect ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(_isCorrect ? Icons.check_circle : Icons.cancel, color: _isCorrect ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isCorrect
                  ? "¡Increíble! Eres un genio de la química."
                  : "Casi lo tienes. La respuesta correcta era: ${widget.correctAnswer}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}