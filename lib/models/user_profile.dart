import 'dart:convert';

class UserProfile {
  final String name;
  final double weightKg;
  final double heightCm;
  final String routine; // ex: 'Escritório / Sedentário', 'Ativo', 'Rotina moderada'
  final String objective; // ex: 'Hipertrofia', 'Definição e Emagrecimento', 'Força Máxima', 'Resistência'
  final String experienceLevel; // 'Iniciante', 'Intermediário', 'Avançado'
  final String limitations; // ex: 'Desconforto no ombro esquerdo', 'Nenhuma'
  final int defaultDaysPerWeek;
  final int defaultDurationMinutes;

  UserProfile({
    required this.name,
    required this.weightKg,
    required this.heightCm,
    required this.routine,
    required this.objective,
    required this.experienceLevel,
    required this.limitations,
    this.defaultDaysPerWeek = 4,
    this.defaultDurationMinutes = 60,
  });

  double get bmi {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  String get bmiClassification {
    final val = bmi;
    if (val < 18.5) return 'Abaixo do peso';
    if (val < 25.0) return 'Peso saudável';
    if (val < 30.0) return 'Sobrepeso';
    return 'Obesidade';
  }

  UserProfile copyWith({
    String? name,
    double? weightKg,
    double? heightCm,
    String? routine,
    String? objective,
    String? experienceLevel,
    String? limitations,
    int? defaultDaysPerWeek,
    int? defaultDurationMinutes,
  }) {
    return UserProfile(
      name: name ?? this.name,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      routine: routine ?? this.routine,
      objective: objective ?? this.objective,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      limitations: limitations ?? this.limitations,
      defaultDaysPerWeek: defaultDaysPerWeek ?? this.defaultDaysPerWeek,
      defaultDurationMinutes: defaultDurationMinutes ?? this.defaultDurationMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'routine': routine,
      'objective': objective,
      'experienceLevel': experienceLevel,
      'limitations': limitations,
      'defaultDaysPerWeek': defaultDaysPerWeek,
      'defaultDurationMinutes': defaultDurationMinutes,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? 'Atleta',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 78.5,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 178.0,
      routine: map['routine'] ?? 'Rotina moderada com trabalho em escritório',
      objective: map['objective'] ?? 'Hipertrofia Muscular',
      experienceLevel: map['experienceLevel'] ?? 'Intermediário',
      limitations: map['limitations'] ?? 'Sem limitações articulares graves',
      defaultDaysPerWeek: (map['defaultDaysPerWeek'] as num?)?.toInt() ?? 4,
      defaultDurationMinutes: (map['defaultDurationMinutes'] as num?)?.toInt() ?? 60,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));

  static UserProfile defaultProfile() {
    return UserProfile(
      name: 'Lucas Rajão',
      weightKg: 80.5,
      heightCm: 180.0,
      routine: 'Dia a dia moderado (computador + deslocamento ativo)',
      objective: 'Hipertrofia & Força Muscular',
      experienceLevel: 'Intermediário',
      limitations: 'Atenção aos ligamentos do ombro em cargas máximas',
      defaultDaysPerWeek: 4,
      defaultDurationMinutes: 60,
    );
  }
}
