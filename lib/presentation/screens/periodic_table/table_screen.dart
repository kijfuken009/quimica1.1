import 'package:flutter/material.dart';
import '../../../data/repositories/element_repository_impl.dart';
import '../../../data/sources/element_local_source.dart';
import '../../../data/models/element_model.dart';
import 'element_detail_screen.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Instanciamos el repositorio para cargar los elementos
    final repo = ElementRepositoryImpl(ElementLocalSource());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tabla Periódica Galáctica"),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<ElementModel>>(
        future: repo.fetchAllElements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error al cargar elementos: ${snapshot.error}"));
          }

          final elements = snapshot.data ?? [];

          return InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.1,
            maxScale: 2.0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: elements.map((element) {
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ElementDetailScreen(element: element)),
                    ),
                    child: Container(
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.indigoAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${element.numero}", style: const TextStyle(fontSize: 10, color: Colors.white)),
                          Text(element.simbolo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}