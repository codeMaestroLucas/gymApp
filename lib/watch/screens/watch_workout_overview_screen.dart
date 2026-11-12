import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../theme/app_colors.dart';
import '../../services/exercise_image_service.dart';
import '../../services/watch_sync_service.dart';
import '../widgets/watch_screen_container.dart';
import 'watch_exercise_detail_screen.dart';
import 'watch_active_workout_screen.dart';

/// Tela de Visão Geral do Treino no Smartwatch
/// Permite ao atleta inspecionar todos os exercícios gerados pela IA ou celular,
/// verificar cargas, repetições, imagens oficiais, observações e iniciar a sessão.
class WatchWorkoutOverviewScreen extends StatelessWidget {
  final Workout workout;
  final bool isCircular;

  const WatchWorkoutOverviewScreen({
    super.key,
    required this.workout,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Workout>>(
      valueListenable: WatchSyncService.instance.workoutsNotifier,
      builder: (context, workouts, _) {
        final currentWorkout = workouts.firstWhere(
          (w) => w.id == workout.id,
          orElse: () => workout,
        );

        return Scaffold(
          backgroundColor: Colors.black,
          body: WatchScreenContainer(
            isCircular: isCircular,
            child: Column(
              children: [
                // Header com botão voltar e Split Tag
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        currentWorkout.splitTag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        currentWorkout.title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Informações rápidas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${currentWorkout.exercises.length} exercícios',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const Text(' • ', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(
                      '~${currentWorkout.durationMinutes} min',
                      style: const TextStyle(fontSize: 10, color: AppColors.accentYellow, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Lista de Exercícios com Imagens Maiores (Visão Clara sem precisar clicar)
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 2, bottom: 6),
                    itemCount: currentWorkout.exercises.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final ex = currentWorkout.exercises[index];
                      final imagePath = ex.imageUrl ??
                          ExerciseImageService.getImageForExercise(
                            exerciseName: ex.name,
                            primaryMuscleGroup: ex.primaryMuscleGroup,
                            diagramType: ex.diagramType,
                          ) ??
                          'source/exercices/images/chest/Bench Press.png';

                      final videoPath = ex.videoUrl ??
                          ExerciseImageService.getVideoForExercise(
                            exerciseName: ex.name,
                            primaryMuscleGroup: ex.primaryMuscleGroup,
                            diagramType: ex.diagramType,
                          );
                      final hasVideo = videoPath != null && videoPath.isNotEmpty;

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WatchExerciseDetailScreen(
                                exercise: ex,
                                isCircular: isCircular,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cardBorder, width: 1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Imagem Anatômica / Técnica Grande do Exercício (source/imgs/exercicies)
                              Container(
                                height: 82,
                                width: double.infinity,
                                color: AppColors.backgroundDark,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Image.asset(
                                          imagePath,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(
                                              Icons.fitness_center_rounded,
                                              size: 30,
                                              color: AppColors.primaryOrange,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Tag do grupo muscular
                                    Positioned(
                                      top: 4,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.75),
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(
                                            color: AppColors.primaryOrange.withValues(alpha: 0.5),
                                            width: 0.6,
                                          ),
                                        ),
                                        child: Text(
                                          ex.primaryMuscleGroup.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primaryOrange,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (hasVideo)
                                      Positioned(
                                        bottom: 4,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryOrange,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.play_arrow_rounded, size: 9, color: Colors.white),
                                              Text(
                                                'VÍDEO',
                                                style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (ex.observations.trim().isNotEmpty)
                                      Positioned(
                                        top: 4,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentYellow.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.edit_note_rounded,
                                            size: 11,
                                            color: AppColors.accentYellow,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Informações do Exercício (Nome + Séries & Carga Unificados)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Repetições e Peso (máx 3 reps)
                                        Text(
                                          '${ex.reps} reps • ${ex.weightKg.toStringAsFixed(ex.weightKg % 1 == 0 ? 0 : 1)} kg',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primaryOrange,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '${ex.restSeconds}s rest',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (hasVideo)
                                      Positioned(
                                        bottom: 4,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryOrange,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.play_arrow_rounded, size: 9, color: Colors.white),
                                              Text(
                                                'VÍDEO',
                                                style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (ex.observations.trim().isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        ex.observations,
                                        style: const TextStyle(
                                          fontSize: 8.5,
                                          color: AppColors.accentYellow,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // Botão Iniciar Treino
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WatchActiveWorkoutScreen(
                            workout: currentWorkout,
                            isCircular: isCircular,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'INICIAR TREINO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
