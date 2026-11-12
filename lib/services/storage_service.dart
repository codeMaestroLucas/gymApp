import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/workout_history.dart';
import 'exercise_image_service.dart';
import 'watch_sync_service.dart';

class StorageService {
  static const String _keyProfile = 'user_profile';
  static const String _keyWorkouts = 'workouts_list_v2';
  static const String _keyHistory = 'workout_history';
  static const String _keyPRs = 'personal_records';
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyPendingWatchFinishes = 'pending_watch_finishes_queue';

  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await ExerciseImageService.init();
    _initialized = true;
  }

  // --- Profile ---
  UserProfile loadProfile() {
    final str = _prefs.getString(_keyProfile);
    if (str != null && str.isNotEmpty) {
      try {
        return UserProfile.fromJson(str);
      } catch (_) {}
    }
    return UserProfile.defaultProfile();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_keyProfile, profile.toJson());
  }

  // --- Gemini API Key ---
  String? getGeminiApiKey() {
    return _prefs.getString(_keyGeminiApiKey);
  }

  Future<void> setGeminiApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _prefs.remove(_keyGeminiApiKey);
    } else {
      await _prefs.setString(_keyGeminiApiKey, key.trim());
    }
  }

  // --- Workouts ---
  List<Workout> loadWorkouts() {
    final str = _prefs.getString(_keyWorkouts);
    if (str != null && str.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(str);
        final loaded = list.map((e) => Workout.fromMap(e as Map<String, dynamic>)).toList();
        // Garante sincronização entre reps e sets e vínculo prioritário
        // de imagens e vídeos da pasta source/exercices
        bool changed = false;
        for (final w in loaded) {
          for (final ex in w.exercises) {
            // Mantém reps e sets sempre em sincronia
            if (ex.sets != ex.reps) {
              ex.sets = ex.reps;
              changed = true;
            }
            if (ex.imageUrl == null ||
                ex.imageUrl!.isEmpty ||
                ex.imageUrl!.contains('source/imgs/exercicies')) {
              ex.imageUrl = ExerciseImageService.getImageForExercise(
                exerciseName: ex.name,
                explicitImageUrl: ex.imageUrl,
                primaryMuscleGroup: ex.primaryMuscleGroup,
                diagramType: ex.diagramType,
              );
              changed = true;
            }
            if (ex.videoUrl == null || ex.videoUrl!.isEmpty) {
              ex.videoUrl = ExerciseImageService.getVideoForExercise(
                exerciseName: ex.name,
                primaryMuscleGroup: ex.primaryMuscleGroup,
                diagramType: ex.diagramType,
              );
              if (ex.videoUrl != null) changed = true;
            }
          }
        }
        if (changed) {
          saveWorkouts(loaded);
        }
        return loaded;
      } catch (_) {}
    }
    final defaults = _getDefaultWorkouts();
    for (final w in defaults) {
      for (final ex in w.exercises) {
        ex.imageUrl = ExerciseImageService.getImageForExercise(
          exerciseName: ex.name,
          primaryMuscleGroup: ex.primaryMuscleGroup,
          diagramType: ex.diagramType,
        );
        ex.videoUrl = ExerciseImageService.getVideoForExercise(
          exerciseName: ex.name,
          primaryMuscleGroup: ex.primaryMuscleGroup,
          diagramType: ex.diagramType,
        );
      }
    }
    saveWorkouts(defaults);
    return defaults;
  }

  Future<void> saveWorkouts(List<Workout> workouts) async {
    final jsonList = workouts.map((w) => w.toMap()).toList();
    await _prefs.setString(_keyWorkouts, json.encode(jsonList));
    // Sincroniza em tempo real com o smartwatch
    await WatchSyncService.instance.syncWorkouts(workouts);
  }

  /// Salva treinos apenas localmente no cache sem disparar loop reverso de sincronização
  Future<void> saveWorkoutsLocally(List<Workout> workouts) async {
    final jsonList = workouts.map((w) => w.toMap()).toList();
    await _prefs.setString(_keyWorkouts, json.encode(jsonList));
  }

  Future<void> updateWorkout(Workout updated) async {
    final list = loadWorkouts();
    final index = list.indexWhere((w) => w.id == updated.id);
    if (index != -1) {
      list[index] = updated;
    } else {
      list.add(updated);
    }
    await saveWorkouts(list);
  }

  Future<void> addHistoryEntry(WorkoutHistoryEntry entry) async {
    final current = loadHistory();
    current.insert(0, entry);
    await saveHistory(current);
  }

  // --- Fila de Sincronização Offline do Smartwatch ---
  List<Map<String, dynamic>> loadPendingWatchFinishes() {
    final str = _prefs.getString(_keyPendingWatchFinishes);
    if (str != null && str.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(str);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> addPendingWatchFinish(Map<String, dynamic> payload) async {
    final list = loadPendingWatchFinishes();
    list.add(payload);
    await _prefs.setString(_keyPendingWatchFinishes, json.encode(list));
  }

  Future<void> clearPendingWatchFinishes() async {
    await _prefs.remove(_keyPendingWatchFinishes);
  }

  Future<List<Workout>> resetWorkoutsToDefault() async {
    final defaults = _getDefaultWorkouts();
    for (final w in defaults) {
      for (final ex in w.exercises) {
        ex.imageUrl = ExerciseImageService.getImageForExercise(
          exerciseName: ex.name,
          primaryMuscleGroup: ex.primaryMuscleGroup,
          diagramType: ex.diagramType,
        );
        ex.videoUrl = ExerciseImageService.getVideoForExercise(
          exerciseName: ex.name,
          primaryMuscleGroup: ex.primaryMuscleGroup,
          diagramType: ex.diagramType,
        );
      }
    }
    await saveWorkouts(defaults);
    return defaults;
  }

  // --- History ---
  List<WorkoutHistoryEntry> loadHistory() {
    final str = _prefs.getString(_keyHistory);
    if (str != null && str.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(str);
        return list
            .map((e) => WorkoutHistoryEntry.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return _getDefaultHistory();
  }

  Future<void> saveHistory(List<WorkoutHistoryEntry> history) async {
    final jsonList = history.map((h) => h.toMap()).toList();
    await _prefs.setString(_keyHistory, json.encode(jsonList));
  }

  // --- Personal Records ---
  List<PersonalRecord> loadPRs() {
    final str = _prefs.getString(_keyPRs);
    if (str != null && str.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(str);
        return list
            .map((e) => PersonalRecord.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return _getDefaultPRs();
  }

  Future<void> savePRs(List<PersonalRecord> prs) async {
    final jsonList = prs.map((p) => p.toMap()).toList();
    await _prefs.setString(_keyPRs, json.encode(jsonList));
  }

  // --- Defaults com 7 Exercícios Variados e No Máximo 3 Repetições ---
  List<Workout> _getDefaultWorkouts() {
    return [
      Workout(
        id: 'w1',
        title: 'Treino A - Peito, Ombros e Tríceps (Força Pesada)',
        splitTag: 'A',
        targetMusclesSummary: 'Peitoral Maior, Deltoides, Tríceps (7 Exercícios)',
        durationMinutes: 60,
        daysOfWeek: ['Segunda', 'Quinta'],
        description: 'Variedade completa com 7 exercícios focados em força pesada e no máximo 3 repetições.',
        aiGenerated: true,
        aiPrompt: 'Alta variedade de empurrar com no máximo 3 repetições',
        completionCount: 14,
        exercises: [
          Exercise(
            id: 'e1_1',
            name: 'Supino Reto com Barra',
            targetMuscles: ['Peitoral Maior', 'Deltoide Anterior', 'Tríceps'],
            primaryMuscleGroup: 'chest',
            weightKg: 95.0,
            reps: 3,
            sets: 3,
            restSeconds: 120,
            observations: 'Descer controlando e explodir na subida mantendo escápulas travadas.',
            diagramType: 'bench_press',
            executionTips: [
              'Pés firmemente cravados no chão para leg drive máximo.',
              'Pausa de 1 segundo controlada no peito sem rebote.'
            ],
          ),
          Exercise(
            id: 'e1_2',
            name: 'Desenvolvimento Militar com Barra',
            targetMuscles: ['Deltoides', 'Trapézio', 'Tríceps'],
            primaryMuscleGroup: 'shoulders',
            weightKg: 62.0,
            reps: 3,
            sets: 3,
            restSeconds: 120,
            observations: 'Travar o abdômen e glúteos para proteção lombar total.',
            diagramType: 'shoulder_press',
            executionTips: [
              'Barra subindo vertical rente ao rosto com extensão forte.',
              'Manter o tronco ereto sem inclinar excessivamente para trás.'
            ],
          ),
          Exercise(
            id: 'e1_3',
            name: 'Supino Inclinado com Halteres Pesados',
            targetMuscles: ['Peitoral Superior', 'Deltoide Anterior'],
            primaryMuscleGroup: 'chest',
            weightKg: 36.0,
            reps: 3,
            sets: 3,
            restSeconds: 100,
            observations: 'Banco regulado a 30 graus para pico de tensão no peitoral superior.',
            diagramType: 'bench_press',
            executionTips: [
              'Controle biomecânico na descida.',
              'Subida em trajetória convergente sem tocar os halteres.'
            ],
          ),
          Exercise(
            id: 'e1_4',
            name: 'Mergulho nas Paralelas com Sobrecarga',
            targetMuscles: ['Tríceps', 'Peitoral Inferior'],
            primaryMuscleGroup: 'arms',
            weightKg: 25.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Anilha no cinto de carga. Descer até 90° nos cotovelos.',
            diagramType: 'tricep_pushdown',
            executionTips: [
              'Tronco levemente inclinado para recrutar cadeia peitoral.',
              'Extensão potente dos cotovelos na subida.'
            ],
          ),
          Exercise(
            id: 'e1_5',
            name: 'Elevação Lateral com Halteres Pesados',
            targetMuscles: ['Deltoide Lateral'],
            primaryMuscleGroup: 'shoulders',
            weightKg: 18.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Subida firme no plano escapular, descida em 3 segundos.',
            diagramType: 'lateral_raise',
            executionTips: [
              'Palmas voltadas para o chão.',
              'Sem impulso do tronco.'
            ],
          ),
          Exercise(
            id: 'e1_6',
            name: 'Supino Fechado com Barra (Tríceps Força)',
            targetMuscles: ['Tríceps Braquial', 'Peitoral Medial'],
            primaryMuscleGroup: 'arms',
            weightKg: 75.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Pegada na largura dos ombros, cotovelos rentes ao tronco.',
            diagramType: 'bench_press',
            executionTips: [
              'Empurrar focado na extensão forte dos cotovelos.',
              'Manter punhos alinhados sem dobrar para trás.'
            ],
          ),
          Exercise(
            id: 'e1_7',
            name: 'Tríceps Polia com Barra Reta Pesada',
            targetMuscles: ['Tríceps Cabeça Lateral'],
            primaryMuscleGroup: 'arms',
            weightKg: 55.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Carga pesada com estrito isolamento e pausa embaixo.',
            diagramType: 'tricep_pushdown',
            executionTips: [
              'Manter corpo estável sem balanço.',
              'Extensão total dos antebraços.'
            ],
          ),
        ],
      ),
      Workout(
        id: 'w2',
        title: 'Treino B - Costas, Bíceps e Trapézio (Puxada Pesada)',
        splitTag: 'B',
        targetMusclesSummary: 'Grande Dorsal, Bíceps, Trapézio (7 Exercícios)',
        durationMinutes: 60,
        daysOfWeek: ['Terça', 'Sexta'],
        description: 'Variedade estendida de puxadas com terra pesado, remadas e no máximo 3 repetições.',
        aiGenerated: true,
        aiPrompt: 'Alta variedade de puxadas com no máximo 3 repetições',
        completionCount: 12,
        exercises: [
          Exercise(
            id: 'e2_1',
            name: 'Levantamento Terra Convencional',
            targetMuscles: ['Eretores da Coluna', 'Glúteos', 'Isquiotibiais', 'Dorsal'],
            primaryMuscleGroup: 'back',
            weightKg: 155.0,
            reps: 2,
            sets: 2,
            restSeconds: 150,
            observations: 'Barra colada nas canelas. Puxar empurrando o chão com calcanhares.',
            diagramType: 'deadlift',
            executionTips: [
              'Trava respiratória intra-abdominal rigorosa.',
              'Coluna neutra e trava no topo sem hiperextender.'
            ],
          ),
          Exercise(
            id: 'e2_2',
            name: 'Puxada Alta Frontal na Polia Pegada Aberta',
            targetMuscles: ['Grande Dorsal', 'Bíceps'],
            primaryMuscleGroup: 'back',
            weightKg: 85.0,
            reps: 3,
            sets: 3,
            restSeconds: 100,
            observations: 'Puxar direcionando cotovelos para baixo em direção às costelas.',
            diagramType: 'lat_pulldown',
            executionTips: [
              'Alongamento completo das dorsais no topo.',
              'Sem jogar o tronco para trás.'
            ],
          ),
          Exercise(
            id: 'e2_3',
            name: 'Remada Curvada com Barra Pegada Pronada',
            targetMuscles: ['Rombóides', 'Grande Dorsal', 'Trapézio'],
            primaryMuscleGroup: 'back',
            weightKg: 90.0,
            reps: 3,
            sets: 3,
            restSeconds: 120,
            observations: 'Tronco fixo em 45 graus, puxar a barra até a linha do umbigo.',
            diagramType: 'barbell_row',
            executionTips: [
              'Adução escapular no topo do movimento.',
              'Lombar estabilizada sem flexão.'
            ],
          ),
          Exercise(
            id: 'e2_4',
            name: 'Barra Fixa com Sobrecarga (Weighted Pull-up)',
            targetMuscles: ['Dorsal', 'Bíceps'],
            primaryMuscleGroup: 'back',
            weightKg: 20.0,
            reps: 3,
            sets: 3,
            restSeconds: 120,
            observations: 'Anilha no cinto de carga. Passar o queixo acima da barra.',
            diagramType: 'lat_pulldown',
            executionTips: [
              'Subida potente sem balançar as pernas.',
              'Descida com controle excêntrico.'
            ],
          ),
          Exercise(
            id: 'e2_5',
            name: 'Remada Unilateral com Halter Pesado (Serrote)',
            targetMuscles: ['Grande Dorsal', 'Redondo Maior'],
            primaryMuscleGroup: 'back',
            weightKg: 44.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Apoio firme no banco reto, puxar o halter em direção ao quadril.',
            diagramType: 'barbell_row',
            executionTips: [
              'Contração unilateral profunda.',
              'Sem rotacionar a coluna vertebral.'
            ],
          ),
          Exercise(
            id: 'e2_6',
            name: 'Rosca Direta com Barra W Pesada',
            targetMuscles: ['Bíceps Braquial', 'Braquiorradial'],
            primaryMuscleGroup: 'arms',
            weightKg: 42.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Cotovelos alinhados e estáticos, sem usar embalo da lombar.',
            diagramType: 'bicep_curl',
            executionTips: [
              'Pausa de 1 segundo de contração no topo.',
              'Descida em 3 segundos.'
            ],
          ),
          Exercise(
            id: 'e2_7',
            name: 'Face Pull na Polia com Corda',
            targetMuscles: ['Deltoide Posterior', 'Trapézio', 'Manguito Rotador'],
            primaryMuscleGroup: 'shoulders',
            weightKg: 40.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Puxar na altura dos olhos e rotacionar as mãos para trás.',
            diagramType: 'lateral_raise',
            executionTips: [
              'Excelente para estabilização postural e saúde dos ombros.',
              'Manter o peito aberto durante a contração.'
            ],
          ),
        ],
      ),
      Workout(
        id: 'w3',
        title: 'Treino C - Pernas Completo (Agachamento & Força)',
        splitTag: 'C',
        targetMusclesSummary: 'Quadríceps, Glúteos, Isquiotibiais, Panturrilhas (7 Exercícios)',
        durationMinutes: 65,
        daysOfWeek: ['Quarta', 'Sábado'],
        description: 'Variedade completa de membros inferiores com foco em agachamento pesado e no máximo 3 reps.',
        aiGenerated: true,
        aiPrompt: 'Alta variedade de pernas com no máximo 3 repetições',
        completionCount: 10,
        exercises: [
          Exercise(
            id: 'e3_1',
            name: 'Agachamento Livre com Barra',
            targetMuscles: ['Quadríceps', 'Glúteo Máximo', 'Core'],
            primaryMuscleGroup: 'legs',
            weightKg: 135.0,
            reps: 3,
            sets: 3,
            restSeconds: 150,
            observations: 'Agachamento até quebrar a paralela de 90°. Calcanhares firmes.',
            diagramType: 'squat',
            executionTips: [
              'Peito aberto, olhar para frente.',
              'Joelhos na mesma linha dos pés.'
            ],
          ),
          Exercise(
            id: 'e3_2',
            name: 'Leg Press 45° com Carga Máxima',
            targetMuscles: ['Quadríceps', 'Glúteos'],
            primaryMuscleGroup: 'legs',
            weightKg: 280.0,
            reps: 3,
            sets: 3,
            restSeconds: 120,
            observations: 'Amplitude máxima sem descolar a lombar do assento.',
            diagramType: 'leg_press',
            executionTips: [
              'Pés no centro da plataforma.',
              'Não travar as articulações dos joelhos no topo.'
            ],
          ),
          Exercise(
            id: 'e3_3',
            name: 'Levantamento Terra Romeno (Stiff Pesado)',
            targetMuscles: ['Isquiotibiais', 'Glúteos', 'Lombar'],
            primaryMuscleGroup: 'legs',
            weightKg: 105.0,
            reps: 3,
            sets: 3,
            restSeconds: 120,
            observations: 'Projetar quadril para trás sentindo alongar a cadeia posterior.',
            diagramType: 'romanian_deadlift',
            executionTips: [
              'Barra colada às pernas durante todo o movimento.',
              'Coluna reta sem arredondar.'
            ],
          ),
          Exercise(
            id: 'e3_4',
            name: 'Agachamento Búlgaro com Halteres',
            targetMuscles: ['Glúteos', 'Quadríceps'],
            primaryMuscleGroup: 'legs',
            weightKg: 32.0,
            reps: 3,
            sets: 3,
            restSeconds: 100,
            observations: 'Pé de trás apoiado no banco. Estabilidade unilateral máxima.',
            diagramType: 'squat',
            executionTips: [
              'Descida vertical controlada.',
              'Tronco reto e abdômen firme.'
            ],
          ),
          Exercise(
            id: 'e3_5',
            name: 'Cadeira Extensora com Carga Alta',
            targetMuscles: ['Quadríceps (Reto Femoral)'],
            primaryMuscleGroup: 'legs',
            weightKg: 85.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Pausa isométrica de 1 segundo na extensão total.',
            diagramType: 'leg_press',
            executionTips: [
              'Manter o quadril bem travado no banco.',
              'Descida lenta controlada.'
            ],
          ),
          Exercise(
            id: 'e3_6',
            name: 'Mesa Flexora Pesada',
            targetMuscles: ['Isquiotibiais'],
            primaryMuscleGroup: 'legs',
            weightKg: 70.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Contração concentrada do bíceps femoral.',
            diagramType: 'romanian_deadlift',
            executionTips: [
              'Evitar levantar o quadril da mesa.',
              'Aproximar calcanhares dos glúteos.'
            ],
          ),
          Exercise(
            id: 'e3_7',
            name: 'Panturrilha no Smith em Pé com Sobrecarga',
            targetMuscles: ['Panturrilhas'],
            primaryMuscleGroup: 'legs',
            weightKg: 125.0,
            reps: 3,
            sets: 3,
            restSeconds: 90,
            observations: 'Amplitude vertical máxima, pausa de 2 segundos no ponto mais alto.',
            diagramType: 'squat',
            executionTips: [
              'Alongar profundamente os calcanhares embaixo.',
              'Elevação na ponta dos pés com potência.'
            ],
          ),
        ],
      ),
    ];
  }

  List<WorkoutHistoryEntry> _getDefaultHistory() {
    final now = DateTime.now();
    return [
      WorkoutHistoryEntry(
        id: 'h1',
        workoutTitle: 'Treino A - Peito, Ombros e Tríceps (Força Pesada)',
        splitTag: 'A',
        completedAt: now.subtract(const Duration(days: 1)),
        durationMinutes: 58,
        totalVolumeKg: 9850,
        totalSets: 25,
        exercisesCount: 7,
        caloriesEstimated: 460,
      ),
      WorkoutHistoryEntry(
        id: 'h2',
        workoutTitle: 'Treino B - Costas, Bíceps e Trapézio (Puxada Pesada)',
        splitTag: 'B',
        completedAt: now.subtract(const Duration(days: 3)),
        durationMinutes: 60,
        totalVolumeKg: 11400,
        totalSets: 25,
        exercisesCount: 7,
        caloriesEstimated: 490,
      ),
      WorkoutHistoryEntry(
        id: 'h3',
        workoutTitle: 'Treino C - Pernas Completo (Agachamento & Força)',
        splitTag: 'C',
        completedAt: now.subtract(const Duration(days: 5)),
        durationMinutes: 64,
        totalVolumeKg: 14850,
        totalSets: 26,
        exercisesCount: 7,
        caloriesEstimated: 540,
      ),
    ];
  }

  List<PersonalRecord> _getDefaultPRs() {
    final now = DateTime.now();
    return [
      PersonalRecord(
        exerciseName: 'Supino Reto com Barra',
        weightKg: 105.0,
        reps: 3,
        achievedAt: now.subtract(const Duration(days: 6)),
        muscleGroup: 'Peitoral',
      ),
      PersonalRecord(
        exerciseName: 'Agachamento Livre',
        weightKg: 140.0,
        reps: 3,
        achievedAt: now.subtract(const Duration(days: 4)),
        muscleGroup: 'Pernas',
      ),
      PersonalRecord(
        exerciseName: 'Levantamento Terra',
        weightKg: 165.0,
        reps: 2,
        achievedAt: now.subtract(const Duration(days: 10)),
        muscleGroup: 'Costas / Cadeia Posterior',
      ),
      PersonalRecord(
        exerciseName: 'Desenvolvimento Militar',
        weightKg: 68.0,
        reps: 3,
        achievedAt: now.subtract(const Duration(days: 12)),
        muscleGroup: 'Ombros',
      ),
      PersonalRecord(
        exerciseName: 'Leg Press 45°',
        weightKg: 320.0,
        reps: 3,
        achievedAt: now.subtract(const Duration(days: 3)),
        muscleGroup: 'Pernas',
      ),
    ];
  }
}
