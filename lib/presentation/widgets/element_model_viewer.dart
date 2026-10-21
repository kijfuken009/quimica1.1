import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/element_model.dart';
import 'atom_3d_viewer.dart';
// Importa aquí tu widget de visor GLB/WebGL existente si lo tienes en otra ruta
// import 'tu_visor_glb.dart';

class ElementModelViewer extends StatefulWidget {
  final ElementModel element;
  final Color categoryColor;
  final Widget Function(BuildContext, String)? glbBuilder;

  const ElementModelViewer({
    super.key,
    required this.element,
    required this.categoryColor,
    this.glbBuilder,
  });

  @override
  State<ElementModelViewer> createState() => _ElementModelViewerState();
}

class _ElementModelViewerState extends State<ElementModelViewer> {
  bool _hasGlb = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkGlbAvailability();
  }

  @override
  void didUpdateWidget(covariant ElementModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.numero != widget.element.numero) {
      _checkGlbAvailability();
    }
  }

  Future<void> _checkGlbAvailability() async {
    setState(() => _checking = true);
    final modelPath = widget.element.modelo;

    if (modelPath.isEmpty || !modelPath.endsWith('.glb')) {
      if (mounted) setState(() { _hasGlb = false; _checking = false; });
      return;
    }

    try {
      // Intenta verificar si el binario del GLB está empaquetado en assets
      await rootBundle.load(modelPath);
      if (mounted) setState(() { _hasGlb = true; _checking = false; });
    } catch (_) {
      // El archivo no existe o está excluido por .gitignore -> Fallback al átomo procedural
      if (mounted) setState(() { _hasGlb = false; _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 1. Si el archivo .glb existe y se proporcionó el builder de WebGL
    if (_hasGlb && widget.glbBuilder != null) {
      return SizedBox(
        height: 320,
        child: widget.glbBuilder!(context, widget.element.modelo),
      );
    }

    // 2. Fallback procedural: átomo 3D en tiempo real
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Atom3DViewer(
          atomicNumber: widget.element.numero,
          symbol: widget.element.simbolo,
          elementColor: widget.categoryColor,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.categoryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Modelo atómico de Bohr interactivo (Gira con el dedo 👆)",
            style: TextStyle(
              fontSize: 12,
              color: widget.categoryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}