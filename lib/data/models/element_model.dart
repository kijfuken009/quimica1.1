import '../../domain/entities/element_entity.dart';

class ElementModel {
  final int numero;
  final String simbolo;
  final String nombre;
  final String peso;
  final String categoria;
  final String descripcion;
  final String descubrimiento;
  final String uso;
  final String modelo;
  final String datoCurioso;

  ElementModel({
    required this.numero,
    required this.simbolo,
    required this.nombre,
    required this.peso,
    required this.categoria,
    required this.descripcion,
    required this.descubrimiento,
    required this.uso,
    required this.modelo,
    required this.datoCurioso,
  });

  factory ElementModel.fromJson(Map<String, dynamic> json) {
    // Lectura directa de las llaves en español del JSON
    final rawNumero = json['numero'] ?? json['number'] ?? 0;

    return ElementModel(
      numero: rawNumero is num ? rawNumero.toInt() : int.tryParse(rawNumero.toString()) ?? 0,
      simbolo: (json['simbolo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      peso: (json['weight'] ?? json['peso'] ?? '').toString(),
      categoria: (json['categoria'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      descubrimiento: (json['discovery'] ?? json['descubrimiento'] ?? '').toString(),
      uso: (json['uso'] ?? '').toString(),
      modelo: (json['model'] ?? json['modelo'] ?? '').toString(),
      datoCurioso: (json['DatoCurioso'] ?? json['dato_curioso'] ?? '').toString(),
    );
  }

  // Convierte el modelo de datos en una entidad de dominio en español
  ElementEntity toEntity() {
    return ElementEntity(
      numero: numero,
      simbolo: simbolo,
      nombre: nombre,
      peso: peso,
      categoria: categoria,
      descripcion: descripcion,
      descubrimiento: descubrimiento,
      uso: uso,
      modelo: modelo,
      datoCurioso: datoCurioso,
    );
  }
}