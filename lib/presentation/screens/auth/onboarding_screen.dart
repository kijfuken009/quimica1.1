import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();

    if (name.isEmpty || ageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, completa todos los campos"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    int? age = int.tryParse(ageText);
    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, ingresa una edad válida"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    await Provider.of<UserProvider>(context, listen: false).saveUser(name, age);

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  /// Modal de Registro y Sincronización por Gmail con Verificación de Docente/Adulto
  void _showTeacherRegistrationModal(BuildContext context) {
    final teacherNameCtrl = TextEditingController();
    final gmailCtrl = TextEditingController();
    final adultVerificationCtrl = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.indigo),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Verificación y Sincronización Docente",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.5),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ingresa tu cuenta de Gmail institucional o personal. Si ya usaste ChemIA antes con este correo, tu pizarra de alumnos y tus QRs se sincronizarán automáticamente:",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: teacherNameCtrl,
                    decoration: InputDecoration(
                      labelText: "Nombre y Apellido del Docente",
                      prefixIcon: const Icon(Icons.person_outline),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: gmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Cuenta de Google (usuario@gmail.com)",
                      prefixIcon: const Icon(Icons.mail_outline),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const Divider(height: 22),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🛡️ Verificación de Docente de Química:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Para confirmar que eres docente en aula: ¿Cuál es la masa molar aproximada del Agua (H₂O) en g/mol?",
                          style: TextStyle(fontSize: 11.5),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: adultVerificationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Respuesta en g/mol (ej: 18)",
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
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
              child: const Text("Cancelar"),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_sync_outlined),
              label: const Text("Verificar y Sincronizar"),
              onPressed: () async {
                final tName = teacherNameCtrl.text.trim();
                final tEmail = gmailCtrl.text.trim().toLowerCase();
                final chemCheck = adultVerificationCtrl.text.trim();

                if (tName.isEmpty ||
                    !tEmail.endsWith('@gmail.com') && !tEmail.contains('@')) {
                  setModalState(() {
                    errorMsg =
                        "⚠️ Ingresa tu nombre completo y un correo de Google válido (@gmail.com).";
                  });
                  return;
                }

                if (chemCheck != '18' && chemCheck != '18.0') {
                  setModalState(() {
                    errorMsg =
                        "❌ Verificación docente incorrecta. Recuerda: H(1×2) + O(16) = 18 g/mol.";
                  });
                  return;
                }

                final teacherProv =
                    Provider.of<TeacherProvider>(context, listen: false);
                final userProv =
                    Provider.of<UserProvider>(context, listen: false);

                final restored = await teacherProv.registerOrSyncWithGmail(
                  name: tName,
                  googleEmail: tEmail,
                );
                await userProv.saveUser("Prof. ${teacherProv.teacherName}", 30);

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green[700],
                    content: Text(
                      restored
                          ? "☁️ Cuenta $tEmail verificada: Pizarra y QRs sincronizados."
                          : "✅ Cuenta docente vinculada a $tEmail.",
                    ),
                  ),
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade400, Colors.purple.shade700],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 15),
                const Icon(Icons.science, size: 86, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  "¡Bienvenido a ChemIA!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tu aventura química comienza aquí. Cuéntanos quién eres.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(
                  controller: _nameController,
                  label: "Tu nombre o apodo (Estudiante)",
                  icon: Icons.person,
                ),
                const SizedBox(height: 18),

                _buildTextField(
                  controller: _ageController,
                  label: "Tu edad",
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                        ),
                        child: Text(
                          "¡Empezar Aventura!",
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),

                const SizedBox(height: 36),

                // Tarjeta inferior para Registro de Docente con cuenta Gmail
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            "Acceso Exclusivo para Docentes",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () =>
                              _showTeacherRegistrationModal(context),
                          icon: const Icon(Icons.email_outlined, size: 19),
                          label: const Text("Registrar Docente con Gmail"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.indigo),
        prefixIcon: Icon(icon, color: Colors.indigo),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
        ),
      ),
    );
  }
}