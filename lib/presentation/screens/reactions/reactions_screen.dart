import 'dart:convert';
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
  String _selectedType = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = [
    'Todos',
    'Combustión',
    'Ácido-Base',
    'Síntesis',
    'Descomposición',
    'Desplazamiento',
    'Doble Desplazamiento',
  ];

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
            reac.productos.toLowerCase().contains(query);

        final matchesType = _selectedType == 'Todos' || reac.tipo.toLowerCase() == _selectedType.toLowerCase();

        return matchesQuery && matchesType;
      }).toList();
    });
  }

  void _showReactionDetailsModal(ReactionModel reaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
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
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Título
                  Text(
                    reaction.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

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
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
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
                                      : "Solo puede ser realizada con la supervisión de un adulto o profesional de laboratorio.",
                                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
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
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reaction.advertenciaSeguridad.isNotEmpty
                                  ? reaction.advertenciaSeguridad
                                  : "Reacción segura para estudio escolar teórico y práctico.",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildDetailSection(
                    title: "Ecuación Balanceada",
                    child: _buildBadge(reaction.ecuacion, fontSize: 16, isHighlight: true),
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
                    title: "Tipo de Reacción",
                    child: _buildBadge(reaction.tipo),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailSection(
                    title: "Explicación",
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reaction.explicacion,
                        style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
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
                    title: "Energía Liberada / Absorbida",
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reaction.energia,
                        style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
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
        title: const Text("Reacciones Químicas"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filter(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Buscar reacción (ej. Agua, C, H₂)...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Chips horizontales de categorías
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              "Tipos de Reacción",
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = _types[index];
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
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
                      setState(() {
                        _selectedType = type;
                      });
                      _filter();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              "Todas las Reacciones (${_filteredReactions.length})",
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),

          // Lista de tarjetas de reacciones
          Expanded(
            child: _filteredReactions.isEmpty
                ? const Center(
                    child: Text(
                      "No se encontraron reacciones",
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredReactions.length,
                    itemBuilder: (context, index) {
                      final reac = _filteredReactions[index];
                      return _buildReactionCard(reac);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionCard(ReactionModel reac) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reac.esPeligrosa ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white12,
          width: reac.esPeligrosa ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(reac.esPeligrosa ? "⚠️" : "🔥", style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reac.nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (reac.esPeligrosa)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Text(
                    "PELIGROSO",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reac.tipo.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Caja de ecuación balanceada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ecuación Balanceada:",
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  reac.ecuacion,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Explicación corta
          const Text("Explicación:", style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            reac.explicacion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 12),

          // Condiciones y Energía
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Condiciones:", style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text(
                      reac.condiciones,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Energía:", style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      reac.energia,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Botón Ver Detalles
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: reac.esPeligrosa ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white24,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showReactionDetailsModal(reac),
              child: const Text("Ver Detalles"),
            ),
          ),
        ],
      ),
    );
  }
}