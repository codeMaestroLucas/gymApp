import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../models/workout_history.dart';
import '../../theme/app_colors.dart';
import '../../services/exercise_image_service.dart';
import '../../services/watch_sync_service.dart';
import '../widgets/watch_screen_container.dart';
import 'watch_exercise_detail_screen.dart';

/// Tela de Execução Ativa do Treino no Smartwatch
/// Permite ao atleta:
/// - Visualizar cada exercício com sua imagem oficial anatômica
/// - Modificar peso (carga em kg) durante o treino com botões rápidos +/-
/// - Modificar repetições (1 a 3 reps) durante o treino
/// - Adicionar e editar observações do exercício com tags rápidas no relógio
/// - Controlar cronômetro de descanso circular
/// - Ao final, salvar o treino atualizado com as novas cargas e observações,
///   sincronizando tudo imediatamente com o aplicativo móvel.
class WatchActiveWorkoutScreen extends StatefulWidget {
  final Workout workout;
  final bool isCircular;

  const WatchActiveWorkoutScreen({
    super.key,
    required this.workout,
    this.isCircular = true,
  });

  @override
  State<WatchActiveWorkoutScreen> createState() => _WatchActiveWorkoutScreenState();
}

class _WatchActiveWorkoutScreenState extends State<WatchActiveWorkoutScreen> {
  late Workout _activeWorkout;
  int _currentExerciseIndex = 0;
  int _totalExercisesCompleted = 0;
  double _totalVolumeAccumulatedKg = 0;
  final DateTime _startedAt = DateTime.now();

  // Estado do descanso
  bool _isResting = false;
  int _restSecondsRemaining = 0;
  int _restInitialSeconds = 60;
  Timer? _restTimer;

  // Treino finalizado (aguardando confirmação de "Salvar treino")
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // Clona o treino para permitir edições em tempo de execução sem afetar
    // o estado global até que o atleta clique em "Salvar Treino"
    _activeWorkout = widget.workout.clone();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  Exercise get _currentExercise => _activeWorkout.exercises[_currentExerciseIndex];

  void _onCompleteExercise() {
    HapticFeedback.heavyImpact();

    setState(() {
      _totalExercisesCompleted++;
      _totalVolumeAccumulatedKg += (_currentExercise.weightKg * _currentExercise.reps);

      if (_currentExerciseIndex < _activeWorkout.exercises.length - 1) {
        _currentExerciseIndex++;
        _startRest(_currentExercise.restSeconds);
      } else {
        // Treino completo!
        _finishWorkout();
      }
    });
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    _restInitialSeconds = seconds > 0 ? seconds : 60;
    _restSecondsRemaining = _restInitialSeconds;
    _isResting = true;

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restSecondsRemaining > 1) {
        setState(() {
          _restSecondsRemaining--;
        });
      } else {
        timer.cancel();
        // Vibração 2x bem fraquinha conforme solicitado pelo usuário
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 180), () {
          HapticFeedback.lightImpact();
        });
        setState(() {
          _isResting = false;
        });
      }
    });
  }

  void _adjustRestTime(int deltaSeconds) {
    setState(() {
      _restSecondsRemaining = (_restSecondsRemaining + deltaSeconds).clamp(5, 300);
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      _isResting = false;
    });
  }

  /// Permite modificar a carga (peso em kg) do exercício atual durante o treino
  void _adjustWeight(double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      final newWeight = (_currentExercise.weightKg + delta).clamp(1.0, 500.0);
      _currentExercise.weightKg = (newWeight * 2).round() / 2; // Arredonda para 0.5 kg
    });
  }

  /// Permite modificar o número de repetições (1 a 3 reps - apenas repetições conforme solicitado)
  void _adjustReps(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      final newReps = (_currentExercise.reps + delta).clamp(1, 3);
      _currentExercise.reps = newReps;
      _currentExercise.sets = newReps;
    });
  }

  /// Diálogo limpo e compacto de observação (sugestões removidas para economizar espaço na tela do relógio)
  void _openObservationModal() {
    final noteCtrl = TextEditingController(text: _currentExercise.observations);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.primaryOrange, width: 1.2),
          ),
          titlePadding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note_rounded, size: 14, color: AppColors.primaryOrange),
              SizedBox(width: 4),
              Text(
                'OBSERVAÇÃO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 11, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ex: postura, cadência...',
                  hintStyle: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _currentExercise.observations = '';
                          });
                          Navigator.of(ctx).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xFF2C2424),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Limpar',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _currentExercise.observations = noteCtrl.text.trim();
                          });
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Salvar',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _finishWorkout() {
    _restTimer?.cancel();
    setState(() {
      _isFinished = true;
    });
  }

  /// Ação principal de "Salvar Treino":
  /// Registra no histórico geral (volume, duração, etc) e atualiza o treino no celular
  /// com todas as alterações de pesos, repetições e observações feitas no relógio!
  Future<void> _saveWorkoutAndSync() async {
    final durationSeconds = DateTime.now().difference(_startedAt).inSeconds;
    final durationMin = (durationSeconds / 60).clamp(1, 240).round();

    final historyEntry = WorkoutHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutTitle: _activeWorkout.title,
      splitTag: _activeWorkout.splitTag,
      completedAt: DateTime.now(),
      durationMinutes: durationMin,
      totalVolumeKg: _totalVolumeAccumulatedKg,
      totalSets: _totalExercisesCompleted,
      exercisesCount: _activeWorkout.exercises.length,
      caloriesEstimated: (durationMin * 8.0).round(),
    );

    // Salva o treino com os pesos/obs modificados e adiciona ao histórico geral
    await WatchSyncService.instance.saveFinishedWorkoutFromWatch(
      updatedWorkout: _activeWorkout,
      historyEntry: historyEntry,
    );

    HapticFeedback.heavyImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1A1A),
          content: Text(
            '✓ Treino salvo e sincronizado com o celular!',
            style: TextStyle(color: Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _buildFinishedView();
    }

    if (_isResting) {
      return _buildRestingView();
    }

    return _buildActiveExerciseView();
  }

  // --- TELA DO EXERCÍCIO ATIVO ---
  Widget _buildActiveExerciseView() {
    final ex = _currentExercise;
    final imagePath = ex.imageUrl ??
        ExerciseImageService.getImageForExercise(
          exerciseName: ex.name,
          primaryMuscleGroup: ex.primaryMuscleGroup,
          diagramType: ex.diagramType,
        ) ??
        'source/imgs/exercicies/peito/0.png';

    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchScreenContainer(
        isCircular: widget.isCircular,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Top Bar: Indicador de Exercício, Concluir Treino antecipado, e Detalhes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _confirmExitWorkout(),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                  ),
                  Text(
                    'EX ${ _currentExerciseIndex + 1 }/${_activeWorkout.exercises.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  // Botão para finalizar treino a qualquer momento e ir para tela de Salvar
                  InkWell(
                    onTap: () => _finishWorkout(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flag_rounded, size: 11, color: AppColors.primaryOrange),
                          SizedBox(width: 2),
                          Text(
                            'Fim',
                            style: TextStyle(fontSize: 8.5, color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              // Imagem Oficial do Exercício Ampliada (source/imgs/exercicies)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WatchExerciseDetailScreen(
                        exercise: ex,
                        isCircular: widget.isCircular,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 70,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.5), width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.primaryOrange,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 3),

              // Nome do Exercício
              Text(
                ex.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              // Ajuste Interativo de Peso (Carga) e Repetições (1 a 3 reps - apenas repetições)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modificador de Carga (kg)
                  _buildInteractiveMetric(
                    label: 'CARGA',
                    value: ex.weightKg.toStringAsFixed(ex.weightKg % 1 == 0 ? 0 : 1),
                    unit: 'kg',
                    color: AppColors.primaryOrange,
                    onDecrement: () => _adjustWeight(-2.5),
                    onIncrement: () => _adjustWeight(2.5),
                  ),
                  const SizedBox(width: 8),
                  // Modificador de Repetições (1 a 3 reps)
                  _buildInteractiveMetric(
                    label: 'REPETIÇÕES',
                    value: '${ex.reps}',
                    unit: 'reps',
                    color: AppColors.accentYellow,
                    onDecrement: () => _adjustReps(-1),
                    onIncrement: () => _adjustReps(1),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Botão de Observações do Exercício (Permite alterar observações na hora)
              InkWell(
                onTap: _openObservationModal,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ex.observations.isNotEmpty
                          ? AppColors.primaryOrange.withValues(alpha: 0.7)
                          : AppColors.cardBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 13,
                        color: ex.observations.isNotEmpty ? AppColors.primaryOrange : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ex.observations.isEmpty ? 'Obs: + nota' : 'Obs: ${ex.observations}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: ex.observations.isNotEmpty ? Colors.white : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Botão de Concluir Exercício
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: _onCompleteExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'CONCLUIR EXERCÍCIO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveMetric({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão diminuir
              InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.remove_rounded, size: 14, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 2),
              // Valor
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              // Botão aumentar
              InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  child: const Icon(Icons.add_rounded, size: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TELA DE DESCANSO CIRCULAR HÁPTICO ---
  Widget _buildRestingView() {
    final progress = _restInitialSeconds > 0
        ? (_restSecondsRemaining / _restInitialSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchScreenContainer(
        isCircular: widget.isCircular,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'DESCANSO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentYellow,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 6),

              // Anel de Progresso Circular de Descanso
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5.5,
                      backgroundColor: AppColors.cardBackground,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentYellow),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_restSecondsRemaining',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'seg',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Controles de ajuste de tempo (+15s / -15s)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRestAdjustButton('-15s', () => _adjustRestTime(-15)),
                  const SizedBox(width: 8),
                  _buildRestAdjustButton('+15s', () => _adjustRestTime(15)),
                ],
              ),

              const SizedBox(height: 6),

              // Botão Pular Descanso
              SizedBox(
                height: 28,
                child: TextButton(
                  onPressed: _skipRest,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                  child: const Text(
                    'PULAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestAdjustButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // --- TELA DE CONCLUSÃO COM BOTÃO "SALVAR TREINO" ---
  Widget _buildFinishedView() {
    final durationSeconds = DateTime.now().difference(_startedAt).inSeconds;
    final durationMin = (durationSeconds / 60).clamp(1, 240).round();

    return Scaffold(
      backgroundColor: Colors.black,
      body: WatchScreenContainer(
        isCircular: widget.isCircular,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.accentYellow, size: 28),
              const SizedBox(height: 2),
              const Text(
                'TREINO FINALIZADO!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              // Resumo das estatísticas da sessão
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem('TEMPO', '$durationMin min', AppColors.accentYellow),
                        _buildSummaryItem('VOLUME', '${_totalVolumeAccumulatedKg.toInt()} kg', AppColors.primaryOrange),
                        _buildSummaryItem('EXERCÍCIOS', '$_totalExercisesCompleted', Colors.white),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Resumo das alterações de exercícios
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exercícios & Pesos Registrados:',
                      style: TextStyle(fontSize: 8.5, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    ...(_activeWorkout.exercises.take(3).map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 1.5),
                        child: Text(
                          '• ${e.name}: ${e.weightKg.toStringAsFixed(e.weightKg % 1 == 0 ? 0 : 1)} kg (${e.reps} reps)${e.observations.isNotEmpty ? ' [Obs]' : ''}',
                          style: const TextStyle(fontSize: 8, color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    })),
                    if (_activeWorkout.exercises.length > 3)
                      Text(
                        '+ ${_activeWorkout.exercises.length - 3} outros exercícios...',
                        style: const TextStyle(fontSize: 7.5, color: AppColors.primaryOrange),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // BOTÃO SALVAR TREINO (Ação solicitada pelo usuário)
              SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: _saveWorkoutAndSync,
                  icon: const Icon(Icons.save_rounded, size: 15),
                  label: const Text(
                    'SALVAR TREINO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Botão secundário de descarte se o atleta não quiser salvar
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text(
                    'Sair sem salvar',
                    style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 7.5, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 1),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  void _confirmExitWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Sair do Treino?', style: TextStyle(color: Colors.white, fontSize: 13)),
        content: const Text(
          'Deseja salvar o progresso atual antes de sair?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _finishWorkout();
            },
            child: const Text('Finalizar e Salvar', style: TextStyle(color: AppColors.primaryOrange, fontSize: 11)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Descartar', style: TextStyle(color: AppColors.accentRed, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class MaterialUrlPageRoute<T> extends MaterialPageRoute<T> {
  MaterialUrlPageRoute({required super.builder});
}
