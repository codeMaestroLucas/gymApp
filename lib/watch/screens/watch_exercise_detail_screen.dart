import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../services/exercise_image_service.dart';
import '../widgets/watch_screen_container.dart';

/// Tela de visualização detalhada do exercício no Smartwatch
/// Exibe a imagem anatômica/técnica oficial do exercício, carga, repetições,
/// tempo de descanso e todas as observações registradas no celular.
class WatchExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  final bool isCircular;

  const WatchExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = exercise.imageUrl ??
        ExerciseImageService.getImageForExercise(
          exerciseName: exercise.name,
          primaryMuscleGroup: exercise.primaryMuscleGroup,
          diagramType: exercise.diagramType,
        ) ??
        'source/imgs/exercicies/peito/0.png';

    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchScreenContainer(
        isCircular: isCircular,
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

              // Imagem Oficial do Exercício Ampliada (source/imgs/exercicies)
              Container(
                height: 125,
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
                exercise.name,
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
                  exercise.primaryMuscleGroup.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Grid de Métricas (Carga e Repetições - máx 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      label: 'CARGA',
                      value: '${exercise.weightKg.toStringAsFixed(exercise.weightKg % 1 == 0 ? 0 : 1)} kg',
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildMetricPill(
                      label: 'REPETIÇÕES',
                      value: '${exercise.reps} reps',
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
                      'Descanso: ${exercise.restSeconds}s',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Observações do usuário / postura técnica (se houver)
              if (exercise.observations.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryOrange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes_rounded, size: 12, color: AppColors.primaryOrange),
                          SizedBox(width: 4),
                          Text(
                            'Observações:',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        exercise.observations,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
