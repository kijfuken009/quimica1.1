import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../providers/teacher_provider.dart';
import '../../widgets/qr_scanner_screen.dart';

class TeacherRosterScreen extends StatefulWidget {
  const TeacherRosterScreen({super.key});

  @override
  State<TeacherRosterScreen> createState() => _TeacherRosterScreenState();
}

class _TeacherRosterScreenState extends State<TeacherRosterScreen> {
  int _selectedTrimestre = 1;

  Future<void> _scanStudentQr(
    BuildContext context,
    TeacherProvider teacherProv,
  ) async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(
          title: 'Escanear QR del Estudiante',
          subtitle:
              'Apunta al código QR del estudiante para anotar sus calificaciones y promedios automáticamente',
        ),
      ),
    );

    if (!context.mounted || scanned == null || scanned.isEmpty) return;

    final record = await teacherProv.syncStudentFromQr(scanned);
    if (!context.mounted) return;

    if (record != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[700],
          content: Text(
            '✅ Estudiante "${record.name}" registrado/actualizado automáticamente.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            '❌ El QR escaneado no pertenece a un reporte estudiantil válido.',
          ),
        ),
      );
    }
  }

  void _showStudentDetailModal(
    BuildContext context,
    TeacherProvider teacherProv,
    TeacherStudentRecord student,
  ) {
    final obsController = TextEditingController(text: student.observations);
    final manualScoreController = TextEditingController();
    final manualTitleController = TextEditingController();
    final recoveryQr = student.toStudentRecoveryQrPayload();

    final regAvg = student.getRegularClassAverage(_selectedTrimestre);
    final surpAvg = student.getSurpriseExamAverage(_selectedTrimestre);
    final finalAvg = student.getFinalTrimestreAverage(_selectedTrimestre);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '👤 ${student.name} (${student.age} años)',
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Resumen Evaluativo • $_selectedTrimestre.º Trimestre',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statMini(
                              'Clases (${student.getCompletedClassesCount(_selectedTrimestre)}/12)',
                              '${regAvg.toStringAsFixed(1)} pts'),
                          _statMini(
                              'Sorpresas (${student.getSurpriseExamCount(_selectedTrimestre)})',
                              '${surpAvg.toStringAsFixed(1)} pts'),
                          _statMini('Promedio Final',
                              '${finalAvg.toStringAsFixed(1)} pts',
                              highlight: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '➕ Agregar Nota de Evaluación Sorpresa Manual:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: manualTitleController,
                        decoration: InputDecoration(
                          labelText: 'Tema / Título',
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: manualScoreController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Nota (0-100)',
                          isDense: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Observación Pedagógica del Docente',
                    hintText:
                        'Ej: Participativo en laboratorio, reforzar óxidos...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  '📲 QR de Recuperación para este Estudiante:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Si el alumno reinstaló la app, pídele que escanee este QR en "Respaldo QR" para recuperar todo su avance:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 170,
                    height: 170,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: QrImageView(
                      data: recoveryQr,
                      version: QrVersions.auto,
                      size: 154,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await teacherProv.removeStudent(student.name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final int? manualScore =
                  int.tryParse(manualScoreController.text.trim());
              await teacherProv.updateStudentObservationsAndManualGrade(
                studentName: student.name,
                observations: obsController.text,
                manualSurpriseScore: manualScore,
                trimestreForManualScore:
                    manualScore != null ? _selectedTrimestre : null,
                manualSurpriseTitle: manualTitleController.text,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Guardar Cambios'),
          ),
        ],
      ),
    );
  }

  Widget _statMini(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: highlight ? 14.5 : 13,
            color: highlight ? Colors.indigo[900] : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showTeacherCloudBackupModal(
    BuildContext context,
    TeacherProvider teacherProv,
  ) {
    final nameCtrl = TextEditingController(text: teacherProv.teacherName);
    final emailCtrl =
        TextEditingController(text: teacherProv.teacherGoogleEmail);
    String? statusMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '☁️ Sincronización con Cuenta Google',
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: 310,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Tu pizarra de alumnos, calificaciones, promedios comparativos y QRs de evaluaciones sorpresa están vinculados a tu correo de Gmail:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Docente',
                      prefixIcon: const Icon(Icons.person_outline),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo Gmail Vinculado',
                      prefixIcon: const Icon(Icons.email_outlined),
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      await teacherProv.registerOrSyncWithGmail(
                        name: nameCtrl.text,
                        googleEmail: emailCtrl.text,
                      );
                      setModalState(() {
                        statusMsg =
                            '☁️ Pizarra de alumnos (${teacherProv.students.length}) y QRs (${teacherProv.createdExams.length}) sincronizados con ${emailCtrl.text.trim()}.';
                      });
                    },
                    icon: const Icon(Icons.cloud_done_outlined),
                    label: const Text('Sincronizar Ahora con mi Gmail'),
                  ),
                  if (statusMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      statusMsg!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
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
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherProv = Provider.of<TeacherProvider>(context);
    final students = teacherProv.students;

    double courseAvg = 0.0;
    int approvedCount = 0;
    if (students.isNotEmpty) {
      double sum = 0;
      for (final s in students) {
        final avg = s.getFinalTrimestreAverage(_selectedTrimestre);
        sum += avg;
        if (avg >= 60) approvedCount++;
      }
      courseAvg = sum / students.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pizarra Docente de Alumnos'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cuenta Gmail y Respaldo Maestro',
            icon: const Icon(Icons.cloud_sync_outlined),
            onPressed: () => _showTeacherCloudBackupModal(context, teacherProv),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _scanStudentQr(context, teacherProv),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear QR de Alumno'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Text(
                  'Prof. ${teacherProv.teacherName} • ${teacherProv.teacherGoogleEmail}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _headerMetric('Inscritos', '${students.length}'),
                    _headerMetric('Promedio Curso',
                        '${courseAvg.toStringAsFixed(1)} / 100'),
                    _headerMetric('Aprobados (≥60)',
                        '$approvedCount / ${students.length}'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1.º Trimestre')),
                ButtonSegment(value: 2, label: Text('2.º Trimestre')),
                ButtonSegment(value: 3, label: Text('3.º Trimestre')),
              ],
              selected: {_selectedTrimestre},
              onSelectionChanged: (sel) {
                setState(() => _selectedTrimestre = sel.first);
              },
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Aún no hay estudiantes registrados en tu pizarra.\n\nPulsa el botón "Escanear QR de Alumno" para escanear el código QR de cada estudiante y registrar automáticamente su nombre, calificaciones, evaluaciones sorpresa y promedios.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final st = students[index];
                      final regAvg =
                          st.getRegularClassAverage(_selectedTrimestre);
                      final surpAvg =
                          st.getSurpriseExamAverage(_selectedTrimestre);
                      final finalAvg =
                          st.getFinalTrimestreAverage(_selectedTrimestre);
                      final completed =
                          st.getCompletedClassesCount(_selectedTrimestre);
                      final surpCount =
                          st.getSurpriseExamCount(_selectedTrimestre);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: finalAvg >= 60
                                ? Colors.green.withValues(alpha: 0.18)
                                : Colors.orange.withValues(alpha: 0.18),
                            child: Text(
                              finalAvg.toStringAsFixed(0),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: finalAvg >= 60
                                    ? Colors.green[800]
                                    : Colors.orange[800],
                              ),
                            ),
                          ),
                          title: Text(
                            '${index + 1}. ${st.name} (${st.age} años)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clases ($completed/12): ${regAvg.toStringAsFixed(1)} pts  |  Sorpresas ($surpCount): ${surpAvg.toStringAsFixed(1)} pts',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (st.observations.isNotEmpty)
                                  Text(
                                    '📝 Obs: ${st.observations}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.indigo[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          trailing:
                              const Icon(Icons.qr_code_2, color: Colors.indigo),
                          onTap: () => _showStudentDetailModal(
                              context, teacherProv, st),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerMetric(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11.5)),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}