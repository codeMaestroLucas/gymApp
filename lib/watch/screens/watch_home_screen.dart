import 'package:flutter/material.dart';
import '../../models/workout.dart';
import '../../theme/app_colors.dart';
import '../../services/watch_sync_service.dart';
import '../widgets/watch_screen_container.dart';
import 'watch_workout_overview_screen.dart';
import 'watch_active_workout_screen.dart';

/// Tela Inicial do Smartwatch (Wear OS / watchOS)
/// Exibe a lista reativa de treinos sincronizados do celular em tempo real.
/// Qualquer alteração feita no aplicativo mobile (IA, exclusão, edição) reflete aqui instantaneamente.
class WatchHomeScreen extends StatelessWidget {
  final bool isCircular;

  const WatchHomeScreen({
    super.key,
    this.isCircular = true,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchScreenContainer(
        isCircular: isCircular,
        child: Column(
          children: [
            // Header do Relógio: Hora atual e Status de Sincronização
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: WatchSyncService.instance.isSynced,
                  builder: (context, synced, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: synced ? const Color(0xFF00E676) : AppColors.accentYellow,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          synced ? 'Sincronizado' : 'Atualizando',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: synced ? const Color(0xFF00E676) : AppColors.accentYellow,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Título
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center_rounded, size: 12, color: AppColors.primaryOrange),
                SizedBox(width: 4),
                Text(
                  'SEUS TREINOS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Lista Reativa de Treinos
            Expanded(
              child: ValueListenableBuilder<List<Workout>>(
                valueListenable: WatchSyncService.instance.workoutsNotifier,
                builder: (context, workouts, _) {
                  if (workouts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sync_rounded, size: 28, color: AppColors.primaryOrange.withValues(alpha: 0.7)),
                            const SizedBox(height: 6),
                            const Text(
                              'Aguardando treinos do celular...',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: workouts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final workout = workouts[index];

                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WatchWorkoutOverviewScreen(
                                workout: workout,
                                isCircular: isCircular,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.cardBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Badge da Divisão (Split Tag A, B, C...)
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    workout.splitTag,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Título e Detalhes
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workout.title,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${workout.exercises.length} ex • ~${workout.durationMinutes} min',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Botão Play Rápido
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WatchActiveWorkoutScreen(
                                        workout: workout,
                                        isCircular: isCircular,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 16,
                                    color: AppColors.primaryOrange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
