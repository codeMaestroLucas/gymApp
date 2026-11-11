import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../widgets/anatomical_diagram.dart';
import '../widgets/rest_timer_sheet.dart';
import '../theme/app_colors.dart';
import 'active_workout_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  final Function(Workout updatedWorkout) onWorkoutUpdated;

  const WorkoutDetailScreen({
    super.key,
    required this.workout,
    required this.onWorkoutUpdated,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Workout _currentWorkout;

  @override
  void initState() {
    super.initState();
    _currentWorkout = widget.workout;
  }

  void _updateExercise(int index, Exercise updated) {
    setState(() {
      _currentWorkout.exercises[index] = updated;
    });
    widget.onWorkoutUpdated(_currentWorkout);
  }

  void _editExerciseDetails(BuildContext context, int index) {
    final ex = _currentWorkout.exercises[index];
    final weightCtrl = TextEditingController(text: ex.weightKg.toString());
    final setsCtrl = TextEditingController(text: ex.sets.toString());
    final restCtrl = TextEditingController(text: ex.restSeconds.toString());
    final obsCtrl = TextEditingController(text: ex.observations);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Editar ${ex.name}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                        prefixIcon: Icon(Icons.fitness_center_rounded, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: setsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Repetições (máx 3)',
                        prefixIcon: Icon(Icons.repeat_rounded, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: restCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Descanso (s)',
                        prefixIcon: Icon(Icons.timer_outlined, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Observações / Instruções pessoais',
                  hintText: 'Ex: Focar na descida de 3s, pegada fechada...',
                  prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final parsedSets = (int.tryParse(setsCtrl.text) ?? ex.sets).clamp(1, 3);
                    final updated = ex.copyWith(
                      weightKg: double.tryParse(weightCtrl.text) ?? ex.weightKg,
                      sets: parsedSets,
                      reps: parsedSets, // Sincroniza repetições com séries (máx 3)
                      restSeconds: int.tryParse(restCtrl.text) ?? ex.restSeconds,
                      observations: obsCtrl.text.trim(),
                    );
                    _updateExercise(index, updated);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Salvar Alterações'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(_currentWorkout.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: 'Gerado com IA',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.cardBackground,
                  content: Text(
                    'Prompt gerador: "${_currentWorkout.aiPrompt}"',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner Resumo do Treino
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.darkCardGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryOrange),
                          ),
                          child: Text(
                            'DIVISÃO ${_currentWorkout.splitTag.toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.timer_outlined,
                            size: 16, color: AppColors.accentYellow),
                        const SizedBox(width: 5),
                        Text(
                          '${_currentWorkout.durationMinutes} min estimados',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentWorkout.description.isNotEmpty
                          ? _currentWorkout.description
                          : _currentWorkout.targetMusclesSummary,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          label: 'Exercícios',
                          value: '${_currentWorkout.exercises.length}',
                        ),
                        _buildSummaryItem(
                          label: 'Repetições Totais',
                          value: '${_currentWorkout.totalSets}',
                        ),
                        _buildSummaryItem(
                          label: 'Volume Estimado',
                          value: '${(_currentWorkout.estimatedTotalVolumeKg / 1000).toStringAsFixed(1)}t',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Título da lista de exercícios
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exercícios e Anatomia',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentWorkout.exercises.length} itens',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de cards com diagrama anatômico e especificações
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ex = _currentWorkout.exercises[index];
                  return _buildExerciseCard(ex, index);
                },
                childCount: _currentWorkout.exercises.length,
              ),
            ),
          ),

          // Espaço para o botão fixo inferior
          const SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.backgroundDark,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveWorkoutScreen(
                    workout: _currentWorkout,
                    onWorkoutCompleted: (updated) {
                      setState(() => _currentWorkout = updated);
                      widget.onWorkoutUpdated(updated);
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
            label: const Text(
              'Iniciar Treino Agora',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryOrange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Exercise ex, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Nome e Botão de Editar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.backgroundDark,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 19, color: AppColors.textSecondary),
                  tooltip: 'Ajustar carga e reps',
                  onPressed: () => _editExerciseDetails(context, index),
                ),
              ],
            ),
          ),

          // Diagrama Anatômico e de Execução Vinculado ao Exercício
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AnatomicalDiagram(
              diagramType: ex.diagramType,
              exerciseName: ex.name,
              primaryMuscleGroup: ex.primaryMuscleGroup,
              targetMuscles: ex.targetMuscles,
              imageUrl: ex.imageUrl,
              height: 195,
            ),
          ),
          const SizedBox(height: 14),

          // Métricas: Carga, Reps, Descanso (com timer interativo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.fitness_center_rounded,
                    label: 'Carga',
                    value: '${ex.weightKg.toStringAsFixed(1)} kg',
                    subtext: 'Intensidade',
                    onTap: () => _editExerciseDetails(context, index),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.repeat_rounded,
                    label: 'Repetições',
                    value: '${ex.reps} reps',
                    subtext: 'Máx 3 reps',
                    onTap: () => _editExerciseDetails(context, index),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.timer_outlined,
                    label: 'Descanso',
                    value: '${ex.restSeconds}s',
                    subtext: 'Toque p/ cronômetro',
                    highlightColor: AppColors.accentYellow,
                    onTap: () {
                      RestTimerSheet.show(
                        context,
                        initialSeconds: ex.restSeconds,
                        exerciseName: ex.name,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Campo de Observações (Editável pelo Usuário)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded,
                          size: 16, color: AppColors.primaryOrange),
                      const SizedBox(width: 6),
                      const Text(
                        'Observações pessoais:',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _editExerciseDetails(context, index),
                        child: const Text(
                          'Editar',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ex.observations.isNotEmpty
                        ? ex.observations
                        : 'Nenhuma observação. Toque em "Editar" para adicionar notas sobre execução, pegada ou desconfortos.',
                    style: TextStyle(
                      color: ex.observations.isNotEmpty
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      fontStyle: ex.observations.isNotEmpty
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    Color? highlightColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlightColor?.withValues(alpha: 0.3) ?? AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: highlightColor ?? AppColors.primaryOrange),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: highlightColor ?? AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
