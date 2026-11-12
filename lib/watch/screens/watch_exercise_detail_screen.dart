import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../services/exercise_image_service.dart';
import '../widgets/watch_screen_container.dart';
import '../../widgets/exercise_video_player.dart';

/// Tela de visualização detalhada do exercício no Smartwatch (Wear OS / watchOS).
/// Permite alternar entre imagem anatômica e vídeo da execução (caso exista),
/// além de verificar cargas, repetições, descanso e observações do atleta.
class WatchExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  final bool isCircular;

  const WatchExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.isCircular = true,
  });

  @override
  State<WatchExerciseDetailScreen> createState() => _WatchExerciseDetailScreenState();
}

class _WatchExerciseDetailScreenState extends State<WatchExerciseDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final imagePath = widget.exercise.imageUrl ??
        ExerciseImageService.getImageForExercise(
          exerciseName: widget.exercise.name,
          primaryMuscleGroup: widget.exercise.primaryMuscleGroup,
          diagramType: widget.exercise.diagramType,
        ) ??
        'source/exercices/images/chest/Bench Press.png';

    final videoPath = widget.exercise.videoUrl ??
        ExerciseImageService.getVideoForExercise(
          exerciseName: widget.exercise.name,
          primaryMuscleGroup: widget.exercise.primaryMuscleGroup,
          diagramType: widget.exercise.diagramType,
        );

    final hasVideo = videoPath != null && videoPath.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchScreenContainer(
        isCircular: widget.isCircular,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botão Voltar compacto
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          'Voltar',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Mídia Principal (Vídeo formato GIF em loop 1.25x ou Foto Limpa)
              if (hasVideo)
                ExerciseVideoPlayer(
                  videoPath: videoPath,
                  thumbnailPath: imagePath,
                  height: 118,
                  autoPlay: true,
                  looping: true,
                  playbackSpeed: 1.25,
                )
              else
                Container(
                  height: 118,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.6), width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.cardBackground,
                            child: const Center(
                              child: Icon(Icons.fitness_center_rounded, color: AppColors.primaryOrange, size: 36),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              // Nome do Exercício
              Text(
                widget.exercise.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Tag do Grupo Muscular
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.exercise.primaryMuscleGroup.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Grid de Métricas (Carga e Repetições)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      label: 'CARGA',
                      value: '${widget.exercise.weightKg.toStringAsFixed(widget.exercise.weightKg % 1 == 0 ? 0 : 1)} kg',
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMetricPill(
                      label: 'REPETIÇÕES',
                      value: '${widget.exercise.reps} reps',
                      color: AppColors.accentYellow,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Pill de Descanso
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      'Descanso: ${widget.exercise.restSeconds}s',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Observações se existirem
              if (widget.exercise.observations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'OBSERVAÇÃO',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.exercise.observations,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
