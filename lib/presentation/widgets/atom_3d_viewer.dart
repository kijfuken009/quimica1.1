import 'dart:math' as math;
import 'package:flutter/material.dart';

class Atom3DViewer extends StatefulWidget {
  final int atomicNumber;
  final String symbol;
  final Color elementColor;

  const Atom3DViewer({
    super.key,
    required this.atomicNumber,
    required this.symbol,
    this.elementColor = Colors.cyanAccent,
  });

  @override
  State<Atom3DViewer> createState() => _Atom3DViewerState();
}

class _Atom3DViewerState extends State<Atom3DViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotX = 0.35;
  double _rotY = 0.35;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Distribución de electrones por nivel de energía (Capas de Bohr: 2n²)
  List<int> _calculateElectronShells(int z) {
    const capacities = [2, 8, 18, 32, 32, 18, 8];
    List<int> shells = [];
    int remaining = z;

    for (int cap in capacities) {
      if (remaining <= 0) break;
      int count = remaining >= cap ? cap : remaining;
      shells.add(count);
      remaining -= count;
    }
    return shells;
  }

  @override
  Widget build(BuildContext context) {
    final shells = _calculateElectronShells(widget.atomicNumber);

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _rotY += details.delta.dx * 0.01;
          _rotX -= details.delta.dy * 0.01;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(double.infinity, 320),
            painter: _AtomPainter(
              animationValue: _controller.value,
              shells: shells,
              symbol: widget.symbol,
              baseColor: widget.elementColor,
              rotX: _rotX,
              rotY: _rotY,
            ),
          );
        },
      ),
    );
  }
}

class _AtomPainter extends CustomPainter {
  final double animationValue;
  final List<int> shells;
  final String symbol;
  final Color baseColor;
  final double rotX;
  final double rotY;

  _AtomPainter({
    required this.animationValue,
    required this.shells,
    required this.symbol,
    required this.baseColor,
    required this.rotX,
    required this.rotY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.44;
    final shellStep = maxRadius / (shells.isEmpty ? 1 : shells.length + 1);

    // 1. Dibujar órbitas y electrones
    for (int i = 0; i < shells.length; i++) {
      final radius = shellStep * (i + 1.2);
      final electronCount = shells[i];

      final orbitTiltX = rotX + (i * 0.38);
      final orbitTiltY = rotY + (i * 0.48);

      _drawOrbitPath(canvas, center, radius, orbitTiltX, orbitTiltY);

      final speedFactor = 1.0 / (i + 1);
      final angleOffset = animationValue * 2 * math.pi * speedFactor;

      for (int e = 0; e < electronCount; e++) {
        final angle = (2 * math.pi / electronCount) * e + angleOffset;
        _draw3DElectron(canvas, center, radius, angle, orbitTiltX, orbitTiltY);
      }
    }

    // 2. Dibujar Núcleo Atómico
    _drawNucleus(canvas, center);
  }

  void _drawOrbitPath(Canvas canvas, Offset center, double radius, double tiltX, double tiltY) {
    final orbitPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    const segments = 60;
    for (int j = 0; j <= segments; j++) {
      final theta = (2 * math.pi / segments) * j;
      double x = radius * math.cos(theta);
      double y = radius * math.sin(theta);
      double z = 0;

      double y1 = y * math.cos(tiltX) - z * math.sin(tiltX);
      double z1 = y * math.sin(tiltX) + z * math.cos(tiltX);
      double x2 = x * math.cos(tiltY) + z1 * math.sin(tiltY);

      final point = Offset(center.dx + x2, center.dy + y1);
      if (j == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path, orbitPaint);
  }

  void _draw3DElectron(Canvas canvas, Offset center, double radius, double angle, double tiltX, double tiltY) {
    double x = radius * math.cos(angle);
    double y = radius * math.sin(angle);
    double z = 0;

    double y1 = y * math.cos(tiltX) - z * math.sin(tiltX);
    double z1 = y * math.sin(tiltX) + z * math.cos(tiltX);
    double x2 = x * math.cos(tiltY) + z1 * math.sin(tiltY);
    double z2 = -x * math.sin(tiltY) + z1 * math.cos(tiltY);

    double scale = (1.0 + (z2 / (radius * 2.5))).clamp(0.6, 1.4);
    final electronCenter = Offset(center.dx + x2, center.dy + y1);

    final glowPaint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(electronCenter, 5.0 * scale, glowPaint);

    final electronPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(electronCenter, 2.8 * scale, electronPaint);
  }

  void _drawNucleus(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, 26, glowPaint);

    final nucleusPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          baseColor,
          baseColor.withValues(alpha: 0.75),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 20));
    canvas.drawCircle(center, 20, nucleusPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );
  }

  @override
  bool shouldRepaint(covariant _AtomPainter oldDelegate) => true;
}