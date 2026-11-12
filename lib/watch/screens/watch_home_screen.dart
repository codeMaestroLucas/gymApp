import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/workout.dart';
import '../../theme/app_colors.dart';
import '../../services/watch_sync_service.dart';
import '../widgets/watch_screen_container.dart';
import 'watch_workout_overview_screen.dart';
import 'watch_active_workout_screen.dart';

/// Tela Inicial do Smartwatch (Wear OS / watchOS)
/// Exibe a lista reativa de treinos sincronizados do celular em tempo real.
/// Qualquer alteração feita no aplicativo mobile (IA, exclusão, edição) reflete aqui instantaneamente.
/// Suporta pull-to-refresh, auto-sync ao retomar app e toque no status para sincronização forçada.
class WatchHomeScreen extends StatefulWidget {
  final bool isCircular;

  const WatchHomeScreen({
    super.key,
    this.isCircular = true,
  });

  @override
  State<WatchHomeScreen> createState() => _WatchHomeScreenState();
}

class _WatchHomeScreenState extends State<WatchHomeScreen> with WidgetsBindingObserver {
  bool _isManualSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _triggerAutoSync();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sempre que o usuário levantar o pulso ou reabrir o app no relógio, sincroniza
      _triggerAutoSync();
    }
  }

  void _triggerAutoSync() {
    WatchSyncService.instance.syncFromAllSources();
  }

  Future<void> _handleManualSync() async {
    if (_isManualSyncing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isManualSyncing = true);

    final success = await WatchSyncService.instance.syncFromAllSources();

    if (mounted) {
      setState(() => _isManualSyncing = false);
      final count = WatchSyncService.instance.workoutsNotifier.value.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1A1A),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: success ? const Color(0xFF00E676) : AppColors.accentYellow,
                size: 13,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  success
                      ? '$count treinos atualizados!'
                      : 'Usando cache local do relógio',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchScreenContainer(
        isCircular: widget.isCircular,
        child: Column(
          children: [
            // Header do Relógio: Hora atual e Status Interativo de Sincronização
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Botão / Pill de Sincronização clicável compacto para tela de 192dp
                Flexible(
                  child: InkWell(
                    onTap: _handleManualSync,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isManualSyncing
                              ? AppColors.primaryOrange
                              : AppColors.cardBorder,
                          width: 0.8,
                        ),
                      ),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: WatchSyncService.instance.isSynced,
                        builder: (context, synced, _) {
                          final isBusy = _isManualSyncing || !synced;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBusy)
                                const SizedBox(
                                  width: 6,
                                  height: 6,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                                  ),
                                )
                              else
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00E676),
                                  ),
                                ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  isBusy ? 'Sync...' : 'Sincronizado',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: isBusy ? AppColors.accentYellow : const Color(0xFF00E676),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
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

            // Lista Reativa de Treinos com suporte a Pull-to-Refresh
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
                            Icon(Icons.sync_rounded, size: 26, color: AppColors.primaryOrange.withValues(alpha: 0.8)),
                            const SizedBox(height: 6),
                            const Text(
                              'Aguardando treinos do celular...',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _handleManualSync,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Sincronizar',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => WatchSyncService.instance.syncFromAllSources(),
                    color: AppColors.primaryOrange,
                    backgroundColor: AppColors.cardBackground,
                    strokeWidth: 2,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                                  isCircular: widget.isCircular,
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
                                          isCircular: widget.isCircular,
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
                    ),
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
