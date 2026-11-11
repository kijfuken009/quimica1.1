class ReactionAtomNode {
  final String symbol;
  final int atomicNumber;
  final int count;
  final int valenceElectrons;

  const ReactionAtomNode({
    required this.symbol,
    required this.atomicNumber,
    this.count = 1,
    this.valenceElectrons = 1,
  });

  factory ReactionAtomNode.fromJson(Map<String, dynamic> json) {
    return ReactionAtomNode(
      symbol: json['symbol']?.toString() ?? 'H',
      atomicNumber: (json['atomicNumber'] as num?)?.toInt() ?? 1,
      count: (json['count'] as num?)?.toInt() ?? 1,
      valenceElectrons: (json['valenceElectrons'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'atomicNumber': atomicNumber,
        'count': count,
        'valenceElectrons': valenceElectrons,
      };
}

class ReactionModel {
  final String id;
  final int trimestre; // 1, 2 o 3
  final int numeroClase; // 1 al 36
  final String temaCurricular; // Ej: "Óxidos Básicos", "Hidróxidos", "Ácidos Oxácidos"
  final String nombre;
  final String tipo;
  final String tipoEnlace; // "iónico" o "covalente"
  final String ecuacion;
  final String reactivos;
  final String productos;
  final String explicacion;
  final String condiciones;
  final String energia; // "Exotérmica" o "Endotérmica"
  final double deltaH; // Entalpía en kJ/mol para graficar la curva
  final double energiaActivacion; // Pico de activación en kJ/mol
  final List<String> elementosRelacionados;
  final bool esPeligrosa;
  final String advertenciaSeguridad;
  final List<ReactionAtomNode> atomosReactivos;

  ReactionModel({
    required this.id,
    this.trimestre = 1,
    this.numeroClase = 1,
    this.temaCurricular = 'Reacciones Químicas',
    required this.nombre,
    required this.tipo,
    this.tipoEnlace = 'covalente',
    required this.ecuacion,
    required this.reactivos,
    required this.productos,
    required this.explicacion,
    required this.condiciones,
    required this.energia,
    this.deltaH = -150.0,
    this.energiaActivacion = 85.0,
    required this.elementosRelacionados,
    this.esPeligrosa = false,
    this.advertenciaSeguridad = '',
    this.atomosReactivos = const [],
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    final rawAtoms = json['atomosReactivos'] as List<dynamic>? ?? [];
    final energiaStr = json['energia']?.toString() ?? 'Exotérmica';
    final isExo = energiaStr.toLowerCase().contains('exo');

    return ReactionModel(
      id: json['id']?.toString() ?? '',
      trimestre: (json['trimestre'] as num?)?.toInt() ?? 1,
      numeroClase: (json['numeroClase'] as num?)?.toInt() ?? 1,
      temaCurricular: json['temaCurricular']?.toString() ?? 'Química General',
      nombre: json['nombre']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      tipoEnlace: json['tipoEnlace']?.toString() ?? 'covalente',
      ecuacion: json['ecuacion']?.toString() ?? '',
      reactivos: json['reactivos']?.toString() ?? '',
      productos: json['productos']?.toString() ?? '',
      explicacion: json['explicacion']?.toString() ?? '',
      condiciones: json['condiciones']?.toString() ?? '',
      energia: energiaStr,
      deltaH: (json['deltaH'] as num?)?.toDouble() ?? (isExo ? -180.0 : 140.0),
      energiaActivacion: (json['energiaActivacion'] as num?)?.toDouble() ?? 90.0,
      elementosRelacionados: List<String>.from(json['elementosRelacionados'] ?? []),
      esPeligrosa: json['esPeligrosa'] as bool? ?? false,
      advertenciaSeguridad: json['advertenciaSeguridad']?.toString() ?? '',
      atomosReactivos: rawAtoms
          .map((a) => ReactionAtomNode.fromJson(Map<String, dynamic>.from(a)))
          .toList(),
    );
  }
}