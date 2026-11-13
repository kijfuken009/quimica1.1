import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/game_service.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../widgets/qr_scanner_screen.dart';
import '../teacher/teacher_exam_builder_screen.dart';
import 'game_level_screen.dart';

class GamesMenuScreen extends StatefulWidget {
  const GamesMenuScreen({super.key});

  @override
  State<GamesMenuScreen> createState() => _GamesMenuScreenState();
}

class _GamesMenuScreenState extends State<GamesMenuScreen> {
  final GameService _gameService = GameService();
  List<ClassSessionInfo> _allClasses = [];
  int _selectedTrimestre = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final list = await _gameService.loadCurriculumClasses();
    if (!mounted) return;
    setState(() {
      _allClasses = list;
      _loading = false;
    });
  }

  /// Modal que muestra las Evaluaciones Sorpresa del Docente en el trimestre seleccionado
  void _showSurpriseEvaluationsHistoryModal(
    BuildContext context,
    UserProvider userProv,
    TeacherProvider teacherProv,
  ) {
    final allSurprise = userProv.user?.surpriseExams ?? [];
    final trimSurprises = allSurprise.where((item) {
      if (item is Map) {
        return (item['trimestre'] as num?)?.toInt() == _selectedTrimestre;
      }
      return false;
    }).toList();

    double avgSurprise = 0.0;
    if (trimSurprises.isNotEmpty) {
      int sum = 0;
      for (final s in trimSurprises) {
        sum += ((s as Map)['score'] as num?)?.toInt() ?? 0;
      }
      avgSurprise = sum / trimSurprises.length;
    }

    final teacherCreatedForTrim = teacherProv.createdExams
        .where((e) => e.trimestre == _selectedTrimestre)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "⚡ Evaluaciones Sorpresa ($_selectedTrimestre.º Trim.)",
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 310,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Promedio en Evaluaciones Sorpresa",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${avgSurprise.toStringAsFixed(1)} / 100 pts",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                      Text(
                        "Evaluaciones rendidas: ${trimSurprises.length}",
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (trimSurprises.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "Aún no has rendido evaluaciones sorpresa en este trimestre.\nCuando tu docente proyecte un QR en aula, escanéalo con el botón 'Evaluación Sorpresa'.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  )
                else
                  ...trimSurprises.map((item) {
                    final map = Map<String, dynamic>.from(item as Map);
                    final int sc = (map['score'] as num?)?.toInt() ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: sc >= 60
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.bolt,
                            color: sc >= 60
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                        title: Text(
                          (map['title'] ?? 'Evaluación Sorpresa').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Fecha: ${map['date'] ?? '-'}"),
                        trailing: Text(
                          "$sc / 100",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: sc >= 60
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                    );
                  }),
                if (teacherProv.isTeacherMode) ...[
                  const Divider(height: 22),
                  Text(
                    "👨‍🏫 QRs Creados por el Docente (${teacherCreatedForTrim.length}):",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherExamBuilderScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text(
                        "Abrir Mis Evaluaciones Sorpresa (Docente)"),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showSurpriseExamModal(context, userProv);
            },
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text("Escanear Nueva"),
          ),
        ],
      ),
    );
  }

  /// Modal con Código QR para que el Docente lo escanee y registre notas automáticamente
  void _showShareGradesQrModal(BuildContext context, UserProvider userProv) {
    final qrPayload = userProv.generateStudentQrPayload();
    final user = userProv.user;
    final avg = userProv.getTrimestreAverage(_selectedTrimestre);
    final completed =
        userProv.getCompletedClassesInTrimestre(_selectedTrimestre);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "📲 Registro QR ($_selectedTrimestre.º Trimestre)",
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Estudiante: ${user?.name ?? 'Estudiante'}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Promedio: ${avg.toStringAsFixed(1)} / 100 pts • Clases: $completed/12",
                  style: const TextStyle(fontSize: 12.5, color: Colors.indigo),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Muestra este código QR al dispositivo de tu docente para que tus calificaciones, asistencia y promedios se anoten automáticamente en su registro:",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 14),
                if (qrPayload.isNotEmpty)
                  Center(
                    child: Container(
                      width: 224,
                      height: 224,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.indigo.withValues(alpha: 0.3),
                            width: 2),
                      ),
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  /// Modal de Respaldo y Recuperación 100% por Código QR y Cámara
  void _showBackupRestoreModal(BuildContext context, UserProvider userProv) {
    final qrPayload = userProv.generateStudentQrPayload();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "☁️ Respaldo y Recuperación QR",
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "1. Mi QR de Respaldo Estudiantil:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Cuando tu docente escanea este QR en clase, tu progreso queda respaldado automáticamente en su registro:",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (qrPayload.isNotEmpty)
                    Center(
                      child: Container(
                        width: 186,
                        height: 186,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: QrImageView(
                          data: qrPayload,
                          version: QrVersions.auto,
                          size: 166,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  const Divider(height: 26),
                  const Text(
                    "2. Recuperar Progreso desde el Docente:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Si reinstalaste la aplicación o cambiaste de teléfono, escanea el código QR de recuperación que te mostrará tu docente:",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      final scannedRaw = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QrScannerScreen(
                            title: 'Escanear QR de Recuperación',
                            subtitle:
                                'Apunta al código QR de respaldo en el dispositivo del docente',
                          ),
                        ),
                      );

                      if (!ctx.mounted) return;
                      if (scannedRaw != null && scannedRaw.isNotEmpty) {
                        final ok =
                            await userProv.restoreFromQrOrToken(scannedRaw);
                        if (!ctx.mounted) return;
                        if (ok) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "🎉 ¡Progreso y calificaciones restaurados por QR con éxito!"),
                            ),
                          );
                        } else {
                          setModalState(() {
                            errorMsg =
                                "❌ El código QR escaneado no corresponde a un respaldo válido de ChemIA.";
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("Escanear QR del Docente"),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMsg!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar"),
            ),
          ],
        ),
      ),
    );
  }

  /// Modal de Evaluación Sorpresa 100% por Cámara QR (Muestra error en rojo o calificación previa si ya fue usada)
  void _showSurpriseExamModal(BuildContext context, UserProvider userProv) {
    String? redErrorText;
    Map<String, dynamic>? previousExamResult;

    void validateAndLaunch(
      String rawCode,
      BuildContext modalCtx,
      void Function(void Function()) setModalState,
    ) {
      setModalState(() {
        redErrorText = null;
        previousExamResult = null;
      });

      final decoded = _gameService.decodeSurpriseQuiz(rawCode);
      if (decoded == null) {
        setModalState(() {
          redErrorText =
              "❌ El código QR escaneado no corresponde a una evaluación sorpresa válida.";
        });
        return;
      }

      final String examId = decoded['id'] as String;
      final pastAttempt = userProv.findCompletedSurpriseExam(examId);
      if (pastAttempt != null) {
        setModalState(() {
          previousExamResult = pastAttempt;
          redErrorText =
              "ℹ️ Esta evaluación sorpresa ya fue resuelta anteriormente.";
        });
        return;
      }

      final String title = decoded['title'] as String;
      final int trim = decoded['trimestre'] as int;
      final List<GameQuestion> questions =
          decoded['questions'] as List<GameQuestion>;

      Navigator.pop(modalCtx);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameLevelScreen(
            gameTitle: title,
            levelNumber: 0,
            trimestre: trim,
            questions: questions,
            isSurpriseExam: true,
            surpriseExamId: examId,
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "⚡ Evaluación Sorpresa",
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Escanea con la cámara el código QR de la evaluación sorpresa generado por tu docente en el aula (10 preguntas • Sin límite de tiempo):",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final scanned = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QrScannerScreen(
                            title: 'Escanear Evaluación Sorpresa',
                            subtitle:
                                'Apunta al código QR de la evaluación en el dispositivo del docente',
                          ),
                        ),
                      );
                      if (!ctx.mounted) return;
                      if (scanned != null && scanned.isNotEmpty) {
                        validateAndLaunch(scanned, ctx, setModalState);
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 22),
                    label: const Text("Escanear QR de Evaluación"),
                  ),
                  if (redErrorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      redErrorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  if (previousExamResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "📋 Resultado de tu Evaluación Pasada",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[900],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              "Estudiante: ${userProv.user?.name ?? 'Estudiante'}"),
                          Text("Evaluación: ${previousExamResult!['title']}"),
                          Text(
                              "Trimestre: ${previousExamResult!['trimestre']}.º Trimestre"),
                          Text("Fecha: ${previousExamResult!['date']}"),
                          const SizedBox(height: 4),
                          Text(
                            "Calificación Obtenida: ${previousExamResult!['score']} / 100 pts",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cerrar"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final teacherProv = Provider.of<TeacherProvider>(context);
    final user = userProv.user;
    final trimestreClasses = _allClasses
        .where((c) => c.trimestre == _selectedTrimestre)
        .toList();
    final promedioTrim = userProv.getTrimestreAverage(_selectedTrimestre);
    final completadas =
        userProv.getCompletedClassesInTrimestre(_selectedTrimestre);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Evaluación por Trimestres"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text("Promedio Trimestral",
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          "${promedioTrim.toStringAsFixed(0)} / 100",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: Colors.black12),
                    Column(
                      children: [
                        const Text("Clases Evaluadas",
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          "$completadas / 12",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Container(height: 36, width: 1, color: Colors.black12),
                    Column(
                      children: [
                        const Text("Puntos Globales",
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          "${user?.totalPoints ?? 0} pts",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          _showSurpriseExamModal(context, userProv),
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text("Evaluación Sorpresa"),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          _showShareGradesQrModal(context, userProv),
                      icon: const Icon(Icons.qr_code_2, size: 18),
                      label: const Text("QR para Docente"),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _showBackupRestoreModal(context, userProv),
                      icon: const Icon(Icons.restore, size: 17),
                      label: const Text("Respaldo QR"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text("1.º Trimestre")),
                    ButtonSegment(value: 2, label: Text("2.º Trimestre")),
                    ButtonSegment(value: 3, label: Text("3.º Trimestre")),
                  ],
                  selected: {_selectedTrimestre},
                  onSelectionChanged: (sel) {
                    setState(() => _selectedTrimestre = sel.first);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo[900],
                    backgroundColor: Colors.amber.withValues(alpha: 0.12),
                    side: BorderSide(color: Colors.amber.shade700, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _showSurpriseEvaluationsHistoryModal(
                    context,
                    userProv,
                    teacherProv,
                  ),
                  icon: Icon(Icons.bolt, color: Colors.amber[900], size: 20),
                  label: Text(
                    "Evaluaciones Sorpresa del Docente ($_selectedTrimestre.º Trimestre)",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trimestreClasses.length,
                    itemBuilder: (context, index) {
                      final cls = trimestreClasses[index];
                      return _buildClassEvaluationCard(context, cls, userProv);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassEvaluationCard(
    BuildContext context,
    ClassSessionInfo cls,
    UserProvider userProv,
  ) {
    final user = userProv.user;
    final int unlocked = user?.unlockedLevel ?? 1;
    final bool isUnlocked = unlocked >= cls.numeroClase;
    final int? savedGrade = user?.classScores[cls.numeroClase];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnlocked ? 2 : 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: savedGrade != null
              ? Colors.green.withValues(alpha: 0.18)
              : (isUnlocked
                  ? Colors.indigo.withValues(alpha: 0.15)
                  : Colors.grey[300]),
          child: Text(
            "C${cls.numeroClase}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: savedGrade != null
                  ? Colors.green[800]
                  : (isUnlocked ? Colors.indigo : Colors.grey[600]),
            ),
          ),
        ),
        title: Text(
          "Clase ${cls.numeroClase}: ${cls.titulo}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.5,
            color: isUnlocked ? null : Colors.grey[600],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "${cls.temaCurricular} • ${cls.ecuacion}\n10 preguntas • 30s por pregunta",
            style: const TextStyle(fontSize: 12),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (savedGrade != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: savedGrade >= 60
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$savedGrade/100",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: savedGrade >= 60
                        ? Colors.green[800]
                        : Colors.orange[800],
                  ),
                ),
              )
            else
              Icon(
                isUnlocked ? Icons.play_circle_fill : Icons.lock_outline,
                color: isUnlocked ? Colors.indigo : Colors.grey,
                size: 28,
              ),
          ],
        ),
        onTap: isUnlocked
            ? () async {
                final questions = await _gameService.loadRandomQuestions(
                  cls.numeroClase,
                  limit: 10,
                );

                if (questions.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Error al cargar las 10 preguntas de la clase")),
                  );
                  return;
                }

                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameLevelScreen(
                      gameTitle: "Clase ${cls.numeroClase}: ${cls.titulo}",
                      levelNumber: cls.numeroClase,
                      trimestre: cls.trimestre,
                      questions: questions,
                      isSurpriseExam: false,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}