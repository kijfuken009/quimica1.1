import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/reaction_model.dart';

class ReactionsScreen extends StatefulWidget {
  const ReactionsScreen({super.key});

  @override
  State<ReactionsScreen> createState() => _ReactionsScreenState();
}

class _ReactionsScreenState extends State<ReactionsScreen> {
  List<ReactionModel> _allReactions = [];
  List<ReactionModel> _filteredReactions = [];
  int _selectedTrimestre = 0; // 0 = Todos, 1 = 1er Trim, 2 = 2do Trim, 3 = 3er Trim
  String _selectedType = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = [
    'Todos',
    'Óxidos Básicos',
    'Anhídridos',
    'Hidróxidos',
    'Ácidos',
    'Sales',
    'Combustión',
    'Síntesis',
    'Ácido-Base',
    'Descomposición',
    'Desplazamiento',
  ];

  // Mapa rápido de números atómicos para calcular órbitas de Bohr automáticamente
  static const Map<String, int> _atomicNumbers = {
    'H': 1, 'He': 2, 'Li': 3, 'Be': 4, 'B': 5, 'C': 6, 'N': 7, 'O': 8,
    'F': 9, 'Ne': 10, 'Na': 11, 'Mg': 12, 'Al': 13, 'Si': 14, 'P': 15,
    'S': 16, 'Cl': 17, 'Ar': 18, 'K': 19, 'Ca': 20, 'Fe': 26, 'Cu': 29,
    'Zn': 30, 'Ag': 47, 'I': 53, 'Ba': 56, 'Au': 79, 'Hg': 80, 'Pb': 82,
  };

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReactions() async {
    try {
      final String data = await rootBundle.loadString('assets/data/reactions.json');
      final List<dynamic> jsonList = jsonDecode(data);
      final reactions = jsonList.map((e) => ReactionModel.fromJson(e)).toList();

      // Ordenar por número de clase para seguir el avance escolar
      reactions.sort((a, b) => a.numeroClase.compareTo(b.numeroClase));

      if (!mounted) return;
      setState(() {
        _allReactions = reactions;
        _filteredReactions = reactions;
      });
    } catch (e) {
      debugPrint("Error cargando reacciones: $e");
    }
  }

  void _filter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredReactions = _allReactions.where((reac) {
        final matchesQuery = reac.nombre.toLowerCase().contains(query) ||
            reac.ecuacion.toLowerCase().contains(query) ||
            reac.reactivos.toLowerCase().contains(query) ||
            reac.productos.toLowerCase().contains(query) ||
            reac.temaCurricular.toLowerCase().contains(query) ||
            'clase ${reac.numeroClase}'.contains(query);

        final matchesTrimestre =
            _selectedTrimestre == 0 || reac.trimestre == _selectedTrimestre;

        final matchesType = _selectedType == 'Todos' ||
            reac.tipo.toLowerCase().contains(_selectedType.toLowerCase()) ||
            reac.temaCurricular.toLowerCase().contains(_selectedType.toLowerCase());

        return matchesQuery && matchesTrimestre && matchesType;
      }).toList();
    });
  }

  /// Obtiene los nodos atómicos para Bohr (desde el JSON o deducidos de elementosRelacionados)
  List<ReactionAtomNode> _resolveAtomsForBohr(ReactionModel reac) {
    if (reac.atomosReactivos.isNotEmpty) {
      return reac.atomosReactivos;
    }
    if (reac.elementosRelacionados.isNotEmpty) {
      return reac.elementosRelacionados.take(2).map((sym) {
        final cleanSym = sym.trim();
        final z = _atomicNumbers[cleanSym] ?? 6;
        return ReactionAtomNode(symbol: cleanSym, atomicNumber: z);
      }).toList();
    }
    return const [
      ReactionAtomNode(symbol: 'H', atomicNumber: 1),
      ReactionAtomNode(symbol: 'O', atomicNumber: 8),
    ];
  }

  void _showReactionDetailsModal(ReactionModel reaction) {
    final atoms = _resolveAtomsForBohr(reaction);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Etiqueta de Trimestre y Clase
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSmallChip(
                        '${reaction.trimestre}.º Trimestre • Clase ${reaction.numeroClase}',
                        Colors.cyanAccent,
                      ),
                      _buildSmallChip(reaction.temaCurricular, Colors.indigoAccent),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Título
                  Text(
                    reaction.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Simulador Bohr + Curva Energética
                  ReactionBohrAndChartWidget(
                    reaction: reaction,
                    atoms: atoms,
                  ),
                  const SizedBox(height: 18),

                  // Cartel de advertencia para reacciones peligrosas
                  if (reaction.esPeligrosa)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.redAccent, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "ADVERTENCIA DE SEGURIDAD",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reaction.advertenciaSeguridad.isNotEmpty
                                      ? reaction.advertenciaSeguridad
                                      : "Solo puede ser realizada con la supervisión de un adulto o docente en laboratorio.",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.greenAccent, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reaction.advertenciaSeguridad.isNotEmpty
                                  ? reaction.advertenciaSeguridad
                                  : "Reacción segura para estudio escolar teórico y práctico.",
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildDetailSection(
                    title: "Ecuación Balanceada",
                    child: _buildBadge(reaction.ecuacion,
                        fontSize: 16, isHighlight: true),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: "Reactivos",
                    child: _buildBadge(reaction.reactivos),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: "Productos",
                    child: _buildBadge(reaction.productos),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: "Tipo de Reacción y Enlace",
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _buildBadge(reaction.tipo),
                        _buildBadge('Enlace ${reaction.tipoEnlace.toUpperCase()}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: "Explicación Pedagógica",
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reaction.explicacion,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: "Condiciones Requeridas",
                    child: Text(
                      reaction.condiciones,
                      style: const TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: "Comportamiento Energético (Entalpía ΔH)",
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${reaction.energia} • ΔH = ${reaction.deltaH} kJ/mol (Ea =${reaction.energiaActivacion} kJ/mol)',
                        style: const TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSmallChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildBadge(String text, {double fontSize = 14, bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? Colors.indigo.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight ? Colors.indigoAccent : Colors.white12,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        title: const Text("Plan de Clases: Reacciones"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filter(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar clase, fórmula o compuesto (ej. Clase 5, Óxido, H₂O)...",
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Selector de Trimestre Escolar (Pensum Boliviano)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTrimestreTab(0, 'Todo el Año'),
                  const SizedBox(width: 8),
                  _buildTrimestreTab(1, '1.º Trimestre'),
                  const SizedBox(width: 8),
                  _buildTrimestreTab(2, '2.º Trimestre'),
                  const SizedBox(width: 8),
                  _buildTrimestreTab(3, '3.º Trimestre'),
                ],
              ),
            ),
          ),

          // Chips horizontales de familias químicas
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  selectedColor: Colors.indigoAccent,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? Colors.indigoAccent : Colors.white12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                      _filter();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              "Sesiones de Laboratorio Virtual (${_filteredReactions.length} clases)",
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),

          // Lista de tarjetas desplegables por clase
          Expanded(
            child: _filteredReactions.isEmpty
                ? const Center(
                    child: Text(
                      "No se encontraron reacciones para este filtro",
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReactions.length,
                    itemBuilder: (context, index) {
                      final reac = _filteredReactions[index];
                      return _buildExpandableReactionCard(reac);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrimestreTab(int trimestre, String label) {
    final selected = _selectedTrimestre == trimestre;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTrimestre = trimestre);
        _filter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.tealAccent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.tealAccent : Colors.white12,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.tealAccent : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  /// Tarjeta desplegable por cada Clase con Simulador de Bohr y Gráfica integrados
  Widget _buildExpandableReactionCard(ReactionModel reac) {
    final atoms = _resolveAtomsForBohr(reac);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reac.esPeligrosa
              ? Colors.redAccent.withValues(alpha: 0.35)
              : Colors.white12,
          width: reac.esPeligrosa ? 1.2 : 1.0,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: Colors.tealAccent,
          collapsedIconColor: Colors.white54,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Clase ${reac.numeroClase}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reac.nombre,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (reac.esPeligrosa)
                const Tooltip(
                  message: 'Requiere supervisión docente',
                  child: Text("⚠️", style: TextStyle(fontSize: 16)),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reac.trimestre}.º Trimestre • ${reac.temaCurricular.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reac.ecuacion,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            const Divider(color: Colors.white12, height: 18),
            // Simulador Interactivo de Bohr y Curva Energética dentro del desplegable
            ReactionBohrAndChartWidget(
              reaction: reac,
              atoms: atoms,
            ),
            const SizedBox(height: 12),
            Text(
              reac.explicacion,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12.5, height: 1.35),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: reac.esPeligrosa
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : Colors.tealAccent.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showReactionDetailsModal(reac),
                icon: const Icon(Icons.science_outlined, size: 18),
                label: const Text("Ver Ficha Completa de la Clase"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget que calcula las órbitas electrónicas de Bohr (2n²) de la reacción
/// y dibuja el comportamiento termoquímico resultante en gráfico cartesiano.
class ReactionBohrAndChartWidget extends StatefulWidget {
  final ReactionModel reaction;
  final List<ReactionAtomNode> atoms;

  const ReactionBohrAndChartWidget({
    super.key,
    required this.reaction,
    required this.atoms,
  });

  @override
  State<ReactionBohrAndChartWidget> createState() =>
      _ReactionBohrAndChartWidgetState();
}

class _ReactionBohrAndChartWidgetState extends State<ReactionBohrAndChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showChart = false;

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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Simulación Bohr (2n²)',
                  style: TextStyle(fontSize: 11.5)),
              selected: !_showChart,
              selectedColor: Colors.cyan.withValues(alpha: 0.3),
              onSelected: (_) => setState(() => _showChart = false),
            ),
            const SizedBox(width: 10),
            ChoiceChip(
              label: const Text('Gráfico Energético (ΔH)',
                  style: TextStyle(fontSize: 11.5)),
              selected: _showChart,
              selectedColor: Colors.amber.withValues(alpha: 0.3),
              onSelected: (_) => setState(() => _showChart = true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 215,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0D1322),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.25)),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _showChart
                    ? _ReactionEnergyGraphPainter(
                        progress: _controller.value,
                        isExothermic: widget.reaction.energia
                            .toLowerCase()
                            .contains('exo'),
                        deltaH: widget.reaction.deltaH,
                        ea: widget.reaction.energiaActivacion,
                      )
                    : _ReactionBohrPainter(
                        progress: _controller.value,
                        atoms: widget.atoms,
                        equation: widget.reaction.ecuacion,
                        bondType: widget.reaction.tipoEnlace,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReactionBohrPainter extends CustomPainter {
  final double progress;
  final List<ReactionAtomNode> atoms;
  final String equation;
  final String bondType;

  _ReactionBohrPainter({
    required this.progress,
    required this.atoms,
    required this.equation,
    required this.bondType,
  });

  List<int> _shellsForZ(int z) {
    final List<int> shells = [];
    int rem = z;
    int n = 1;
    while (rem > 0) {
      final cap = 2 * n * n;
      final count = math.min(rem, cap);
      shells.add(count);
      rem -= count;
      n++;
    }
    return shells;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.45;
    final atomA = atoms.isNotEmpty
        ? atoms.first
        : const ReactionAtomNode(symbol: 'Na', atomicNumber: 11);
    final atomB = atoms.length > 1
        ? atoms[1]
        : const ReactionAtomNode(symbol: 'O', atomicNumber: 8);

    // Oscilación suave entre reactivos separados y enlace formado
    final factor = (math.sin(progress * math.pi * 2 - math.pi / 2) + 1) / 2;
    final dist = 126.0 - (factor * 50.0);

    final centerA = Offset(size.width / 2 - dist / 2, cy);
    final centerB = Offset(size.width / 2 + dist / 2, cy);

    _drawAtom(canvas, centerA, atomA, Colors.amberAccent, progress * 2 * math.pi);
    _drawAtom(canvas, centerB, atomB, Colors.cyanAccent, -progress * 2 * math.pi);

    if (factor > 0.62) {
      final bondPaint = Paint()
        ..color = Colors.greenAccent.withValues(alpha: (factor - 0.62) * 2.4)
        ..strokeWidth = 2.4;
      canvas.drawLine(centerA, centerB, bondPaint);
    }

    final statusText = factor > 0.62
        ? 'Enlace ${bondType.toUpperCase()} activo → $equation'
        : 'Reactivos: ${atomA.symbol} (Z=${atomA.atomicNumber}) + ${atomB.symbol} (Z=${atomB.atomicNumber})';

    final tp = TextPainter(
      text: TextSpan(
        text: statusText,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);

    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 26));
  }

  void _drawAtom(Canvas canvas, Offset center, ReactionAtomNode atom,
      Color color, double baseAngle) {
    final shells = _shellsForZ(atom.atomicNumber);
    final orbitPaint = Paint()
      ..color = color.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (int i = 0; i < shells.length; i++) {
      final r = 16.0 + (i * 10.5);
      canvas.drawCircle(center, r, orbitPaint);
      final totalE = shells[i];
      for (int e = 0; e < totalE; e++) {
        final ang =
            baseAngle * (i.isEven ? 1 : -1) + (2 * math.pi * e / totalE);
        final ex = center.dx + r * math.cos(ang);
        final ey = center.dy + r * math.sin(ang);
        final isValence = i == shells.length - 1;
        canvas.drawCircle(
          Offset(ex, ey),
          isValence ? 3.4 : 2.2,
          Paint()..color = isValence ? Colors.white : color,
        );
      }
    }

    canvas.drawCircle(center, 10, Paint()..color = color.withValues(alpha: 0.85));
    final tp = TextPainter(
      text: TextSpan(
        text: atom.symbol,
        style: const TextStyle(
            color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _ReactionBohrPainter oldDelegate) => true;
}

class _ReactionEnergyGraphPainter extends CustomPainter {
  final double progress;
  final bool isExothermic;
  final double deltaH;
  final double ea;

  _ReactionEnergyGraphPainter({
    required this.progress,
    required this.isExothermic,
    required this.deltaH,
    required this.ea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const right = 18.0;
    const top = 22.0;
    const bottom = 30.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;

    final axisPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.3;
    canvas.drawLine(const Offset(left, top), Offset(left, top + h), axisPaint);
    canvas.drawLine(Offset(left, top + h), Offset(left + w, top + h), axisPaint);

    final startY = isExothermic ? top + h * 0.44 : top + h * 0.74;
    final peakY = top + h * 0.12;
    final endY = isExothermic ? top + h * 0.78 : top + h * 0.34;

    final path = Path();
    Offset? dot;

    for (int i = 0; i <= 100; i++) {
      final t = i / 100.0;
      final x = left + t * w;
      double y;
      if (t < 0.2) {
        y = startY;
      } else if (t < 0.5) {
        final lt = (t - 0.2) / 0.3;
        y = startY + (peakY - startY) * math.sin(lt * math.pi / 2);
      } else if (t < 0.8) {
        final lt = (t - 0.5) / 0.3;
        y = peakY + (endY - peakY) * (1 - math.cos(lt * math.pi / 2));
      } else {
        y = endY;
      }

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      if ((t - progress).abs() < 0.012) dot = Offset(x, y);
    }

    final color = isExothermic ? Colors.orangeAccent : Colors.lightBlueAccent;
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke,
    );

    if (dot != null) {
      canvas.drawCircle(dot, 5.5, Paint()..color = Colors.white);
    }

    _text(canvas, 'Energía (kJ/mol) | Ea: $ea', const Offset(10, 4), Colors.white60);
    _text(
      canvas,
      isExothermic
          ? 'Exotérmica (ΔH = $deltaH kJ/mol • Libera calor)'
          : 'Endotérmica (ΔH = +${deltaH.abs()} kJ/mol • Absorbe calor)',
      Offset(left + 6, top + h + 8),
      color,
    );
  }

  void _text(Canvas canvas, String str, Offset pos, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: str,
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _ReactionEnergyGraphPainter oldDelegate) => true;
}