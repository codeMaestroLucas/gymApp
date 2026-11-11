import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../services/ai_workout_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class CreateWorkoutModal extends StatefulWidget {
  final UserProfile userProfile;
  final Function(List<Workout> newWorkouts) onWorkoutsCreated;

  const CreateWorkoutModal({
    super.key,
    required this.userProfile,
    required this.onWorkoutsCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required UserProfile userProfile,
    required Function(List<Workout>) onWorkoutsCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateWorkoutModal(
        userProfile: userProfile,
        onWorkoutsCreated: onWorkoutsCreated,
      ),
    );
  }

  @override
  State<CreateWorkoutModal> createState() => _CreateWorkoutModalState();
}

class _CreateWorkoutModalState extends State<CreateWorkoutModal> {
  final TextEditingController _promptController = TextEditingController();
  late int _selectedDays;
  late int _selectedDuration;
  int _selectedMaxReps = 3; // Padrão solicitado: no máximo 3 repetições
  int _selectedVariety = 7; // Padrão solicitado: ampla variedade (6 a 8 exercícios)
  bool _isLoading = false;
  String _loadingStep = '';

  final List<String> _promptSuggestions = [
    'Força máxima com alta variedade de exercícios (máx 3 reps)',
    'Treino pesado com barra e halteres (1 a 3 reps)',
    'Foco em cargas pesadas e exercícios compostos múltiplos',
    'Potência e densidade com variedade de ângulos',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.userProfile.defaultDaysPerWeek;
    _selectedDuration = widget.userProfile.defaultDurationMinutes;
    _promptController.text =
        'Quero focar em cargas pesadas e alta variedade de exercícios com no máximo 3 repetições.';
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateWorkouts() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe seu objetivo no prompt.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingStep = 'Analisando perfil (${widget.userProfile.weightKg}kg, ${widget.userProfile.objective})...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _loadingStep = 'Configurando variedade alta ($_selectedVariety exercícios por sessão)...';
        });
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _loadingStep = 'Calculando cargas pesadas e limitando a no máximo $_selectedMaxReps reps...';
        });
      }

      final apiKey = StorageService().getGeminiApiKey();
      final newWorkouts = await AiWorkoutService.generateWorkouts(
        prompt: prompt,
        daysAvailable: _selectedDays,
        durationMinutes: _selectedDuration,
        profile: widget.userProfile,
        maxReps: _selectedMaxReps,
        exerciseVariety: _selectedVariety,
        geminiApiKey: apiKey,
      );

      if (mounted) {
        widget.onWorkoutsCreated(newWorkouts);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.cardBackground,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primaryOrange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${newWorkouts.length} treinos gerados com $_selectedVariety exercícios e máx $_selectedMaxReps reps!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar treinos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de arraste
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Cabeçalho com ícone de IA
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criar Treino com IA',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Alta variedade de exercícios e cargas elevadas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Destaque de Regra Ativa: Ampla Variedade + Máximo 3 Reps
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.primaryOrange, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Diretriz Ativa: Variedade estendida (6 a 8 exercícios por sessão) com no máximo 3 repetições pesadas por exercício.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campo de prompt descritivo
            const Text(
              'O que você deseja focar neste treino?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                hintText:
                    'Ex: Quero alta variedade de exercícios compostos com no máximo 3 repetições...',
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Chips com sugestões de prompt
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _promptSuggestions.map((sug) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(sug, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.backgroundDark,
                      side: const BorderSide(color: AppColors.cardBorder),
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          _promptController.text = sug;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Seletor de Limite de Repetições (Máximo 3 reps)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Limite Máximo de Repetições:',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_selectedMaxReps reps máx',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildOptionChip(
                  label: '1 Rep (Single / PR)',
                  isSelected: _selectedMaxReps == 1,
                  onTap: () => setState(() => _selectedMaxReps = 1),
                ),
                const SizedBox(width: 8),
                _buildOptionChip(
                  label: '2 Reps (Doubles)',
                  isSelected: _selectedMaxReps == 2,
                  onTap: () => setState(() => _selectedMaxReps = 2),
                ),
                const SizedBox(width: 8),
                _buildOptionChip(
                  label: '3 Reps (Triples - Ideal)',
                  isSelected: _selectedMaxReps == 3,
                  onTap: () => setState(() => _selectedMaxReps = 3),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Seletor de Variedade de Exercícios por Sessão
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Variedade por Treino:',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_selectedVariety exercícios',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [6, 7, 8].map((count) {
                final isSelected = _selectedVariety == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text('$count Exercícios'),
                      selected: isSelected,
                      selectedColor: AppColors.primaryOrange,
                      backgroundColor: AppColors.backgroundDark,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedVariety = count);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Seletor de Dias disponíveis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dias disponíveis na semana:',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_selectedDays dias/semana',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [2, 3, 4, 5, 6].map((day) {
                final isSelected = _selectedDays == day;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text('$day d'),
                      selected: isSelected,
                      selectedColor: AppColors.primaryOrange,
                      backgroundColor: AppColors.backgroundDark,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedDays = day);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Seletor de Tempo por treino
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tempo disponível por sessão:',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$_selectedDuration min',
                  style: const TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [45, 60, 75, 90].map((dur) {
                final isSelected = _selectedDuration == dur;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: ChoiceChip(
                      label: Text('$dur m'),
                      selected: isSelected,
                      selectedColor: AppColors.primaryOrange,
                      backgroundColor: AppColors.backgroundDark,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11.5,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedDuration = dur);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Estado de Loading ou Botão de Ação
            if (_isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loadingStep,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _generateWorkouts,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    'Gerar com $_selectedVariety Exercícios (Máx $_selectedMaxReps Reps)',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryOrange : AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryOrange : AppColors.cardBorder,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
