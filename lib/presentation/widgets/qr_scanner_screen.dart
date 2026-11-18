import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? expectedPrefix;

  const QrScannerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.expectedPrefix,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final ImagePicker _imagePicker = ImagePicker();
  bool _hasCompleted = false;
  bool _isAnalyzingGallery = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Valida si el código QR leído coincide con el formato esperado de ChemIA
  bool _isValidPayload(String rawValue) {
    final clean = rawValue.trim();
    if (clean.isEmpty) return false;
    if (widget.expectedPrefix != null && widget.expectedPrefix!.isNotEmpty) {
      return clean.startsWith(widget.expectedPrefix!);
    }
    return clean.startsWith('CHEMIA-');
  }

  /// Modal de Éxito cuando el QR de la imagen o cámara es válido
  Future<void> _showSuccessModalAndReturn(String rawCode, {required bool fromGallery}) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fromGallery ? "Imagen Cargada Correctamente" : "Código QR Detectado",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          fromGallery
              ? "✅ La imagen de la galería se procesó con éxito y el código QR de ChemIA coincide."
              : "✅ El código QR fue escaneado y verificado correctamente.",
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Continuar"),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context, rawCode);
  }

  /// Modal de Error cuando la imagen no tiene un QR o el QR no coincide
  Future<void> _showInvalidQrModal(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "El QR no coincide",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Intentar con otra imagen"),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasCompleted || _isAnalyzingGallery) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _hasCompleted = true;
        if (_isValidPayload(raw)) {
          await _showSuccessModalAndReturn(raw.trim(), fromGallery: false);
        } else {
          await _showInvalidQrModal(
            "❌ El código QR escaneado no coincide con el formato requerido para esta acción en ChemIA.",
          );
          _hasCompleted = false;
        }
        break;
      }
    }
  }

  /// Permite importar una captura o imagen de QR desde la galería del teléfono
  Future<void> _pickAndAnalyzeQrFromGallery() async {
    if (_isAnalyzingGallery) return;
    setState(() => _isAnalyzingGallery = true);

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) {
        if (mounted) setState(() => _isAnalyzingGallery = false);
        return;
      }

      final BarcodeCapture? capture =
          await _controller.analyzeImage(pickedFile.path);

      if (!mounted) return;

      if (capture == null || capture.barcodes.isEmpty) {
        await _showInvalidQrModal(
          "❌ No se detectó ningún código QR en la imagen seleccionada. Asegúrate de elegir una captura nítida del código QR.",
        );
        setState(() => _isAnalyzingGallery = false);
        return;
      }

      final String? raw = capture.barcodes.first.rawValue;
      if (raw == null || !_isValidPayload(raw)) {
        await _showInvalidQrModal(
          "❌ El código QR de la imagen no coincide con el tipo de respaldo o evaluación de ChemIA esperado.",
        );
        setState(() => _isAnalyzingGallery = false);
        return;
      }

      _hasCompleted = true;
      await _showSuccessModalAndReturn(raw.trim(), fromGallery: true);
    } catch (_) {
      if (mounted) {
        await _showInvalidQrModal(
          "❌ Ocurrió un problema al leer la imagen seleccionada. Intenta con otra captura de tu galería.",
        );
        setState(() => _isAnalyzingGallery = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Encender/Apagar Linterna",
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: "Cambiar Cámara",
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.black87,
            child: Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_off,
                                color: Colors.white70, size: 54),
                            const SizedBox(height: 12),
                            Text(
                              'Cámara no disponible (${error.errorCode.name}).\nPuedes usar el botón de abajo para importar la imagen del QR desde tu Galería.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amberAccent, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            color: Colors.black,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  _isAnalyzingGallery ? null : _pickAndAnalyzeQrFromGallery,
              icon: _isAnalyzingGallery
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.photo_library_outlined),
              label: Text(
                _isAnalyzingGallery
                    ? "Analizando imagen QR..."
                    : "Importar Imagen QR desde Galería",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}