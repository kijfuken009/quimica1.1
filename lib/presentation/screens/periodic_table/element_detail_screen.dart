import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../data/models/element_model.dart';
import '../../widgets/atom_3d_viewer.dart';

class ElementDetailScreen extends StatefulWidget {
  final ElementModel element;
  const ElementDetailScreen({super.key, required this.element});

  @override
  State<ElementDetailScreen> createState() => _ElementDetailScreenState();
}

class _ElementDetailScreenState extends State<ElementDetailScreen> {
  bool _hasGlb = false;
  bool _checkingGlb = true;

  @override
  void initState() {
    super.initState();
    _checkModelAvailability();
  }

  Future<void> _checkModelAvailability() async {
    final modelPath = widget.element.modelo;
    if (modelPath.isEmpty || !modelPath.endsWith('.glb')) {
      if (mounted) setState(() { _hasGlb = false; _checkingGlb = false; });
      return;
    }

    try {
      // Verifica si el archivo binario .glb está realmente en los assets locales
      await rootBundle.load(modelPath);
      if (mounted) setState(() { _hasGlb = true; _checkingGlb = false; });
    } catch (_) {
      // Si no existe (excluido por git o no descargado), conmuta al átomo 3D procedural
      if (mounted) setState(() { _hasGlb = false; _checkingGlb = false; });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'alkali':
      case 'metales alcalinos':
        return Colors.redAccent;
      case 'alkaline':
      case 'alcalinoterreos':
        return Colors.orangeAccent;
      case 'transition':
      case 'metales de transicion':
        return Colors.amber;
      case 'post-transition':
      case 'metales del bloque p':
        return Colors.lightGreen;
      case 'metalloid':
      case 'metaloides':
        return Colors.tealAccent;
      case 'non-metal':
      case 'no metales':
        return Colors.lightBlueAccent;
      case 'noble':
      case 'gases nobles':
        return Colors.purpleAccent;
      case 'lanthanide':
      case 'lantanidos':
        return Colors.pinkAccent;
      case 'actinide':
      case 'actinidos':
        return Colors.deepOrangeAccent;
      default:
        return Colors.cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getCategoryColor(widget.element.categoria);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.element.nombre} (${widget.element.simbolo})"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Contenedor 3D Híbrido (GLB o Átomo Procedural Bohr)
            Container(
              height: 380,
              width: double.infinity,
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                border: Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: _checkingGlb
                    ? const Center(child: CircularProgressIndicator())
                    : _hasGlb
                        ? ModelViewer(
                            src: widget.element.modelo,
                            autoRotate: true,
                            cameraControls: true,
                            backgroundColor: Colors.transparent,
                          )
                        : Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Atom3DViewer(
                                atomicNumber: widget.element.numero,
                                symbol: widget.element.simbolo,
                                elementColor: themeColor,
                              ),
                              Positioned(
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "Átomo de Bohr 3D interactivo (Gira con el dedo 👆)",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),

            // Panel de Información Detallada
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard("✨ Dato Curioso", widget.element.datoCurioso, Colors.amber),
                  _buildInfoCard("📖 Descripción", widget.element.descripcion, Colors.blue),
                  _buildInfoCard("🧪 Usos Industriales", widget.element.uso, Colors.green),
                  _buildInfoCard("🕰️ Historia", widget.element.descubrimiento, Colors.purple),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}