import 'package:flutter/material.dart';
import '../../../data/repositories/element_repository_impl.dart';
import '../../../data/sources/element_local_source.dart';
import '../../../data/models/element_model.dart';
import 'element_detail_screen.dart';

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  List<ElementModel> allElements = [];
  List<ElementModel> filteredElements = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadElements();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Carga inicial de datos
  Future<void> _loadElements() async {
    final repo = ElementRepositoryImpl(ElementLocalSource());
    final elements = await repo.fetchAllElements();
    if (!mounted) return;
    setState(() {
      allElements = elements;
      filteredElements = elements;
    });
  }

  // Lógica del buscador en tiempo real (busca por nombre o símbolo en español)
  void _filterElements(String query) {
    setState(() {
      filteredElements = allElements
          .where((el) =>
              el.nombre.toLowerCase().contains(query.toLowerCase()) ||
              el.simbolo.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // Asignación de colores según la categoría (soporta inglés y español)
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase().trim()) {
      case 'alkali':
      case 'alcalino':
        return Colors.redAccent;
      case 'alkaline':
      case 'alkaline-earth':
      case 'alcalinoterreo':
      case 'alcalinotérreo':
        return Colors.orangeAccent;
      case 'transition':
      case 'transicion':
      case 'transición':
        return Colors.amberAccent;
      case 'post-transition':
      case 'post-transicion':
      case 'post-transición':
        return Colors.greenAccent;
      case 'metalloid':
      case 'metaloide':
        return Colors.tealAccent;
      case 'non-metal':
      case 'no metal':
      case 'no-metal':
        return Colors.lightBlueAccent;
      case 'noble':
      case 'gas noble':
      case 'noble gas':
        return Colors.purpleAccent;
      case 'lanthanide':
      case 'lantanido':
      case 'lantánido':
        return Colors.pinkAccent;
      case 'actinide':
      case 'actinido':
      case 'actínido':
        return Colors.deepOrangeAccent;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tabla Periódica"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: searchController,
              onChanged: _filterElements,
              decoration: InputDecoration(
                hintText: "Buscar elemento (ej: Oxígeno, O)...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.5,
              maxScale: 2.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: filteredElements.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          "No se encontraron elementos",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: filteredElements
                            .map((element) => _buildElementCell(element))
                            .toList(),
                      ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Celda interactiva de cada elemento
  Widget _buildElementCell(ElementModel element) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ElementDetailScreen(element: element),
        ),
      ),
      child: Container(
        width: 65,
        height: 80,
        decoration: BoxDecoration(
          color: _getCategoryColor(element.categoria),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white70, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${element.numero}",
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              element.simbolo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                element.nombre,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}