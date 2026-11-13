import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/teacher_provider.dart';
import '../../../services/game_service.dart';

class TeacherExamBuilderScreen extends StatefulWidget {
  const TeacherExamBuilderScreen({super.key});

  @override
  State<TeacherExamBuilderScreen> createState() =>
      _TeacherExamBuilderScreenState();
}

class _TeacherExamBuilderScreenState extends State<TeacherExamBuilderScreen> {
  final GameService _gameService = GameService();
  final TextEditingController _examTitleCtrl =
      TextEditingController(text: 'Evaluación Sorpresa de Aula');
  final TextEditingController _manualQuestionCtrl = TextEditingController();
  final TextEditingController _manualAnswerCtrl = TextEditingController();

  List<ClassSessionInfo> _classes = [];
  int _selectedClassNumber = 1;
  int _selectedTrimestre = 1;
  List<GameQuestion> _draftQuestions = [];

  @override
  void initState() {
    super.initState();
    _initClasses();
  }

  @override
  void dispose() {
    _examTitleCtrl.dispose();
    _manualQuestionCtrl.dispose();
    _manualAnswerCtrl.dispose();
    super.dispose();
  }

  Future<void> _initClasses() async {
    final list = await _gameService.loadCurriculumClasses();
    if (!mounted) return;
    setState(() {
      _classes = list;
    });
    await _loadQuestionsFromSelectedClass();
  }

  Future<void> _loadQuestionsFromSelectedClass() async {
    final q = await _gameService.loadRandomQuestions(
      _selectedClassNumber,
      limit: 10,
    );
    if (!mounted) return;
    final clsInfo = _classes
        .where((c) => c.numeroClase == _selectedClassNumber)
        .firstOrNull;
    setState(() {
      _draftQuestions = List<GameQuestion>.from(q);
      if (clsInfo != null) {
        _selectedTrimestre = clsInfo.trimestre;
        _examTitleCtrl.text =
            'Sorpresa C${clsInfo.numeroClase}: ${clsInfo.titulo}';
      }
    });
  }

  void _addManualQuestion() {
    final qText = _manualQuestionCtrl.text.trim();
    final aText = _manualAnswerCtrl.text.trim();
    if (qText.isEmpty || aText.isEmpty) return;

    setState(() {
      _draftQuestions.insert(0, GameQuestion(question: qText, answer: aText));
      _manualQuestionCtrl.clear();
      _manualAnswerCtrl.clear();
    });
  }

  void _showExamQrDialog(BuildContext context, CreatedSurpriseExam exam) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '⚡ ${exam.title}',
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${exam.trimestre}.º Trimestre • Clase ${exam.numeroClase} • ${exam.questions.length} preguntas',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Muestra este código QR a tus estudiantes para que inicien la Evaluación Sorpresa desde su cámara:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 224,
                    height: 224,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo, width: 2),
                    ),
                    child: QrImageView(
                      data: exam.qrPayload,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID Único: ${exam.id}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherProv = Provider.of<TeacherProvider>(context);
    final savedExams = teacherProv.createdExams;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generador de Evaluaciones Sorpresa'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.edit_note), text: 'Crear Evaluación'),
              Tab(icon: Icon(Icons.qr_code_2), text: 'Mis QRs Guardados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '1. Seleccionar Clase Base del Día (1 a 36):',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedClassNumber,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            items: _classes.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.numeroClase,
                                child: Text(
                                  'T${c.trimestre} - Clase ${c.numeroClase}: ${c.titulo}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() => _selectedClassNumber = val);
                              _loadQuestionsFromSelectedClass();
                            },
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _examTitleCtrl,
                            decoration: InputDecoration(
                              labelText: 'Título de la Evaluación Sorpresa',
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _loadQuestionsFromSelectedClass,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Cargar 10 de esta Clase'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    setState(() => _draftQuestions.clear()),
                                icon: const Icon(Icons.delete_sweep_outlined,
                                    size: 18),
                                label: const Text('Vaciar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '2. Agregar Pregunta y Respuesta Propia del Docente:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _manualQuestionCtrl,
                            decoration: InputDecoration(
                              labelText: 'Escribe tu pregunta aquí',
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _manualAnswerCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Respuesta correcta',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.tonalIcon(
                                onPressed: _addManualQuestion,
                                icon: const Icon(Icons.add),
                                label: const Text('Añadir'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Preguntas en la Evaluación (${_draftQuestions.length}):',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  ..._draftQuestions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          child: Text('${idx + 1}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(q.question,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Respuesta: ${q.answer}',
                            style: TextStyle(color: Colors.green[800])),
                        trailing: IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() => _draftQuestions.removeAt(idx));
                          },
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _draftQuestions.isEmpty
                        ? null
                        : () async {
                            final questionsToUse =
                                _draftQuestions.take(10).toList();
                            final created =
                                await teacherProv.saveCreatedSurpriseExam(
                              title: _examTitleCtrl.text.trim().isEmpty
                                  ? 'Evaluación Sorpresa'
                                  : _examTitleCtrl.text.trim(),
                              trimestre: _selectedTrimestre,
                              numeroClase: _selectedClassNumber,
                              questions: questionsToUse,
                              gameService: _gameService,
                            );
                            if (!context.mounted) return;
                            _showExamQrDialog(context, created);
                          },
                    icon: const Icon(Icons.qr_code_2),
                    label: Text(
                      'Generar y Guardar QR (${_draftQuestions.take(10).length} preguntas)',
                    ),
                  ),
                ],
              ),
            ),
            savedExams.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Aún no has generado Evaluaciones Sorpresa.\nCrea una en la pestaña "Crear Evaluación" y quedará guardada aquí lista para proyectar o compartir.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: savedExams.length,
                    itemBuilder: (context, index) {
                      final ex = savedExams[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.qr_code_2),
                          ),
                          title: Text(ex.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${ex.trimestre}.º Trimestre • Clase ${ex.numeroClase} • ${ex.questions.length} preguntas\nFecha: ${ex.createdAt} • ID: ${ex.id}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () =>
                                teacherProv.deleteCreatedExam(ex.id),
                          ),
                          onTap: () => _showExamQrDialog(context, ex),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}