import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exercise.dart';
import '../services/exercise_image_service.dart';
import '../theme/app_colors.dart';
import 'exercise_detail_screen.dart';

/// Catálogo visual de todos os exercícios da biblioteca.
/// Permite visualizar as imagens de todos os exercícios, buscar por nome,
/// filtrar por grupo muscular e abrir os detalhes e vídeo de execução de qualquer exercício.
class ExerciseCatalogSheet extends StatefulWidget {
  const ExerciseCatalogSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExerciseCatalogSheet(),
    );
  }

  @override
  State<ExerciseCatalogSheet> createState() => _ExerciseCatalogSheetState();
}

class _ExerciseCatalogSheetState extends State<ExerciseCatalogSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  bool _isLoading = true;
  String _selectedMuscle = 'Todos';

  static const List<String> _muscleFilters = [
    'Todos',
    'Peitoral',
    'Costas',
    'Quadríceps',
    'Isquiotibiais',
    'Ombros',
    'Bíceps',
    'Tríceps',
    'Panturrilhas',
    'Cardio',
    'Cintura',
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/exercicios.json');
      final List<dynamic> list = json.decode(jsonString);
      _allExercises = list.cast<Map<String, dynamic>>();
      _filteredExercises = List.from(_allExercises);
    } catch (_) {
      _allExercises = [];
      _filteredExercises = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        final name = (ex['nome'] as String? ?? '').toLowerCase();
        final muscle = (ex['grupo_muscular'] as String? ?? '').toLowerCase();

        final matchesQuery = query.isEmpty || name.contains(query) || muscle.contains(query);
        final matchesMuscle = _selectedMuscle == 'Todos' ||
            muscle.contains(_selectedMuscle.toLowerCase()) ||
            _selectedMuscle.toLowerCase().contains(muscle);

        return matchesQuery && matchesMuscle;
      }).toList();
    });
  }

  void _openExerciseDetail(Map<String, dynamic> raw) {
    final name = raw['nome'] as String? ?? 'Exercício';
    final imagePath = raw['caminho_imagem'] as String? ??
        ExerciseImageService.getImageForExercise(exerciseName: name);
    final videoPath = raw['caminho_video'] as String? ??
        ExerciseImageService.getVideoForExercise(exerciseName: name);
    final muscle = raw['grupo_muscular'] as String? ?? 'Geral';

    final exercise = Exercise(
      id: 'cat_${name.hashCode}',
      name: name,
      targetMuscles: [muscle],
      primaryMuscleGroup: muscle.toLowerCase(),
      weightKg: 30.0,
      reps: 3,
      sets: 3,
      restSeconds: 90,
      diagramType: 'bench_press',
      imageUrl: imagePath,
      videoUrl: videoPath,
    );

    ExerciseDetailModal.show(context, exercise: exercise);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
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
                padding: const EdgeInsets.only(top: 10, bottom: 4),
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

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center_rounded, color: AppColors.primaryOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Biblioteca de Exercícios',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_filteredExercises.length} de ${_allExercises.length} exercícios com fotos e vídeos',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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

              // Barra de busca por nome
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar exercício (ex: supino, agachamento, remada...)',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primaryOrange),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textSecondary),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),

              // Chips de Grupos Musculares
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _muscleFilters.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (context, idx) {
                    final muscle = _muscleFilters[idx];
                    final isSelected = _selectedMuscle == muscle;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMuscle = muscle;
                          _applyFilters();
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryOrange : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryOrange : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          muscle,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // Grid de Exercícios com Imagem e Badge de Vídeo
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryOrange),
                      )
                    : _filteredExercises.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum exercício encontrado para essa busca.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          )
                        : GridView.builder(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.82,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _filteredExercises.length,
                            itemBuilder: (context, index) {
                              final raw = _filteredExercises[index];
                              final name = raw['nome'] as String? ?? '';
                              final imagePath = raw['caminho_imagem'] as String? ?? '';
                              final hasVideo = raw['caminho_video'] != null;
                              final muscle = raw['grupo_muscular'] as String? ?? '';

                              return InkWell(
                                onTap: () => _openExerciseDetail(raw),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Imagem com Badge de Vídeo
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          color: const Color(0xFF0D0B0B),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(6.0),
                                                child: Image.asset(
                                                  imagePath,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) => const Center(
                                                    child: Icon(Icons.fitness_center_rounded,
                                                        color: AppColors.primaryOrange, size: 28),
                                                  ),
                                                ),
                                              ),
                                              if (hasVideo)
                                                Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primaryOrange,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.play_arrow_rounded, size: 10, color: Colors.white),
                                                        Text(
                                                          'VÍDEO',
                                                          style: TextStyle(
                                                            fontSize: 7.5,
                                                            fontWeight: FontWeight.w900,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Nome e Grupo Muscular
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              muscle.toUpperCase(),
                                              style: const TextStyle(
                                                color: AppColors.primaryOrange,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
            ],
          ),
        );
      },
    );
  }
}
