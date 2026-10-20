import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/game_service.dart';
import '../../../providers/user_provider.dart';

class GameLevelScreen extends StatefulWidget {
  final String gameTitle;
  final int levelNumber;
  final List<GameQuestion> questions;

  const GameLevelScreen({
    super.key,
    required this.gameTitle,
    required this.levelNumber,
    required this.questions,
  });

  @override
  State<GameLevelScreen> createState() => _GameLevelScreenState();
}

class _GameLevelScreenState extends State<GameLevelScreen> {
  static const int questionDuration = 15; // 15 segundos por pregunta
  int currentQuestionIndex = 0;
  int score = 0;
  int _timeLeft = questionDuration;
  Timer? _timer;

  final TextEditingController _answerController = TextEditingController();
  bool _showResult = false;
  bool _isCorrect = false;
  bool _timeOut = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = questionDuration;
      _timeOut = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    setState(() {
      _isCorrect = false;
      _timeOut = true;
      _showResult = true;
    });
  }

  String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  void _checkAnswer() {
    if (_answerController.text.trim().isEmpty || _showResult) return;
    _timer?.cancel();

    final String correctAns = widget.questions[currentQuestionIndex].answer;
    final bool correct = _normalize(_answerController.text) == _normalize(correctAns);

    setState(() {
      _isCorrect = correct;
      _timeOut = false;
      if (correct) score++;
      _showResult = true;
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _showResult = false;
        _answerController.clear();
        currentQuestionIndex++;
      });
      _startTimer();
    } else {
      _finishGame();
    }
  }

  Future<void> _finishGame() async {
    _timer?.cancel();
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final bool passed = score >= (widget.questions.length * 0.6).ceil();

    await userProv.addPointsAndUnlockLevel(
      pointsWon: score * 10,
      completedLevel: widget.levelNumber,
      passed: passed,
    );

    if (!mounted) return;
    _showReportDialog(passed);
  }

  void _showReportDialog(bool passed) {
    final userName = Provider.of<UserProvider>(context, listen: false).user?.name ?? "Estudiante";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("📊 Resultados del Reto", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Estudiante: $userName", style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text("Nivel: ${widget.gameTitle}"),
            const Divider(height: 25),
            Text(
              "$score / ${widget.questions.length}",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            Text("+${score * 10} puntos obtenidos", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            Text(
              passed
                  ? "🎉 ¡Excelente trabajo! Has superado el reto y desbloqueado nuevos desafíos."
                  : "💡 Estuviste cerca. ¡Prueba de nuevo para mejorar tu velocidad!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: passed ? Colors.green[700] : Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Continuar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[currentQuestionIndex];
    final progressTimer = _timeLeft / questionDuration;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progreso del juego
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.questions.length,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 20),

            // Reloj / Cronómetro dinámico
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _timeLeft <= 5 ? Colors.red.withValues(alpha: 0.15) : Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _timeLeft <= 5 ? Colors.red : Colors.indigo,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: _timeLeft <= 5 ? Colors.red : Colors.indigo,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$_timeLeft s",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _timeLeft <= 5 ? Colors.red : Colors.indigo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progressTimer,
              backgroundColor: Colors.grey[200],
              color: _timeLeft <= 5 ? Colors.red : Colors.indigo,
              minHeight: 4,
            ),
            const SizedBox(height: 25),

            Text(
              "Pregunta ${currentQuestionIndex + 1} de ${widget.questions.length}",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  currentQuestion.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _answerController,
              enabled: !_showResult,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_showResult) _checkAnswer();
              },
              decoration: InputDecoration(
                labelText: "Escribe tu respuesta aquí",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 20),
            if (!_showResult)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _checkAnswer,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Comprobar"),
                ),
              ),
            if (_showResult) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                ),
                child: Text(
                  _isCorrect
                      ? "¡Correcto! Excelente deducción."
                      : _timeOut
                          ? "⏰ ¡Tiempo agotado! Respuesta: ${currentQuestion.answer}"
                          : "Respuesta esperada: ${currentQuestion.answer}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isCorrect ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _isCorrect ? Colors.green : Colors.indigo,
                  ),
                  onPressed: _nextQuestion,
                  child: Text(
                    currentQuestionIndex < widget.questions.length - 1
                        ? "Siguiente Pregunta →"
                        : "Ver Resultados",
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}