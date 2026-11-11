import 'dart:convert';

class Exercise {
  final String id;
  final String name;
  final List<String> targetMuscles;
  final String primaryMuscleGroup; // 'chest', 'back', 'legs', 'shoulders', 'arms', 'core'
  double weightKg;
  int reps;
  int sets;
  int restSeconds;
  String observations;
  final String diagramType;
  final List<String> executionTips;
  String? imageUrl;
  bool isCompleted;

  Exercise({
    required this.id,
    required this.name,
    required this.targetMuscles,
    required this.primaryMuscleGroup,
    required this.weightKg,
    required this.reps,
    required this.sets,
    required this.restSeconds,
    this.observations = '',
    required this.diagramType,
    this.executionTips = const [],
    this.imageUrl,
    this.isCompleted = false,
  });

  Exercise copyWith({
    String? id,
    String? name,
    List<String>? targetMuscles,
    String? primaryMuscleGroup,
    double? weightKg,
    int? reps,
    int? sets,
    int? restSeconds,
    String? observations,
    String? diagramType,
    List<String>? executionTips,
    String? imageUrl,
    bool? isCompleted,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      primaryMuscleGroup: primaryMuscleGroup ?? this.primaryMuscleGroup,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      restSeconds: restSeconds ?? this.restSeconds,
      observations: observations ?? this.observations,
      diagramType: diagramType ?? this.diagramType,
      executionTips: executionTips ?? this.executionTips,
      imageUrl: imageUrl ?? this.imageUrl,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetMuscles': targetMuscles,
      'primaryMuscleGroup': primaryMuscleGroup,
      'weightKg': weightKg,
      'reps': reps,
      'sets': sets,
      'restSeconds': restSeconds,
      'observations': observations,
      'diagramType': diagramType,
      'executionTips': executionTips,
      'imageUrl': imageUrl,
      'isCompleted': isCompleted,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      targetMuscles: List<String>.from(map['targetMuscles'] ?? []),
      primaryMuscleGroup: map['primaryMuscleGroup'] ?? 'chest',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 20.0,
      reps: (map['reps'] as num?)?.toInt() ?? 10,
      sets: (map['sets'] as num?)?.toInt() ?? 3,
      restSeconds: (map['restSeconds'] as num?)?.toInt() ?? 60,
      observations: map['observations'] ?? '',
      diagramType: map['diagramType'] ?? 'bench_press',
      executionTips: List<String>.from(map['executionTips'] ?? []),
      imageUrl: map['imageUrl'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory Exercise.fromJson(String source) =>
      Exercise.fromMap(json.decode(source));
}
