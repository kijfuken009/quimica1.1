/// [UserModel] representa la información del estudiante.
/// Implementamos métodos de serialización para permitir la persistencia
/// de datos en el dispositivo mediante SharedPreferences o SQLite.
class UserModel {
  final String name;
  final int age;
  final int chemistryLevel; // 1: Principiante, 2: Intermedio, 3: Avanzado

  UserModel({
    required this.name,
    required this.age,
    this.chemistryLevel = 1,
  });

  /// Convierte el objeto UserModel a un mapa de datos.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'level': chemistryLevel,
    };
  }

  /// Crea un objeto UserModel a partir de un mapa.
  /// Incluye validaciones básicas y valores por defecto para evitar caídas de la app.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        name: json['name'] as String? ?? "Estudiante Anónimo",
        age: json['age'] as int? ?? 12,
        chemistryLevel: json['level'] as int? ?? 1,
      );
    } catch (e) {
      // En caso de corrupción de datos, devolvemos un usuario básico
      return UserModel(name: "Usuario", age: 12);
    }
  }

  /// Permite crear una copia del usuario modificando sólo ciertos campos.
  UserModel copyWith({
    String? name,
    int? age,
    int? chemistryLevel,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      chemistryLevel: chemistryLevel ?? this.chemistryLevel,
    );
  }
}