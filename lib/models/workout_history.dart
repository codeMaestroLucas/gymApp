import 'dart:convert';

class WorkoutHistoryEntry {
  final String id;
  final String workoutTitle;
  final String splitTag;
  final DateTime completedAt;
  final int durationMinutes;
  final double totalVolumeKg;
  final int totalSets;
  final int exercisesCount;
  final int caloriesEstimated;

  WorkoutHistoryEntry({
    required this.id,
    required this.workoutTitle,
    required this.splitTag,
    required this.completedAt,
    required this.durationMinutes,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.exercisesCount,
    this.caloriesEstimated = 320,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutTitle': workoutTitle,
      'splitTag': splitTag,
      'completedAt': completedAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalVolumeKg': totalVolumeKg,
      'totalSets': totalSets,
      'exercisesCount': exercisesCount,
      'caloriesEstimated': caloriesEstimated,
    };
  }

  factory WorkoutHistoryEntry.fromMap(Map<String, dynamic> map) {
    return WorkoutHistoryEntry(
      id: map['id'] ?? '',
      workoutTitle: map['workoutTitle'] ?? '',
      splitTag: map['splitTag'] ?? '',
      completedAt: DateTime.tryParse(map['completedAt'] ?? '') ?? DateTime.now(),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 45,
      totalVolumeKg: (map['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
      totalSets: (map['totalSets'] as num?)?.toInt() ?? 12,
      exercisesCount: (map['exercisesCount'] as num?)?.toInt() ?? 4,
      caloriesEstimated: (map['caloriesEstimated'] as num?)?.toInt() ?? 300,
    );
  }

  String toJson() => json.encode(toMap());

  factory WorkoutHistoryEntry.fromJson(String source) =>
      WorkoutHistoryEntry.fromMap(json.decode(source));
}

class PersonalRecord {
  final String exerciseName;
  final double weightKg;
  final int reps;
  final DateTime achievedAt;
  final String muscleGroup;

  PersonalRecord({
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.achievedAt,
    required this.muscleGroup,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'weightKg': weightKg,
      'reps': reps,
      'achievedAt': achievedAt.toIso8601String(),
      'muscleGroup': muscleGroup,
    };
  }

  factory PersonalRecord.fromMap(Map<String, dynamic> map) {
    return PersonalRecord(
      exerciseName: map['exerciseName'] ?? '',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      reps: (map['reps'] as num?)?.toInt() ?? 1,
      achievedAt: DateTime.tryParse(map['achievedAt'] ?? '') ?? DateTime.now(),
      muscleGroup: map['muscleGroup'] ?? 'Geral',
    );
  }

  String toJson() => json.encode(toMap());

  factory PersonalRecord.fromJson(String source) =>
      PersonalRecord.fromMap(json.decode(source));
}
