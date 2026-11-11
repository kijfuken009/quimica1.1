import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/reaction_model.dart';

class ReactionBohrSimulator extends StatefulWidget {
  final ReactionModel reaction;
  const ReactionBohrSimulator({super.key, required this.reaction});

  @override
  State<ReactionBohrSimulator> createState() => _ReactionBohrSimulatorState();
}

class _ReactionBohrSimulatorState extends State<ReactionBohrSimulator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showEnergyChart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de vista: Átomos de Bohr vs Gráfico Energético
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.blur_circular, size: 18),
              label: Text('Interacción Bohr'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.show_chart, size: 18),
              label: Text('Curva Energética'),
            ),
          ],
          selected: {_showEnergyChart},
          onSelectionChanged: (selection) {
            setState(() => _showEnergyChart = selection.first);
          },
        ),
        const SizedBox(height: 12),
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _showEnergyChart
                    ? _ReactionEnergyChartPainter(
                        progress: _controller.value,
                        isExothermic: widget.reaction.energia.toLowerCase().contains('exo'),
                        deltaH: widget.reaction.deltaH,
                        activationEnergy: widget.reaction.energiaActivacion,
                      )
                    : _ReactionBohrBondPainter(
                        progress: _controller.value,
                        atoms: widget.reaction.atomosReactivos,
                        bondType: widget.reaction.tipoEnlace,
                        equation: widget.reaction.ecuacion,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReactionBohrBondPainter extends CustomPainter {
  final double progress;
  final List<ReactionAtomNode> atoms;
  final String bondType;
  final String equation;

  _ReactionBohrBondPainter({
    required this.progress,
    required this.atoms,
    required this.bondType,
    required this.equation,
  });

  List<int> _calculateShells(int z) {
    final List<int> shells = [];
    int remaining = z;
    int n = 1;
    while (remaining > 0) {
      int capacity = 2 * n * n;
      int take = math.min(remaining, capacity);
      shells.add(take);
      remaining -= take;
      n++;
    }
    return shells;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.46;
    final atomA = atoms.isNotEmpty
        ? atoms.first
        : const ReactionAtomNode(symbol: 'Na', atomicNumber: 11, count: 1, valenceElectrons: 1);
    final atomB = atoms.length > 1
        ? atoms[1]
        : const ReactionAtomNode(symbol: 'O', atomicNumber: 8, count: 1, valenceElectrons: 6);

    // Fase 0.0 -> 0.5: acercamiento de reactivos | 0.5 -> 1.0: enlace formado
    final approachFactor = (math.sin(progress * math.pi * 2 - math.pi / 2) + 1) / 2;
    final separation = 130.0 - (approachFactor * 52.0);

    final centerA = Offset(size.width / 2 - separation / 2, centerY);
    final centerB = Offset(size.width / 2 + separation / 2, centerY);

    _drawBohrAtom(canvas, centerA, atomA, Colors.amberAccent, progress * 2 * math.pi);
    _drawBohrAtom(canvas, centerB, atomB, Colors.cyanAccent, -progress * 2 * math.pi);

    // Cuando están cerca, resaltar la transferencia o compartición electrónica
    if (approachFactor > 0.65) {
      final bondPaint = Paint()
        ..color = Colors.greenAccent.withValues(alpha: (approachFactor - 0.65) * 2.5)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(centerA, centerB, bondPaint);
    }

    // Etiqueta inferior explicativa
    final textPainter = TextPainter(
      text: TextSpan(
        text: approachFactor > 0.65
            ? 'Producto formado (${bondType.toUpperCase()}) • $equation'
            : 'Reactivos aproximándose: ${atomA.symbol} (Z=${atomA.atomicNumber}) + ${atomB.symbol} (Z=${atomB.atomicNumber})',
        style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);

    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, size.height - 28));
  }

  void _drawBohrAtom(
    Canvas canvas,
    Offset center,
    ReactionAtomNode atom,
    Color color,
    double baseAngle,
  ) {
    final shells = _calculateShells(atom.atomicNumber);
    final orbitPaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < shells.length; i++) {
      final radius = 18.0 + (i * 12.0);
      canvas.drawCircle(center, radius, orbitPaint);

      final electronsInShell = shells[i];
      for (int e = 0; e < electronsInShell; e++) {
        final angle = baseAngle * (i.isEven ? 1 : -1) + (2 * math.pi * e / electronsInShell);
        final ex = center.dx + radius * math.cos(angle);
        final ey = center.dy + radius * math.sin(angle);
        canvas.drawCircle(
          Offset(ex, ey),
          i == shells.length - 1 ? 3.8 : 2.5,
          Paint()..color = i == shells.length - 1 ? Colors.white : color,
        );
      }
    }

    // Núcleo
    canvas.drawCircle(center, 11, Paint()..color = color.withValues(alpha: 0.85));
    final tp = TextPainter(
      text: TextSpan(
        text: atom.symbol,
        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ReactionBohrBondPainter oldDelegate) => true;
}

class _ReactionEnergyChartPainter extends CustomPainter {
  final double progress;
  final bool isExothermic;
  final double deltaH;
  final double activationEnergy;

  _ReactionEnergyChartPainter({
    required this.progress,
    required this.isExothermic,
    required this.deltaH,
    required this.activationEnergy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 42.0;
    const rightPad = 20.0;
    const topPad = 24.0;
    const bottomPad = 34.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    // Ejes cartesianos
    final axisPaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(leftPad, topPad), Offset(leftPad, topPad + chartH), axisPaint);
    canvas.drawLine(
      Offset(leftPad, topPad + chartH),
      Offset(leftPad + chartW, topPad + chartH),
      axisPaint,
    );

    final startY = isExothermic ? topPad + chartH * 0.45 : topPad + chartH * 0.72;
    final peakY = topPad + chartH * 0.14;
    final endY = isExothermic ? topPad + chartH * 0.78 : topPad + chartH * 0.35;

    final path = Path();
    Offset? indicatorPos;

    for (int i = 0; i <= 100; i++) {
      final t = i / 100.0;
      final x = leftPad + t * chartW;
      double y;
      if (t < 0.2) {
        y = startY;
      } else if (t < 0.5) {
        final localT = (t - 0.2) / 0.3;
        y = startY + (peakY - startY) * math.sin(localT * math.pi / 2);
      } else if (t < 0.8) {
        final localT = (t - 0.5) / 0.3;
        y = peakY + (endY - peakY) * (1 - math.cos(localT * math.pi / 2));
      } else {
        y = endY;
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      if ((t - progress).abs() < 0.012) {
        indicatorPos = Offset(x, y);
      }
    }

    final curveColor = isExothermic ? Colors.orangeAccent : Colors.lightBlueAccent;
    canvas.drawPath(
      path,
      Paint()
        ..color = curveColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke,
    );

    if (indicatorPos != null) {
      canvas.drawCircle(indicatorPos, 6, Paint()..color = Colors.white);
    }

    // Etiquetas del gráfico
    _drawLabel(canvas, 'Energía (kJ/mol)', const Offset(8, 6), Colors.white70);
    _drawLabel(
      canvas,
      isExothermic
          ? 'Exotérmica (ΔH = $deltaH kJ/mol • Libera calor)'
          : 'Endotérmica (ΔH = +${deltaH.abs()} kJ/mol • Absorbe calor)',
      Offset(leftPad + 10, topPad + chartH + 10),
      curveColor,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _ReactionEnergyChartPainter oldDelegate) => true;
}