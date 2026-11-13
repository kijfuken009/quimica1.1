import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_service.dart';

class TeacherStudentRecord {
  final String name;
  final int age;
  final int chemistryLevel;
  final int totalPoints;
  final int unlockedLevel;
  final Map<int, int> classScores;
  final List<dynamic> surpriseExams;
  final String observations;
  final String lastSyncDate;

  TeacherStudentRecord({
    required this.name,
    required this.age,
    required this.chemistryLevel,
    required this.totalPoints,
    required this.unlockedLevel,
    required this.classScores,
    required this.surpriseExams,
    this.observations = '',
    required this.lastSyncDate,
  });

  /// Promedio únicamente de las 12 clases regulares del trimestre (1, 2 o 3)
  double getRegularClassAverage(int trimestre) {
    final int start = (trimestre - 1) * 12 + 1;
    final int end = trimestre * 12;
    int sum = 0;
    int count = 0;
    for (int c = start; c <= end; c++) {
      if (classScores.containsKey(c)) {
        sum += classScores[c]!;
        count++;
      }
    }
    return count == 0 ? 0.0 : sum / count;
  }

  /// Cantidad de clases completadas en el trimestre (sobre 12)
  int getCompletedClassesCount(int trimestre) {
    final int start = (trimestre - 1) * 12 + 1;
    final int end = trimestre * 12;
    int count = 0;
    for (int c = start; c <= end; c++) {
      if (classScores.containsKey(c)) count++;
    }
    return count;
  }

  /// Promedio únicamente de las Evaluaciones Sorpresa del trimestre
  double getSurpriseExamAverage(int trimestre) {
    int sum = 0;
    int count = 0;
    for (final item in surpriseExams) {
      if (item is Map && (item['trimestre'] as num?)?.toInt() == trimestre) {
        sum += (item['score'] as num?)?.toInt() ?? 0;
        count++;
      }
    }
    return count == 0 ? 0.0 : sum / count;
  }

  /// Cantidad de Evaluaciones Sorpresa rendidas en el trimestre
  int getSurpriseExamCount(int trimestre) {
    int count = 0;
    for (final item in surpriseExams) {
      if (item is Map && (item['trimestre'] as num?)?.toInt() == trimestre) {
        count++;
      }
    }
    return count;
  }

  /// Promedio Final Evaluativo y Comparativo del Trimestre (Clases + Sorpresas)
  double getFinalTrimestreAverage(int trimestre) {
    final int start = (trimestre - 1) * 12 + 1;
    final int end = trimestre * 12;
    int sum = 0;
    int count = 0;
    for (int c = start; c <= end; c++) {
      if (classScores.containsKey(c)) {
        sum += classScores[c]!;
        count++;
      }
    }
    for (final item in surpriseExams) {
      if (item is Map && (item['trimestre'] as num?)?.toInt() == trimestre) {
        sum += (item['score'] as num?)?.toInt() ?? 0;
        count++;
      }
    }
    return count == 0 ? 0.0 : sum / count;
  }

  /// Genera el QR de Recuperación para que el estudiante restaure su progreso desde la pizarra del docente
  String toStudentRecoveryQrPayload() {
    final compactMap = {
      'n': name,
      'a': age,
      'l': chemistryLevel,
      'p': totalPoints,
      'u': unlockedLevel,
      'cs': classScores.map((k, v) => MapEntry(k.toString(), v)),
      'se': surpriseExams,
      't1': double.parse(getFinalTrimestreAverage(1).toStringAsFixed(1)),
      't2': double.parse(getFinalTrimestreAverage(2).toStringAsFixed(1)),
      't3': double.parse(getFinalTrimestreAverage(3).toStringAsFixed(1)),
    };
    final encoded = base64UrlEncode(utf8.encode(jsonEncode(compactMap)));
    return 'CHEMIA-SYNC:$encoded';
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'chemistryLevel': chemistryLevel,
        'totalPoints': totalPoints,
        'unlockedLevel': unlockedLevel,
        'classScores': classScores.map((k, v) => MapEntry(k.toString(), v)),
        'surpriseExams': surpriseExams,
        'observations': observations,
        'lastSyncDate': lastSyncDate,
      };

  factory TeacherStudentRecord.fromJson(Map<String, dynamic> json) {
    final rawScores = json['classScores'] as Map<String, dynamic>? ?? {};
    final Map<int, int> parsedScores = {};
    rawScores.forEach((k, v) {
      final keyInt = int.tryParse(k);
      if (keyInt != null) {
        parsedScores[keyInt] = (v as num?)?.toInt() ?? 0;
      }
    });

    return TeacherStudentRecord(
      name: (json['name'] ?? 'Estudiante').toString(),
      age: (json['age'] as num?)?.toInt() ?? 12,
      chemistryLevel: (json['chemistryLevel'] as num?)?.toInt() ?? 1,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      unlockedLevel: (json['unlockedLevel'] as num?)?.toInt() ?? 1,
      classScores: parsedScores,
      surpriseExams: List<dynamic>.from(json['surpriseExams'] ?? []),
      observations: (json['observations'] ?? '').toString(),
      lastSyncDate: (json['lastSyncDate'] ?? '').toString(),
    );
  }

  TeacherStudentRecord copyWith({
    String? observations,
    List<dynamic>? surpriseExams,
  }) {
    return TeacherStudentRecord(
      name: name,
      age: age,
      chemistryLevel: chemistryLevel,
      totalPoints: totalPoints,
      unlockedLevel: unlockedLevel,
      classScores: classScores,
      surpriseExams: surpriseExams ?? this.surpriseExams,
      observations: observations ?? this.observations,
      lastSyncDate: lastSyncDate,
    );
  }
}

class CreatedSurpriseExam {
  final String id;
  final String title;
  final int trimestre;
  final int numeroClase;
  final String createdAt;
  final List<GameQuestion> questions;
  final String qrPayload;

  CreatedSurpriseExam({
    required this.id,
    required this.title,
    required this.trimestre,
    required this.numeroClase,
    required this.createdAt,
    required this.questions,
    required this.qrPayload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'trimestre': trimestre,
        'numeroClase': numeroClase,
        'createdAt': createdAt,
        'questions': questions.map((q) => q.toJson()).toList(),
        'qrPayload': qrPayload,
      };

  factory CreatedSurpriseExam.fromJson(Map<String, dynamic> json) {
    final rawQ = List<dynamic>.from(json['questions'] ?? []);
    return CreatedSurpriseExam(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Evaluación Sorpresa').toString(),
      trimestre: (json['trimestre'] as num?)?.toInt() ?? 1,
      numeroClase: (json['numeroClase'] as num?)?.toInt() ?? 1,
      createdAt: (json['createdAt'] ?? '').toString(),
      questions: rawQ
          .map((e) => GameQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      qrPayload: (json['qrPayload'] ?? '').toString(),
    );
  }
}

class TeacherProvider with ChangeNotifier {
  bool _isTeacherMode = false;
  String _teacherName = '';
  String _teacherGoogleEmail = '';
  List<TeacherStudentRecord> _students = [];
  List<CreatedSurpriseExam> _createdExams = [];

  bool get isTeacherMode => _isTeacherMode;
  String get teacherName => _teacherName;
  String get teacherGoogleEmail => _teacherGoogleEmail;
  List<TeacherStudentRecord> get students => _students;
  List<CreatedSurpriseExam> get createdExams => _createdExams;

  Future<void> loadTeacherData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('teacher_master_data');
    if (raw != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(raw);
        _teacherName = (map['teacherName'] ?? '').toString();
        _teacherGoogleEmail = (map['teacherGoogleEmail'] ?? '').toString();
        _isTeacherMode = map['isTeacherMode'] == true;

        final rawStudents = List<dynamic>.from(map['students'] ?? []);
        _students = rawStudents
            .map((e) => TeacherStudentRecord.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();

        final rawExams = List<dynamic>.from(map['createdExams'] ?? []);
        _createdExams = rawExams
            .map((e) => CreatedSurpriseExam.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'teacherName': _teacherName,
      'teacherGoogleEmail': _teacherGoogleEmail,
      'isTeacherMode': _isTeacherMode,
      'students': _students.map((s) => s.toJson()).toList(),
      'createdExams': _createdExams.map((e) => e.toJson()).toList(),
    };
    await prefs.setString('teacher_master_data', jsonEncode(map));

    // Sincroniza automáticamente bajo la cuenta de Gmail del docente
    if (_teacherGoogleEmail.isNotEmpty) {
      final cleanEmail = _teacherGoogleEmail.trim().toLowerCase();
      final cloudPayload = jsonEncode({
        'teacherName': _teacherName,
        'teacherGoogleEmail': cleanEmail,
        'lastCloudSync': DateTime.now().toIso8601String(),
        'students': _students.map((s) => s.toJson()).toList(),
        'createdExams': _createdExams.map((e) => e.toJson()).toList(),
      });
      await prefs.setString('gdrive_sync_$cleanEmail', cloudPayload);
    }

    notifyListeners();
  }

  /// Registra al docente desde la pantalla de bienvenida con su Nombre y Cuenta Gmail
  Future<void> registerTeacher({
    required String name,
    required String googleEmail,
  }) async {
    await registerOrSyncWithGmail(name: name, googleEmail: googleEmail);
  }

  /// Registra o recupera automáticamente los datos del docente usando su cuenta Gmail verificada
  Future<bool> registerOrSyncWithGmail({
    required String name,
    required String googleEmail,
  }) async {
    final cleanEmail = googleEmail.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();

    final cloudKey = 'gdrive_sync_$cleanEmail';
    final existingCloudData = prefs.getString(cloudKey);

    _teacherName = name.trim();
    _teacherGoogleEmail = cleanEmail;
    _isTeacherMode = true;

    if (existingCloudData != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(existingCloudData);
        if ((map['teacherName'] ?? '').toString().isNotEmpty) {
          _teacherName = map['teacherName'].toString();
        }
        final rawStudents = List<dynamic>.from(map['students'] ?? []);
        _students = rawStudents
            .map((e) => TeacherStudentRecord.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();

        final rawExams = List<dynamic>.from(map['createdExams'] ?? []);
        _createdExams = rawExams
            .map((e) => CreatedSurpriseExam.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }

    await _persist();
    return existingCloudData != null;
  }

  /// Sincroniza automáticamente la pizarra y los QRs con el correo Gmail del docente
  Future<void> syncToGoogleAccount() async {
    await _persist();
  }

  Future<void> updateTeacherProfile({
    required String name,
    required String googleEmail,
  }) async {
    _teacherName = name.trim();
    _teacherGoogleEmail = googleEmail.trim().toLowerCase();
    await _persist();
  }

  /// Registra o actualiza automáticamente a un alumno al escanear su QR CHEMIA-SYNC
  Future<TeacherStudentRecord?> syncStudentFromQr(String rawQr) async {
    try {
      String clean = rawQr.trim();
      if (!clean.startsWith('CHEMIA-SYNC:')) return null;
      clean = clean.replaceFirst('CHEMIA-SYNC:', '').trim();

      final decodedStr = utf8.decode(base64Url.decode(clean));
      final Map<String, dynamic> m = jsonDecode(decodedStr);

      final String studentName = (m['n'] ?? 'Estudiante').toString().trim();
      final int age = (m['a'] as num?)?.toInt() ?? 12;
      final int level = (m['l'] as num?)?.toInt() ?? 1;
      final int points = (m['p'] as num?)?.toInt() ?? 0;
      final int unlocked = (m['u'] as num?)?.toInt() ?? 1;

      final rawCs = m['cs'] as Map<String, dynamic>? ?? {};
      final Map<int, int> parsedScores = {};
      rawCs.forEach((k, v) {
        final keyInt = int.tryParse(k);
        if (keyInt != null) {
          parsedScores[keyInt] = (v as num?)?.toInt() ?? 0;
        }
      });

      final List<dynamic> parsedSurprise = List<dynamic>.from(m['se'] ?? []);
      final String today = DateTime.now().toIso8601String().split('T').first;

      final existingIndex = _students.indexWhere(
        (s) => s.name.toLowerCase() == studentName.toLowerCase(),
      );

      String autoObservation = '';
      final tempRecord = TeacherStudentRecord(
        name: studentName,
        age: age,
        chemistryLevel: level,
        totalPoints: points,
        unlockedLevel: unlocked,
        classScores: parsedScores,
        surpriseExams: parsedSurprise,
        lastSyncDate: today,
      );

      final double avgT1 = tempRecord.getFinalTrimestreAverage(1);
      if (avgT1 >= 85) {
        autoObservation = 'Rendimiento destacado';
      } else if (avgT1 >= 60) {
        autoObservation = 'Aprobado - Avance regular';
      } else if (parsedScores.isNotEmpty) {
        autoObservation = 'Requiere apoyo pedagógico';
      }

      late TeacherStudentRecord savedRecord;
      if (existingIndex >= 0) {
        final prevObs = _students[existingIndex].observations;
        savedRecord = TeacherStudentRecord(
          name: studentName,
          age: age,
          chemistryLevel: level,
          totalPoints: points,
          unlockedLevel: unlocked,
          classScores: parsedScores,
          surpriseExams: parsedSurprise,
          observations: prevObs.isNotEmpty ? prevObs : autoObservation,
          lastSyncDate: today,
        );
        _students[existingIndex] = savedRecord;
      } else {
        savedRecord = TeacherStudentRecord(
          name: studentName,
          age: age,
          chemistryLevel: level,
          totalPoints: points,
          unlockedLevel: unlocked,
          classScores: parsedScores,
          surpriseExams: parsedSurprise,
          observations: autoObservation,
          lastSyncDate: today,
        );
        _students.add(savedRecord);
      }

      _students
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await _persist();
      return savedRecord;
    } catch (_) {
      return null;
    }
  }

  /// Permite al docente anotar observaciones o agregar una nota manual de Evaluación Sorpresa
  Future<void> updateStudentObservationsAndManualGrade({
    required String studentName,
    required String observations,
    int? manualSurpriseScore,
    int? trimestreForManualScore,
    String? manualSurpriseTitle,
  }) async {
    final idx = _students.indexWhere(
        (s) => s.name.toLowerCase() == studentName.toLowerCase());
    if (idx < 0) return;

    final current = _students[idx];
    final List<dynamic> updatedSurprises =
        List<dynamic>.from(current.surpriseExams);

    if (manualSurpriseScore != null && trimestreForManualScore != null) {
      updatedSurprises.insert(0, {
        'id': 'MANUAL-${DateTime.now().millisecondsSinceEpoch}',
        'title':
            (manualSurpriseTitle == null || manualSurpriseTitle.trim().isEmpty)
                ? 'Eval. Sorpresa en Aula'
                : manualSurpriseTitle.trim(),
        'trimestre': trimestreForManualScore,
        'score': manualSurpriseScore.clamp(0, 100),
        'date': DateTime.now().toIso8601String().split('T').first,
      });
    }

    _students[idx] = current.copyWith(
      observations: observations.trim(),
      surpriseExams: updatedSurprises,
    );
    await _persist();
  }

  Future<void> removeStudent(String studentName) async {
    _students
        .removeWhere((s) => s.name.toLowerCase() == studentName.toLowerCase());
    await _persist();
  }

  /// Guarda una nueva Evaluación Sorpresa en la biblioteca del Docente
  Future<CreatedSurpriseExam> saveCreatedSurpriseExam({
    required String title,
    required int trimestre,
    required int numeroClase,
    required List<GameQuestion> questions,
    required GameService gameService,
  }) async {
    final String examId =
        'EX-T$trimestre-C$numeroClase-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final String qrPayload = gameService.encodeSurpriseQuiz(
      examId: examId,
      title: title,
      trimestre: trimestre,
      numeroClase: numeroClase,
      questions: questions,
    );

    final exam = CreatedSurpriseExam(
      id: examId,
      title: title,
      trimestre: trimestre,
      numeroClase: numeroClase,
      createdAt: DateTime.now().toIso8601String().split('T').first,
      questions: questions,
      qrPayload: qrPayload,
    );

    _createdExams.insert(0, exam);
    await _persist();
    return exam;
  }

  Future<void> deleteCreatedExam(String id) async {
    _createdExams.removeWhere((e) => e.id == id);
    await _persist();
  }
}