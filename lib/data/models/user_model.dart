class UserModel {
  final String name;
  final int age;
  final int chemistryLevel;
  final int totalPoints;
  final int unlockedLevel;
  final Map<int, int> classScores;
  final List<dynamic> surpriseExams;

  UserModel({
    required this.name,
    required this.age,
    this.chemistryLevel = 1,
    this.totalPoints = 0,
    this.unlockedLevel = 1,
    this.classScores = const {},
    this.surpriseExams = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'level': chemistryLevel,
      'points': totalPoints,
      'unlockedLevel': unlockedLevel,
      'classScores': classScores.map((k, v) => MapEntry(k.toString(), v)),
      'surpriseExams': surpriseExams,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      final rawScores = json['classScores'] as Map<String, dynamic>? ?? {};
      final Map<int, int> parsedScores = {};
      rawScores.forEach((key, value) {
        final k = int.tryParse(key);
        if (k != null) {
          parsedScores[k] = (value as num?)?.toInt() ?? 0;
        }
      });

      final List<dynamic> rawSurprise =
          List<dynamic>.from(json['surpriseExams'] ?? []);

      return UserModel(
        name: json['name'] as String? ?? "Estudiante Anónimo",
        age: json['age'] as int? ?? 12,
        chemistryLevel: json['level'] as int? ?? 1,
        totalPoints: json['points'] as int? ?? 0,
        unlockedLevel: json['unlockedLevel'] as int? ?? 1,
        classScores: parsedScores,
        surpriseExams: rawSurprise,
      );
    } catch (e) {
      return UserModel(name: "Usuario", age: 12);
    }
  }

  UserModel copyWith({
    String? name,
    int? age,
    int? chemistryLevel,
    int? totalPoints,
    int? unlockedLevel,
    Map<int, int>? classScores,
    List<dynamic>? surpriseExams,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      chemistryLevel: chemistryLevel ?? this.chemistryLevel,
      totalPoints: totalPoints ?? this.totalPoints,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      classScores: classScores ?? this.classScores,
      surpriseExams: surpriseExams ?? this.surpriseExams,
    );
  }
}