import 'package:equatable/equatable.dart';

/// [ElementEntity] representa la esencia de un elemento químico en la aplicación.
/// Heredamos de Equatable para permitir comparaciones seguras entre objetos,
/// lo cual es vital para las pruebas de seguridad y unitarias en proyectos universitarios.
class ElementEntity extends Equatable {
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

  const ElementEntity({
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

  // El método toString es fundamental para el debugging y el logging de seguridad
  @override
  String toString() {
    return 'ElementEntity(numero: $numero, simbolo: $simbolo, nombre: $nombre)';
  }

  @override
  List<Object?> get props => [
        numero,
        simbolo,
        nombre,
        peso,
        categoria,
        descripcion,
        descubrimiento,
        uso,
        modelo,
        datoCurioso,
      ];
}