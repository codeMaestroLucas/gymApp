import 'dart:convert';
import 'exercise.dart';

class Workout {
  final String id;
  final String title;
  final String splitTag; // ex: 'A', 'B', 'C', 'Upper', 'Lower'
  final String targetMusclesSummary;
  final int durationMinutes;
  final List<String> daysOfWeek;
  final List<Exercise> exercises;
  final String description;
  final bool aiGenerated;
  final String aiPrompt;
  DateTime? lastCompletedAt;
  int completionCount;

  Workout({
    required this.id,
    required this.title,
    required this.splitTag,
    required this.targetMusclesSummary,
    required this.durationMinutes,
    this.daysOfWeek = const [],
    required this.exercises,
    this.description = '',
    this.aiGenerated = true,
    this.aiPrompt = '',
    this.lastCompletedAt,
    this.completionCount = 0,
  });

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  double get estimatedTotalVolumeKg =>
      exercises.fold(0.0, (sum, e) => sum + (e.weightKg * e.reps * e.sets));

  Workout copyWith({
    String? id,
    String? title,
    String? splitTag,
    String? targetMusclesSummary,
    int? durationMinutes,
    List<String>? daysOfWeek,
    List<Exercise>? exercises,
    String? description,
    bool? aiGenerated,
    String? aiPrompt,
    DateTime? lastCompletedAt,
    int? completionCount,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      splitTag: splitTag ?? this.splitTag,
      targetMusclesSummary: targetMusclesSummary ?? this.targetMusclesSummary,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      exercises: exercises ?? this.exercises,
      description: description ?? this.description,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      aiPrompt: aiPrompt ?? this.aiPrompt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      completionCount: completionCount ?? this.completionCount,
    );
  }

  Workout clone() {
    return copyWith(
      exercises: exercises.map((e) => e.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'splitTag': splitTag,
      'targetMusclesSummary': targetMusclesSummary,
      'durationMinutes': durationMinutes,
      'daysOfWeek': daysOfWeek,
      'exercises': exercises.map((x) => x.toMap()).toList(),
      'description': description,
      'aiGenerated': aiGenerated,
      'aiPrompt': aiPrompt,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'completionCount': completionCount,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      splitTag: map['splitTag'] ?? 'A',
      targetMusclesSummary: map['targetMusclesSummary'] ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 50,
      daysOfWeek: List<String>.from(map['daysOfWeek'] ?? []),
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((x) => Exercise.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      description: map['description'] ?? '',
      aiGenerated: map['aiGenerated'] ?? false,
      aiPrompt: map['aiPrompt'] ?? '',
      lastCompletedAt: map['lastCompletedAt'] != null
          ? DateTime.tryParse(map['lastCompletedAt'])
          : null,
      completionCount: (map['completionCount'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Workout.fromJson(String source) =>
      Workout.fromMap(json.decode(source));
}
