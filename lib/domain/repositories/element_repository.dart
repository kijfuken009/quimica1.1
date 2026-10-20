import '../../data/models/element_model.dart';

abstract class ElementRepository {
  Future<List<ElementModel>> fetchAllElements();
}