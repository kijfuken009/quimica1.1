import 'dart:convert';
import 'package:flutter/services.dart';

class GameQuestion {
  final String question;
  final String answer;

  GameQuestion({required this.question, required this.answer});

  factory GameQuestion.fromJson(Map<String, dynamic> json) {
    return GameQuestion(
      question: (json['question'] ?? json['q'] ?? '').toString(),
      answer: (json['answer'] ?? json['a'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'q': question,
        'a': answer,
      };
}

class ClassSessionInfo {
  final int numeroClase; // 1 al 36
  final int trimestre; // 1, 2 o 3
  final String titulo;
  final String temaCurricular;
  final String ecuacion;

  const ClassSessionInfo({
    required this.numeroClase,
    required this.trimestre,
    required this.titulo,
    required this.temaCurricular,
    required this.ecuacion,
  });
}

class GameService {
  Future<List<ClassSessionInfo>> loadCurriculumClasses() async {
    try {
      final String data =
          await rootBundle.loadString('assets/data/reactions.json');
      final List<dynamic> list = jsonDecode(data);
      final List<ClassSessionInfo> classes = list.map((item) {
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(item as Map);
        return ClassSessionInfo(
          numeroClase: (map['numeroClase'] as num?)?.toInt() ?? 1,
          trimestre: (map['trimestre'] as num?)?.toInt() ?? 1,
          titulo: map['nombre']?.toString() ?? 'Clase de Química',
          temaCurricular:
              map['temaCurricular']?.toString() ?? 'Química General',
          ecuacion: map['ecuacion']?.toString() ?? '',
        );
      }).toList();

      classes.sort((a, b) => a.numeroClase.compareTo(b.numeroClase));
      return classes;
    } catch (_) {
      return List.generate(36, (i) {
        final int c = i + 1;
        final int t = c <= 12 ? 1 : (c <= 24 ? 2 : 3);
        return ClassSessionInfo(
          numeroClase: c,
          trimestre: t,
          titulo: 'Sesión de Química #$c',
          temaCurricular: 'Práctica de Laboratorio',
          ecuacion: '',
        );
      });
    }
  }

  Future<List<GameQuestion>> loadRandomQuestions(
    int classOrLevelNumber, {
    int limit = 10,
  }) async {
    try {
      final List<GameQuestion> pool = [];

      try {
        final String reacRaw =
            await rootBundle.loadString('assets/data/reactions.json');
        final List<dynamic> reacList = jsonDecode(reacRaw);

        Map<String, dynamic>? matchedReaction;
        for (final item in reacList) {
          if (item is Map) {
            final int numClase = (item['numeroClase'] as num?)?.toInt() ?? 0;
            if (numClase == classOrLevelNumber) {
              matchedReaction = Map<String, dynamic>.from(item);
              break;
            }
          }
        }

        if (matchedReaction != null) {
          final r = matchedReaction;
          final String tema = (r['temaCurricular'] ?? '').toString();
          final String energia = (r['energia'] ?? 'Exotérmica').toString();
          final String enlace = (r['tipoEnlace'] ?? 'covalente').toString();
          final String tipo = (r['tipo'] ?? 'Síntesis').toString();
          final List<String> elementos =
              List<String>.from(r['elementosRelacionados'] ?? []);

          if (tema.isNotEmpty) {
            pool.add(GameQuestion(
              question:
                  'En la Clase $classOrLevelNumber (${r['nombre']}), ¿a qué familia química pertenece la reacción ${r['ecuacion']}?',
              answer: tema,
            ));
          }
          pool.add(GameQuestion(
            question:
                '¿Qué comportamiento térmico tiene la reacción ${r['ecuacion']} (Exotérmica o Endotérmica)?',
            answer: energia,
          ));
          pool.add(GameQuestion(
            question:
                '¿Qué tipo de enlace químico predomina en ${r['nombre']} (iónico o covalente)?',
            answer: enlace,
          ));
          pool.add(GameQuestion(
            question:
                '¿Cuál es el tipo de reacción química de ${r['ecuacion']} (ej. Síntesis, Combustión, Descomposición, Ácido-Base)?',
            answer: tipo,
          ));
          if (elementos.isNotEmpty) {
            pool.add(GameQuestion(
              question:
                  'Escribe el símbolo químico del primer elemento principal involucrado en: ${r['ecuacion']}',
              answer: elementos.first,
            ));
          }
        }
      } catch (_) {}

      final int primaryLevel = ((classOrLevelNumber - 1) % 4) + 1;
      final List<int> levelOrder = [
        primaryLevel,
        for (int l = 1; l <= 4; l++)
          if (l != primaryLevel) l,
      ];

      for (final lvl in levelOrder) {
        try {
          final String response =
              await rootBundle.loadString('assets/data/games/level$lvl.json');
          final List<dynamic> data = jsonDecode(response);
          final List<GameQuestion> levelQuestions = data
              .map((item) =>
                  GameQuestion.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          levelQuestions.shuffle();
          pool.addAll(levelQuestions);
        } catch (_) {}
      }

      if (pool.isEmpty) return [];

      final List<GameQuestion> selected = pool.take(limit).toList();
      selected.shuffle();
      return selected;
    } catch (e) {
      return [];
    }
  }

  /// GENERADOR DE CÓDIGO/QR DE EVALUACIÓN SORPRESA (Exclusivo para el módulo Docente)
  String encodeSurpriseQuiz({
    required String examId,
    required String title,
    required int trimestre,
    required int numeroClase,
    required List<GameQuestion> questions,
  }) {
    final map = {
      'id': examId,
      't': title,
      'tr': trimestre,
      'c': numeroClase,
      'q': questions.map((q) => q.toJson()).toList(),
    };
    final base64Str = base64UrlEncode(utf8.encode(jsonEncode(map)));
    return 'CHEMIA-QUIZ:$base64Str';
  }

  /// DECODIFICA Y VALIDA ESTRICTAMENTE EL CÓDIGO DE EVALUACIÓN SORPRESA
  Map<String, dynamic>? decodeSurpriseQuiz(String rawToken) {
    try {
      String clean = rawToken.trim();
      if (!clean.startsWith('CHEMIA-QUIZ:')) {
        return null; // Rechaza cualquier texto que no sea un código oficial
      }
      clean = clean.replaceFirst('CHEMIA-QUIZ:', '').trim();
      if (clean.isEmpty) return null;

      final jsonStr = utf8.decode(base64Url.decode(clean));
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      final List<dynamic> rawQ = map['q'] ?? map['questions'] ?? [];
      final List<GameQuestion> questions = rawQ
          .map((q) => GameQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
          .toList();

      if (questions.isEmpty) return null;
      return {
        'id': (map['id'] ?? 'QUIZ-DEFAULT').toString(),
        'title': (map['t'] ?? map['title'] ?? 'Evaluación Sorpresa').toString(),
        'trimestre': (map['tr'] ?? map['trimestre'] as num?)?.toInt() ?? 1,
        'numeroClase': (map['c'] as num?)?.toInt() ?? 1,
        'questions': questions,
      };
    } catch (_) {
      return null;
    }
  }
}