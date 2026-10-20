import '../sources/element_local_source.dart';
import '../../domain/repositories/element_repository.dart';
import '../models/element_model.dart';

class ElementRepositoryImpl implements ElementRepository {
  final ElementLocalSource localSource;

  ElementRepositoryImpl(this.localSource);

  @override
  Future<List<ElementModel>> fetchAllElements() async {
    // Aquí podrías añadir lógica de caché o seguridad adicional
    return await localSource.getElements();
  }
}