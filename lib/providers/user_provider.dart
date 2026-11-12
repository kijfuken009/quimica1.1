import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('user_data');

    if (userData != null) {
      _user = UserModel.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> saveUser(String name, int age) async {
    _user = UserModel(
      name: name,
      age: age,
      chemistryLevel: 1,
      totalPoints: 0,
      unlockedLevel: 1,
      classScores: {},
      surpriseExams: [],
    );
    await _persist();
  }

  /// Verifica si una evaluación sorpresa (por examId) ya fue rendida por el estudiante
  Map<String, dynamic>? findCompletedSurpriseExam(String examId) {
    if (_user == null || examId.trim().isEmpty) return null;
    for (final item in _user!.surpriseExams) {
      if (item is Map && item['id']?.toString() == examId.trim()) {
        return Map<String, dynamic>.from(item);
      }
    }
    return null;
  }

  Future<void> addPointsAndUnlockLevel({
    required int pointsWon,
    required int completedLevel,
    required bool passed,
    int? scoreOn100,
    bool isSurpriseExam = false,
    String surpriseExamId = '',
    String surpriseTitle = '',
    int trimestre = 1,
  }) async {
    if (_user == null) return;

    final int calculatedGrade = scoreOn100 ?? pointsWon;

    if (isSurpriseExam) {
      final List<dynamic> updatedSurprise =
          List<dynamic>.from(_user!.surpriseExams);

      // Evita duplicar si el examId ya existe
      if (surpriseExamId.isNotEmpty) {
        updatedSurprise.removeWhere(
          (e) => e is Map && e['id']?.toString() == surpriseExamId,
        );
      }

      updatedSurprise.insert(0, {
        'id': surpriseExamId.isEmpty
            ? 'EX-${DateTime.now().millisecondsSinceEpoch}'
            : surpriseExamId,
        'title': surpriseTitle.isEmpty ? 'Evaluación Sorpresa' : surpriseTitle,
        'trimestre': trimestre,
        'score': calculatedGrade,
        'date': DateTime.now().toIso8601String().split('T').first,
      });

      _user = _user!.copyWith(
        totalPoints: _user!.totalPoints + pointsWon,
        surpriseExams: updatedSurprise,
      );
      await _persist();
      return;
    }

    int newUnlockedLevel = _user!.unlockedLevel;
    // Desbloqueo estrictamente secuencial de la Clase 1 a la 36
    if (passed && _user!.unlockedLevel == completedLevel && completedLevel < 36) {
      newUnlockedLevel = completedLevel + 1;
    }

    final Map<int, int> updatedScores = Map<int, int>.from(_user!.classScores);
    final int prevBest = updatedScores[completedLevel] ?? 0;
    if (calculatedGrade >= prevBest) {
      updatedScores[completedLevel] = calculatedGrade;
    }

    final int newChemLevel =
        newUnlockedLevel > 24 ? 3 : (newUnlockedLevel > 12 ? 2 : 1);

    _user = _user!.copyWith(
      totalPoints: _user!.totalPoints + pointsWon,
      unlockedLevel: newUnlockedLevel,
      chemistryLevel: newChemLevel,
      classScores: updatedScores,
    );

    await _persist();
  }

  double getTrimestreAverage(int trimestre) {
    if (_user == null) return 0.0;
    final int startClass = (trimestre - 1) * 12 + 1;
    final int endClass = trimestre * 12;

    int sum = 0;
    int count = 0;
    for (int c = startClass; c <= endClass; c++) {
      if (_user!.classScores.containsKey(c)) {
        sum += _user!.classScores[c]!;
        count++;
      }
    }

    for (final item in _user!.surpriseExams) {
      if (item is Map && (item['trimestre'] as num?)?.toInt() == trimestre) {
        sum += (item['score'] as num?)?.toInt() ?? 0;
        count++;
      }
    }

    if (count == 0) return 0.0;
    return sum / count;
  }

  int getCompletedClassesInTrimestre(int trimestre) {
    if (_user == null) return 0;
    final int startClass = (trimestre - 1) * 12 + 1;
    final int endClass = trimestre * 12;
    int count = 0;
    for (int c = startClass; c <= endClass; c++) {
      if (_user!.classScores.containsKey(c)) count++;
    }
    return count;
  }

  /// GENERA EL QR COMPACTO UNIFICADO (Sirve para que el Docente escanee y registre
  /// al alumno automáticamente, y sirve como QR de Respaldo/Recuperación)
  String generateStudentQrPayload() {
    final u = _user;
    if (u == null) return '';

    final compactMap = {
      'n': u.name,
      'a': u.age,
      'l': u.chemistryLevel,
      'p': u.totalPoints,
      'u': u.unlockedLevel,
      'cs': u.classScores.map((k, v) => MapEntry(k.toString(), v)),
      'se': u.surpriseExams,
      't1': double.parse(getTrimestreAverage(1).toStringAsFixed(1)),
      't2': double.parse(getTrimestreAverage(2).toStringAsFixed(1)),
      't3': double.parse(getTrimestreAverage(3).toStringAsFixed(1)),
    };

    final encoded = base64UrlEncode(utf8.encode(jsonEncode(compactMap)));
    return 'CHEMIA-SYNC:$encoded';
  }

  /// RESTAURA EL PROGRESO DESDE EL QR DEL DOCENTE O DEL RESPALDO ESTUDIANTIL
  Future<bool> restoreFromQrOrToken(String rawInput) async {
    try {
      String clean = rawInput.trim();
      if (clean.contains('CHEMIA-SYNC:')) {
        clean = clean.split('CHEMIA-SYNC:').last.trim();
        final decodedStr = utf8.decode(base64Url.decode(clean));
        final Map<String, dynamic> m = jsonDecode(decodedStr);

        final Map<String, dynamic> fullJson = {
          'name': m['n'] ?? 'Estudiante',
          'age': m['a'] ?? 12,
          'level': m['l'] ?? 1,
          'points': m['p'] ?? 0,
          'unlockedLevel': m['u'] ?? 1,
          'classScores': m['cs'] ?? {},
          'surpriseExams': m['se'] ?? [],
        };
        _user = UserModel.fromJson(fullJson);
        await _persist();
        return true;
      }

      if (clean.contains('CHEMIA-BACKUP:')) {
        clean = clean.split('CHEMIA-BACKUP:').last.trim();
      }
      final decodedStr = utf8.decode(base64Url.decode(clean));
      final Map<String, dynamic> map = jsonDecode(decodedStr);
      _user = UserModel.fromJson(map);
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateNickname(String newName) async {
    if (_user != null) {
      _user = _user!.copyWith(name: newName);
      await _persist();
    }
  }

  Future<void> clearUser() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }
}