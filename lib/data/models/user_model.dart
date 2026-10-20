/// [UserModel] representa la información del estudiante.
/// Implementamos métodos de serialización para permitir la persistencia
/// de datos en el dispositivo mediante SharedPreferences.
class UserModel {
  final String name;
  final int age;
  final int chemistryLevel; // 1: Principiante, 2: Intermedio, 3: Avanzado
  final int totalPoints;
  final int unlockedLevel;

  UserModel({
    required this.name,
    required this.age,
    this.chemistryLevel = 1,
    this.totalPoints = 0,
    this.unlockedLevel = 1,
  });

  /// Convierte el objeto UserModel a un mapa de datos.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'level': chemistryLevel,
      'points': totalPoints,
      'unlockedLevel': unlockedLevel,
    };
  }

  /// Crea un objeto UserModel a partir de un mapa.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserModel(
        name: json['name'] as String? ?? "Estudiante Anónimo",
        age: json['age'] as int? ?? 12,
        chemistryLevel: json['level'] as int? ?? 1,
        totalPoints: json['points'] as int? ?? 0,
        unlockedLevel: json['unlockedLevel'] as int? ?? 1,
      );
    } catch (e) {
      return UserModel(name: "Usuario", age: 12);
    }
  }

  /// Permite crear una copia del usuario modificando sólo ciertos campos.
  UserModel copyWith({
    String? name,
    int? age,
    int? chemistryLevel,
    int? totalPoints,
    int? unlockedLevel,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      chemistryLevel: chemistryLevel ?? this.chemistryLevel,
      totalPoints: totalPoints ?? this.totalPoints,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
    );
  }
}