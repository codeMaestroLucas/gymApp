import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_image_service.dart';
import '../theme/app_colors.dart';
import '../widgets/exercise_video_player.dart';
import '../widgets/rest_timer_sheet.dart';

/// Modal e Tela Completa de Detalhes do Exercício.
/// Ao clicar na imagem de um exercício em qualquer tela do app,
/// esta tela é exibida apresentando os detalhes completos, parâmetros de carga/reps,
/// e o vídeo oficial de execução caso exista em source/exercices/videos.
class ExerciseDetailModal extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise updated)? onExerciseUpdated;

  const ExerciseDetailModal({
    super.key,
    required this.exercise,
    this.onExerciseUpdated,
  });

  /// Método estático para exibir como Bottom Sheet elegante e moderna
  static Future<void> show(
    BuildContext context, {
    required Exercise exercise,
    Function(Exercise updated)? onExerciseUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExerciseDetailModal(
        exercise: exercise,
        onExerciseUpdated: onExerciseUpdated,
      ),
    );
  }

  @override
  State<ExerciseDetailModal> createState() => _ExerciseDetailModalState();
}

class _ExerciseDetailModalState extends State<ExerciseDetailModal> {
  late Exercise _ex;
  String? _imagePath;
  String? _videoPath;
  Map<String, dynamic>? _catalogInfo;
  int _mediaTab = 0; // 0: Vídeo (se houver), 1: Foto

  @override
  void initState() {
    super.initState();
    _ex = widget.exercise;
    _resolveMedia();
  }

  void _resolveMedia() {
    _imagePath = _ex.imageUrl ??
        ExerciseImageService.getImageForExercise(
          exerciseName: _ex.name,
          primaryMuscleGroup: _ex.primaryMuscleGroup,
          diagramType: _ex.diagramType,
        ) ??
        'source/exercices/images/chest/Bench Press.png';

    _videoPath = _ex.videoUrl ??
        ExerciseImageService.getVideoForExercise(
          exerciseName: _ex.name,
          primaryMuscleGroup: _ex.primaryMuscleGroup,
          diagramType: _ex.diagramType,
        );

    _catalogInfo = ExerciseImageService.getExerciseInfo(_ex.name);
    _mediaTab = (_videoPath != null && _videoPath!.isNotEmpty) ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _videoPath != null && _videoPath!.isNotEmpty;
    final nivel = _catalogInfo?['nivel'] as String? ?? 'Intermediário';

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
          ),
          child: Column(
            children: [
              // Barra de arrasto superior
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Header com Título e Botão Fechar
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  _ex.primaryMuscleGroup.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Text(
                                  nivel.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.accentYellow,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _ex.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Conteúdo rolável com mídia e detalhes
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Seletor de Mídia (Vídeo vs Foto) se vídeo existir
                    if (hasVideo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildMediaTabButton(
                                label: 'Vídeo da Execução',
                                icon: Icons.play_circle_fill_rounded,
                                isSelected: _mediaTab == 0,
                                onTap: () => setState(() => _mediaTab = 0),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMediaTabButton(
                                label: 'Foto Anatômica',
                                icon: Icons.image_rounded,
                                isSelected: _mediaTab == 1,
                                onTap: () => setState(() => _mediaTab = 1),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Exibição da Mídia Principal (Player de Vídeo ou Imagem Ampliada)
                    if (hasVideo && _mediaTab == 0)
                      ExerciseVideoPlayer(
                        videoPath: _videoPath!,
                        thumbnailPath: _imagePath,
                        height: 230,
                        autoPlay: true,
                        looping: true,
                      )
                    else
                      Container(
                        height: 230,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0B0B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder, width: 1.2),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Image.asset(
                                _imagePath!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.fitness_center_rounded, size: 48, color: AppColors.primaryOrange),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_library_outlined, size: 11, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'FOTO OFICIAL',
                                      style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Parâmetros de Prescrição do Exercício
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.fitness_center_rounded,
                            label: 'Carga',
                            value: '${_ex.weightKg.toStringAsFixed(_ex.weightKg % 1 == 0 ? 0 : 1)} kg',
                            accentColor: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.repeat_rounded,
                            label: 'Repetições',
                            value: '${_ex.reps} reps',
                            accentColor: AppColors.accentYellow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.timer_outlined,
                            label: 'Descanso',
                            value: '${_ex.restSeconds}s',
                            accentColor: const Color(0xFF00E676),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Músculos Trabalhados
                    if (_ex.targetMuscles.isNotEmpty) ...[
                      const Text(
                        'MÚSCULOS ALVO',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _ex.targetMuscles.map((muscle) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 13, color: AppColors.primaryOrange),
                                const SizedBox(width: 5),
                                Text(
                                  muscle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Observações do Treinador / Anotações
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _ex.observations.isNotEmpty
                              ? AppColors.primaryOrange.withValues(alpha: 0.5)
                              : AppColors.cardBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primaryOrange),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'OBSERVAÇÕES E NOTAS TÉCNICAS',
                                  style: TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _ex.observations.isNotEmpty
                                ? _ex.observations
                                : 'Sem observações adicionais. Foque na técnica correta e na sobrecarga progressiva com baixas repetições.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Dicas de Execução / Biomecânica
                    if (_ex.executionTips.isNotEmpty) ...[
                      const Text(
                        'PONTOS CHAVE DE EXECUÇÃO',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._ex.executionTips.map(
                        (tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right_rounded, size: 18, color: AppColors.accentYellow),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Botão para Iniciar Cronômetro de Descanso
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          RestTimerSheet.show(
                            context,
                            initialSeconds: _ex.restSeconds,
                            exerciseName: _ex.name,
                          );
                        },
                        icon: const Icon(Icons.timer_outlined, size: 18, color: AppColors.accentYellow),
                        label: Text(
                          'Testar Cronômetro de Descanso (${_ex.restSeconds}s)',
                          style: const TextStyle(color: AppColors.accentYellow, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accentYellow),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
