import 'package:flutter/material.dart';
import '../models/workout_history.dart';
import '../models/user_profile.dart';
import '../widgets/evolution_charts.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class EvolutionScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile updatedProfile) onProfileUpdated;

  const EvolutionScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  late List<WorkoutHistoryEntry> _history;
  late List<PersonalRecord> _prs;

  // Pontos de histórico de peso corporal
  late List<double> _weightHistory;
  late List<String> _weightDates;

  @override
  void initState() {
    super.initState();
    _history = StorageService().loadHistory();
    _prs = StorageService().loadPRs();

    // Histórico de pesagens baseado no perfil atual
    final currentW = widget.userProfile.weightKg;
    _weightHistory = [
      (currentW - 2.4),
      (currentW - 1.8),
      (currentW - 1.1),
      (currentW - 0.4),
      currentW,
    ];
    _weightDates = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Hoje'];
  }

  void _addNewWeightMeasurement() {
    final weightCtrl =
        TextEditingController(text: widget.userProfile.weightKg.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Registrar Nova Pesagem',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          content: TextField(
            controller: weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso atual (kg)',
              suffixText: 'kg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final newW = double.tryParse(weightCtrl.text);
                if (newW != null && newW > 0) {
                  setState(() {
                    _weightHistory.add(newW);
                    if (_weightHistory.length > 6) {
                      _weightHistory.removeAt(0);
                    }
                    _weightDates.add('Hoje');
                    if (_weightDates.length > 6) {
                      _weightDates.removeAt(0);
                    }
                  });
                  final updatedProf = widget.userProfile.copyWith(weightKg: newW);
                  widget.onProfileUpdated(updatedProf);
                  StorageService().saveProfile(updatedProf);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }

  void _addNewPR() {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final repsCtrl = TextEditingController(text: '1');
    final groupCtrl = TextEditingController(text: 'Peitoral');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Novo Recorde Pessoal (PR)',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Exercício',
                    hintText: 'Ex: Supino Inclinado, Terra...',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Carga máxima (kg)',
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: repsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Repetições válidas',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final w = double.tryParse(weightCtrl.text);
                final r = int.tryParse(repsCtrl.text) ?? 1;
                if (nameCtrl.text.isNotEmpty && w != null && w > 0) {
                  final newPr = PersonalRecord(
                    exerciseName: nameCtrl.text.trim(),
                    weightKg: w,
                    reps: r,
                    achievedAt: DateTime.now(),
                    muscleGroup: groupCtrl.text.trim(),
                  );
                  setState(() {
                    _prs.insert(0, newPr);
                  });
                  StorageService().savePRs(_prs);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Salvar PR'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo das estatísticas da semana
    final totalWorkouts = _history.length;
    final totalVolKg = _history.fold(0.0, (sum, h) => sum + h.totalVolumeKg);
    final totalMinutes = _history.fold(0, (sum, h) => sum + h.durationMinutes);
    final totalCalories = _history.fold(0, (sum, h) => sum + h.caloriesEstimated);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evolução & Performance',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Acompanhamento detalhado de carga, frequência e físico',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cartões de Estatísticas Semanais
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Treinos',
                        value: '$totalWorkouts feitos',
                        subtext: 'Meta: 4/sem',
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.fitness_center_rounded,
                        label: 'Volume Total',
                        value: '${(totalVolKg / 1000).toStringAsFixed(1)} t',
                        subtext: '+8% vs semana ant.',
                        color: AppColors.accentYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.timer_outlined,
                        label: 'Tempo Ativo',
                        value: '${totalMinutes ~/ 60}h ${totalMinutes % 60}m',
                        subtext: 'Alta densidade',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatTile(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Gasto Calórico',
                        value: '$totalCalories kcal',
                        subtext: 'Metabolismo basal+',
                        color: AppColors.accentRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Card de Insights da IA
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: AppColors.accentYellow, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Insights do Treinador IA',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInsightItem(
                        icon: Icons.trending_up_rounded,
                        color: AppColors.primaryOrange,
                        text:
                            'Progressão constante: Seu volume em Peitoral e Pernas subiu 6.2% nas últimas semanas, mantendo a cadência recomendada.',
                      ),
                      const SizedBox(height: 10),
                      _buildInsightItem(
                        icon: Icons.health_and_safety_rounded,
                        color: AppColors.accentYellow,
                        text:
                            'Recuperação: Levando em conta sua rotina ativa, recomendamos manter o descanso de 90s nos exercícios compostos pesados.',
                      ),
                      const SizedBox(height: 10),
                      _buildInsightItem(
                        icon: Icons.speed_rounded,
                        color: AppColors.accentRed,
                        text:
                            'Atenção às articulações: Excelente controle no Supino sem sobrecarga no ombro esquerdo citado no seu perfil.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Gráfico 1: Volume Semanal de Carga
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Volume Semanal (Toneladas)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Esta semana',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      WeeklyVolumeChart(
                        weeklyVolumes: [7.4, 8.9, 11.4, 0.0, 7.2, 8.7, 0.0],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Gráfico 2: Evolução Corporal (Peso kg)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Evolução do Peso Corporal',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Atual: ${widget.userProfile.weightKg.toStringAsFixed(1)} kg (${widget.userProfile.bmiClassification})',
                                  style: const TextStyle(
                                    color: AppColors.primaryOrange,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                color: AppColors.primaryOrange),
                            onPressed: _addNewWeightMeasurement,
                            tooltip: 'Registrar pesagem',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      BodyWeightCurveChart(
                        weightPoints: _weightHistory,
                        dateLabels: _weightDates,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Recordes Pessoais (PRs)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recordes Pessoais (PRs)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addNewPR,
                      icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryOrange),
                      label: const Text('Novo PR',
                          style: TextStyle(color: AppColors.primaryOrange, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pr = _prs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.emoji_events_rounded,
                                color: AppColors.primaryOrange, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pr.exerciseName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${pr.reps} reps • ${pr.muscleGroup}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${pr.weightKg.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _prs.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Histórico Recente de Treinos
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Histórico Recente',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final h = _history[index];
                    final dateStr =
                        '${h.completedAt.day.toString().padLeft(2, '0')}/${h.completedAt.month.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  h.workoutTitle,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${h.durationMinutes} min • ${(h.totalVolumeKg / 1000).toStringAsFixed(1)}t volume',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.accentGreen, size: 20),
                        ],
                      ),
                    );
                  },
                  childCount: _history.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
