class ReactionModel {
  final String id;
  final String nombre;
  final String tipo;
  final String ecuacion;
  final String reactivos;
  final String productos;
  final String explicacion;
  final String condiciones;
  final String energia;
  final List<String> elementosRelacionados;
  final bool esPeligrosa;
  final String advertenciaSeguridad;

  ReactionModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.ecuacion,
    required this.reactivos,
    required this.productos,
    required this.explicacion,
    required this.condiciones,
    required this.energia,
    required this.elementosRelacionados,
    this.esPeligrosa = false,
    this.advertenciaSeguridad = '',
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      ecuacion: json['ecuacion'] ?? '',
      reactivos: json['reactivos'] ?? '',
      productos: json['productos'] ?? '',
      explicacion: json['explicacion'] ?? '',
      condiciones: json['condiciones'] ?? '',
      energia: json['energia'] ?? '',
      elementosRelacionados: List<String>.from(json['elementosRelacionados'] ?? []),
      esPeligrosa: json['esPeligrosa'] as bool? ?? false,
      advertenciaSeguridad: json['advertenciaSeguridad'] ?? '',
    );
  }
}