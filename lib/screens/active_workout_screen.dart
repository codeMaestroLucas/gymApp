import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/workout_history.dart';
import '../widgets/rest_timer_sheet.dart';
import '../services/storage_service.dart';
import '../services/exercise_image_service.dart';
import 'exercise_detail_screen.dart';
import '../theme/app_colors.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final Workout workout;
  final Function(Workout updatedWorkout) onWorkoutCompleted;

  const ActiveWorkoutScreen({
    super.key,
    required this.workout,
    required this.onWorkoutCompleted,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Stopwatch _stopwatch;
  Timer? _timer;
  late List<bool> _completedExercises;
  int _currentExerciseIndex = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() {});
    });
    _completedExercises =
        List.generate(widget.workout.exercises.length, (index) => false);
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsedTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _finishWorkout() async {
    _stopwatch.stop();
    final elapsedMinutes = mathMax(1, _stopwatch.elapsed.inMinutes);
    final completedCount =
        _completedExercises.where((done) => done).length;

    // Calcular volume executado
    double totalVolume = 0;
    for (int i = 0; i < widget.workout.exercises.length; i++) {
      if (_completedExercises[i]) {
        final ex = widget.workout.exercises[i];
        totalVolume += (ex.weightKg * ex.reps * ex.sets);
      }
    }
    if (totalVolume == 0) {
      totalVolume = widget.workout.estimatedTotalVolumeKg;
    }

    final newHistory = WorkoutHistoryEntry(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      workoutTitle: widget.workout.title,
      splitTag: widget.workout.splitTag,
      completedAt: DateTime.now(),
      durationMinutes: elapsedMinutes,
      totalVolumeKg: totalVolume,
      totalSets: widget.workout.totalSets,
      exercisesCount: completedCount > 0 ? completedCount : widget.workout.exercises.length,
      caloriesEstimated: (elapsedMinutes * 8.2).round(),
    );

    final historyList = StorageService().loadHistory();
    historyList.insert(0, newHistory);
    await StorageService().saveHistory(historyList);

    final updated = widget.workout.copyWith(
      lastCompletedAt: DateTime.now(),
      completionCount: widget.workout.completionCount + 1,
    );
    widget.onWorkoutCompleted(updated);

    if (mounted) {
      _showCompletionDialog(newHistory);
    }
  }

  int mathMax(int a, int b) => a > b ? a : b;

  void _showCompletionDialog(WorkoutHistoryEntry entry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.primaryOrange, size: 28),
              SizedBox(width: 10),
              Text('Treino Concluído!', style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parabéns pela dedicação! Seu progresso foi salvo no histórico de evolução.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildRowDetail('Duração total', '${entry.durationMinutes} minutos'),
                    const SizedBox(height: 8),
                    _buildRowDetail('Volume levantado', '${(entry.totalVolumeKg / 1000).toStringAsFixed(1)} toneladas'),
                    const SizedBox(height: 8),
                    _buildRowDetail('Calorias estimadas', '${entry.caloriesEstimated} kcal'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // fecha dialog
                Navigator.pop(context); // volta da tela ativa
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Concluir e Voltar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEx = widget.workout.exercises[_currentExerciseIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(widget.workout.splitTag.isNotEmpty
            ? 'Treino ${widget.workout.splitTag}'
            : 'Em Andamento'),
        actions: [
          TextButton.icon(
            onPressed: _finishWorkout,
            icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryOrange),
            label: const Text(
              'Finalizar',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cronômetro Ativo no Topo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: AppColors.cardBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TEMPO DE TREINO',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1)),
                    Text(
                      _formatElapsedTime(_stopwatch.elapsed),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    RestTimerSheet.show(
                      context,
                      initialSeconds: currentEx.restSeconds,
                      exerciseName: currentEx.name,
                    );
                  },
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: Text('Descanso (${currentEx.restSeconds}s)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundDark,
                    foregroundColor: AppColors.accentYellow,
                    side: const BorderSide(color: AppColors.accentYellow),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Exercícios Ativos com Checkbox e Ajuste de Carga
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.workout.exercises.length,
              itemBuilder: (context, index) {
                final ex = widget.workout.exercises[index];
                final isDone = _completedExercises[index];
                final isCurrent = index == _currentExerciseIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.cardBackground
                        : const Color(0xFF161212),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primaryOrange
                          : AppColors.cardBorder,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isDone,
                          activeColor: AppColors.primaryOrange,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          onChanged: (val) {
                            setState(() {
                              _completedExercises[index] = val ?? false;
                              if (val == true && index < widget.workout.exercises.length - 1) {
                                _currentExerciseIndex = index + 1;
                                RestTimerSheet.show(
                                  context,
                                  initialSeconds: ex.restSeconds,
                                  exerciseName: ex.name,
                                );
                              }
                            });
                          },
                        ),
                        // Miniatura da imagem oficial (ao clicar, abre vídeo e detalhes)
                        GestureDetector(
                          onTap: () {
                            ExerciseDetailModal.show(context, exercise: ex);
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ex.videoUrl != null
                                    ? AppColors.primaryOrange.withValues(alpha: 0.7)
                                    : AppColors.cardBorder,
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              ex.imageUrl ??
                                  ExerciseImageService.getImageForExercise(
                                    exerciseName: ex.name,
                                    primaryMuscleGroup: ex.primaryMuscleGroup,
                                    diagramType: ex.diagramType,
                                  ) ??
                                  'source/exercices/images/chest/Bench Press.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.fitness_center_rounded, size: 18, color: AppColors.primaryOrange),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      ex.name,
                      style: TextStyle(
                        color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '${ex.reps} reps • ${ex.weightKg.toStringAsFixed(ex.weightKg % 1 == 0 ? 0 : 1)} kg',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primaryOrange, size: 22),
                          tooltip: 'Ver vídeo de execução',
                          onPressed: () {
                            ExerciseDetailModal.show(context, exercise: ex);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.timer_outlined, color: AppColors.accentYellow, size: 20),
                          onPressed: () {
                            RestTimerSheet.show(
                              context,
                              initialSeconds: ex.restSeconds,
                              exerciseName: ex.name,
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() => _currentExerciseIndex = index);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
