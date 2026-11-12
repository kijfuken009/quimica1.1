import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/game_service.dart';
import '../../../providers/user_provider.dart';

class GameLevelScreen extends StatefulWidget {
  final String gameTitle;
  final int levelNumber; // 1 al 36 (Número de Clase)
  final int trimestre; // 1, 2 o 3
  final List<GameQuestion> questions;
  final bool isSurpriseExam; // Si es true, NO tiene temporizador
  final String surpriseExamId;

  const GameLevelScreen({
    super.key,
    required this.gameTitle,
    required this.levelNumber,
    required this.questions,
    this.trimestre = 1,
    this.isSurpriseExam = false,
    this.surpriseExamId = '',
  });

  @override
  State<GameLevelScreen> createState() => _GameLevelScreenState();
}

class _GameLevelScreenState extends State<GameLevelScreen> {
  static const int questionDuration = 30; // 30 segundos por pregunta en clases regulares
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
    if (widget.isSurpriseExam) {
      setState(() {
        _timeOut = false;
      });
      return;
    }

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
    final bool correct =
        _normalize(_answerController.text) == _normalize(correctAns);

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
    final int totalQ = widget.questions.length;
    final int gradeOn100 = ((score / totalQ) * 100).round();
    final bool passed = gradeOn100 >= 60;

    await userProv.addPointsAndUnlockLevel(
      pointsWon: score * 10,
      completedLevel: widget.levelNumber,
      passed: passed,
      scoreOn100: gradeOn100,
      isSurpriseExam: widget.isSurpriseExam,
      surpriseExamId: widget.surpriseExamId,
      surpriseTitle: widget.gameTitle,
      trimestre: widget.trimestre,
    );

    if (!mounted) return;
    _showReportDialog(passed, gradeOn100);
  }

  void _showReportDialog(bool passed, int gradeOn100) {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final userName = userProv.user?.name ?? "Estudiante";
    final qrPayload = userProv.generateStudentQrPayload();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.isSurpriseExam
              ? "⚡ Resultado: Evaluación Sorpresa"
              : "📊 Calificación de la Clase",
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Estudiante: $userName",
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  "${widget.trimestre}.º Trimestre • ${widget.gameTitle}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
                const Divider(height: 20),
                Text(
                  "$gradeOn100 / 100 pts",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                Text(
                  "Aciertos: $score de ${widget.questions.length} (+${score * 10} pts)",
                  style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                if (qrPayload.isNotEmpty) ...[
                  const Text(
                    "Muestra este QR al docente para registrar tu nota:",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 190,
                      height: 190,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 170,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  passed
                      ? "🎉 ¡Aprobado! Se desbloqueó el siguiente desafío."
                      : "💡 Obtuviste menos de 60/100 pts. ¡Repasa la clase e inténtalo de nuevo!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: passed ? Colors.green[700] : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
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
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.questions.length,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 20),

            if (widget.isSurpriseExam)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber[800]!, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Colors.amber[900]),
                    const SizedBox(width: 8),
                    Text(
                      "Evaluación Sorpresa • Sin temporizador",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeft <= 5
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.indigo.withValues(alpha: 0.1),
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
            ],
            const SizedBox(height: 25),

            Text(
              "Pregunta ${currentQuestionIndex + 1} de ${widget.questions.length}",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  currentQuestion.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w600),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                  label: const Text("Comprobar Respuesta"),
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
                  border: Border.all(
                      color: _isCorrect ? Colors.green : Colors.red),
                ),
                child: Text(
                  _isCorrect
                      ? "¡Correcto! (+10 pts)"
                      : _timeOut
                          ? "⏰ ¡Tiempo agotado (30s)! Respuesta correcta: ${currentQuestion.answer}"
                          : "Respuesta correcta: ${currentQuestion.answer}",
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
                        : "Ver Calificación Final",
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