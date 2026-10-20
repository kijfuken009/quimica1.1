import 'dart:convert';
import 'package:flutter/services.dart';

class GameQuestion {
  final String question;
  final String answer;

  GameQuestion({required this.question, required this.answer});

  factory GameQuestion.fromJson(Map<String, dynamic> json) {
    return GameQuestion(
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
    );
  }
}

class GameService {
  /// Carga el JSON del nivel y selecciona aleatoriamente la cantidad solicitada
  Future<List<GameQuestion>> loadRandomQuestions(int level, {int limit = 5}) async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/games/level$level.json');
      final List<dynamic> data = jsonDecode(response);

      List<GameQuestion> questions =
          data.map((item) => GameQuestion.fromJson(item as Map<String, dynamic>)).toList();

      // Barajar preguntas
      questions.shuffle();

      // Devolver solo el límite pedido
      return questions.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}