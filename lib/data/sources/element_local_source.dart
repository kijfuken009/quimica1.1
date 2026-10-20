import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/element_model.dart';

class ElementLocalSource {
  Future<List<ElementModel>> getElements() async {
    try {
      final String response = await rootBundle.loadString('assets/data/elements.json');
      final List<dynamic> data = jsonDecode(response);
      return data.map((json) => ElementModel.fromJson(json)).toList();
    } on FormatException catch (e) {
      throw Exception("El archivo JSON tiene un formato inválido: $e");
    } catch (e) {
      throw Exception("No se pudo cargar el archivo en assets/data/elements.json: $e");
    }
  }
}