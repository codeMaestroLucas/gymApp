import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serviço centralizado para vincular e resolver imagens e vídeos de execução
/// dos exercícios a partir da pasta 'source/exercices/images' e 'source/exercices/videos'.
class ExerciseImageService {
  ExerciseImageService._();

  static const String _basePath = 'source/exercices/images';
  static const String _videoBasePath = 'source/exercices/videos';

  static bool _catalogLoaded = false;
  static final Map<String, Map<String, dynamic>> _catalogByName = {};

  /// Inicializa o catálogo lendo o arquivo assets/data/exercicios.json
  static Future<void> init() async {
    if (_catalogLoaded) return;
    try {
      if (!kIsWeb && File('assets/data/exercicios.json').existsSync()) {
        final content = File('assets/data/exercicios.json').readAsStringSync();
        loadFromJsonString(content);
        return;
      }
      final jsonString = await rootBundle
          .loadString('assets/data/exercicios.json')
          .timeout(const Duration(milliseconds: 600));
      loadFromJsonString(jsonString);
    } catch (_) {
      // Falha silenciosa em ambientes de teste sem assets carregados
    }
  }

  /// Carrega o catálogo a partir de uma string JSON
  static void loadFromJsonString(String jsonString) {
    try {
      final List<dynamic> list = json.decode(jsonString);
      _catalogByName.clear();
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final nome = (item['nome'] as String?)?.trim();
          if (nome != null && nome.isNotEmpty) {
            _catalogByName[_normalize(nome)] = item;
          }
        }
      }
      _catalogLoaded = true;
    } catch (_) {}
  }

  // Mapa de resolução direta para exercícios clássicos e suas variações
  static const Map<String, String> _directExerciseMap = {
    // Peito / Chest
    'supino reto com barra': '$_basePath/chest/Bench Press.png',
    'supino reto': '$_basePath/chest/Bench Press.png',
    'bench press': '$_basePath/chest/Bench Press.png',
    'supino inclinado': '$_basePath/chest/Incline Bench Press.png',
    'supino inclinado com halteres': '$_basePath/chest/Incline Bench Press.png',
    'incline bench press': '$_basePath/chest/Incline Bench Press.png',
    'supino declinado': '$_basePath/chest/Decline Dumbbell Fly.png',
    'crucifixo com halteres': '$_basePath/chest/Dumbbell Fly.png',
    'dumbbell fly': '$_basePath/chest/Dumbbell Fly.png',
    'crucifixo na polia': '$_basePath/chest/Cable Standing Fly.png',
    'cable standing fly': '$_basePath/chest/Cable Standing Fly.png',
    'flexao de braco': '$_basePath/chest/Bench Press.png',
    'push up': '$_basePath/chest/Push-up.png',

    // Ombros / Shoulders
    'desenvolvimento militar com barra': '$_basePath/shoulders/Smith Standing Behind Head Military Press.png',
    'desenvolvimento militar': '$_basePath/shoulders/Smith Standing Behind Head Military Press.png',
    'desenvolvimento com halteres': '$_basePath/shoulders/Arnold Press.png',
    'arnold press': '$_basePath/shoulders/Arnold Press.png',
    'elevacao lateral com halteres': '$_basePath/chest/Lateral Raise.png',
    'elevacao lateral': '$_basePath/chest/Lateral Raise.png',
    'lateral raise': '$_basePath/chest/Lateral Raise.png',
    'elevacao frontal': '$_basePath/shoulders/Dumbbell Standing Alternate Vertical Front Raises.png',
    'desenvolvimento arnold': '$_basePath/shoulders/Arnold Press.png',
    'face pull': '$_basePath/shoulders/Cable Standing Rear Delt Row.png',
    'encolhimento com barra': '$_basePath/back/Shrug.png',
    'shrug': '$_basePath/back/Shrug.png',

    // Costas / Back
    'levantamento terra convencional': '$_basePath/back/Barbell Deadlift front view.png',
    'levantamento terra': '$_basePath/back/Barbell Deadlift front view.png',
    'barbell deadlift': '$_basePath/back/Barbell Deadlift front view.png',
    'puxada alta frontal na polia': '$_basePath/chest/Bar Lateral Pulldown.png',
    'puxada alta': '$_basePath/chest/Bar Lateral Pulldown.png',
    'bar lateral pulldown': '$_basePath/chest/Bar Lateral Pulldown.png',
    'remada curvada com barra': '$_basePath/chest/Bent Over Row.png',
    'remada curvada': '$_basePath/chest/Bent Over Row.png',
    'bent over row': '$_basePath/chest/Bent Over Row.png',
    'remada baixa': '$_basePath/back/Cable Low Seated Row.png',
    'cable low seated row': '$_basePath/back/Cable Low Seated Row.png',
    'barra fixa': '$_basePath/chest/Bar Lateral Pulldown.png',
    'remada unilateral com halter': '$_basePath/back/Lever Seated Row.png',
    'lever seated row': '$_basePath/back/Lever Seated Row.png',
    'pulldown': '$_basePath/chest/Bar Lateral Pulldown.png',

    // Braços / Bíceps
    'rosca direta com barra w': '$_basePath/chest/Barbell Curl.png',
    'rosca direta': '$_basePath/chest/Barbell Curl.png',
    'barbell curl': '$_basePath/chest/Barbell Curl.png',
    'rosca martelo': '$_basePath/chest/Hammer Curl.png',
    'hammer curl': '$_basePath/chest/Hammer Curl.png',
    'rosca alternada': '$_basePath/chest/Alternate Biceps Curl.png',
    'alternate biceps curl': '$_basePath/chest/Alternate Biceps Curl.png',
    'rosca scott': '$_basePath/biceps/EZ Barbell Spider Curl_1.png',
    'rosca concentrada': '$_basePath/biceps/Barbell Standing Close Grip Curl.png',

    // Braços / Tríceps
    'triceps polia alta com corda': '$_basePath/chest/Triceps Pushdown.png',
    'triceps corda': '$_basePath/chest/Triceps Pushdown.png',
    'triceps pushdown': '$_basePath/chest/Triceps Pushdown.png',
    'triceps polia': '$_basePath/chest/Triceps Pushdown.png',
    'triceps testa': '$_basePath/triceps/Barbell Incline Triceps Extension Skull Crusher.png',
    'supino fechado com barra': '$_basePath/triceps/Close-grip Press.png',
    'supino fechado': '$_basePath/triceps/Close-grip Press.png',
    'mergulho nas paralelas': '$_basePath/triceps/Bench dip on floor.png',
    'triceps frances': '$_basePath/triceps/Seated Overhead Triceps Extension.png',
    'triceps banco': '$_basePath/triceps/Bench dip on floor.png',

    // Pernas / Quadríceps
    'agachamento livre com barra': '$_basePath/chest/Full Squat.png',
    'agachamento livre': '$_basePath/chest/Full Squat.png',
    'agachamento': '$_basePath/chest/Full Squat.png',
    'full squat': '$_basePath/chest/Full Squat.png',
    'leg press 45': '$_basePath/quadriceps/Lever Seated Leg Press_1.png',
    'leg press': '$_basePath/quadriceps/Lever Seated Leg Press_1.png',
    'cadeira extensora': '$_basePath/quadriceps/Lever Leg Extension_2.png',
    'agachamento bulgaro': '$_basePath/quadriceps/Single Leg Split Squat.png',
    'afundo': '$_basePath/quadriceps/Barbell Lunge.png',
    'passada': '$_basePath/quadriceps/Barbell Lunge.png',

    // Pernas / Isquiotibiais e Glúteos
    'stiff com halteres': '$_basePath/hips/Smith Deadlift.png',
    'stiff': '$_basePath/hips/Smith Deadlift.png',
    'levantamento terra romeno': '$_basePath/hips/Smith Deadlift.png',
    'mesa flexora': '$_basePath/hamstrings/Lever Seated Leg Curl.png',
    'cadeira flexora': '$_basePath/hamstrings/Lever Seated Leg Curl.png',
    'elevacao pelvica': '$_basePath/hips/Hyperextension.png',

    // Panturrilhas
    'panturrilha no smith': '$_basePath/calves/Barbell Standing Calf Raise.png',
    'panturrilha em pe': '$_basePath/calves/Barbell Standing Calf Raise.png',
    'panturrilha sentado': '$_basePath/calves/Lever seated one leg calf raise.png',
    'panturrilha': '$_basePath/calves/Bodyweight Standing Calf Raise.png',

    // Abdômen / Core
    'prancha abdominal': '$_basePath/waist/Hyperextension.png',
    'abdominal': '$_basePath/waist/Seated Flutter Kick.png',
  };

  // Mapa de resolução direta para vídeos de execução (source/exercices/videos)
  static const Map<String, String> _directVideoMap = {
    // Peito
    'supino reto com barra': '$_videoBasePath/chest/Bench Press.mp4',
    'supino reto': '$_videoBasePath/chest/Bench Press.mp4',
    'bench press': '$_videoBasePath/chest/Bench Press.mp4',
    'supino inclinado': '$_videoBasePath/chest/Incline Bench Press.mp4',
    'supino inclinado com halteres': '$_videoBasePath/chest/Incline Bench Press.mp4',
    'incline bench press': '$_videoBasePath/chest/Incline Bench Press.mp4',
    'crucifixo com halteres': '$_videoBasePath/chest/Dumbbell Fly.mp4',
    'dumbbell fly': '$_videoBasePath/chest/Dumbbell Fly.mp4',
    'crucifixo na polia': '$_videoBasePath/chest/Cable Standing Fly.mp4',
    'cable standing fly': '$_videoBasePath/chest/Cable Standing Fly.mp4',
    'flexao de braco': '$_videoBasePath/chest/Push-up.mp4',
    'push up': '$_videoBasePath/chest/Push-up.mp4',

    // Ombros
    'desenvolvimento militar': '$_videoBasePath/shoulders/Smith Standing Behind Head Military Press.mp4',
    'desenvolvimento com halteres': '$_videoBasePath/shoulders/Arnold Press.mp4',
    'arnold press': '$_videoBasePath/shoulders/Arnold Press.mp4',
    'elevacao lateral': '$_videoBasePath/shoulders/Lateral Raise.mp4',
    'lateral raise': '$_videoBasePath/shoulders/Lateral Raise.mp4',
    'face pull': '$_videoBasePath/shoulders/Cable Standing Rear Delt Row.mp4',
    'encolhimento com barra': '$_videoBasePath/back/Shrug.mp4',
    'shrug': '$_videoBasePath/back/Shrug.mp4',

    // Costas
    'levantamento terra': '$_videoBasePath/hips/Barbell Deadlift.mp4',
    'levantamento terra convencional': '$_videoBasePath/hips/Barbell Deadlift.mp4',
    'deadlift': '$_videoBasePath/hips/Barbell Deadlift.mp4',
    'barbell deadlift': '$_videoBasePath/hips/Barbell Deadlift.mp4',
    'puxada alta frontal na polia': '$_videoBasePath/back/Bar Lateral Pulldown.mp4',
    'puxada alta': '$_videoBasePath/back/Bar Lateral Pulldown.mp4',
    'bar lateral pulldown': '$_videoBasePath/back/Bar Lateral Pulldown.mp4',
    'remada curvada': '$_videoBasePath/back/Bent Over Row.mp4',
    'remada curvada com barra': '$_videoBasePath/back/Bent Over Row.mp4',
    'bent over row': '$_videoBasePath/back/Bent Over Row.mp4',
    'remada baixa': '$_videoBasePath/back/Cable Low Seated Row.mp4',
    'cable low seated row': '$_videoBasePath/back/Cable Low Seated Row.mp4',
    'remada unilateral com halter': '$_videoBasePath/back/Lever Seated Row.mp4',
    'lever seated row': '$_videoBasePath/back/Lever Seated Row.mp4',

    // Braços
    'rosca direta com barra w': '$_videoBasePath/biceps/Barbell Curl.mp4',
    'rosca direta': '$_videoBasePath/biceps/Barbell Curl.mp4',
    'barbell curl': '$_videoBasePath/biceps/Barbell Curl.mp4',
    'rosca martelo': '$_videoBasePath/biceps/Hammer Curl.mp4',
    'hammer curl': '$_videoBasePath/biceps/Hammer Curl.mp4',
    'rosca alternada': '$_videoBasePath/biceps/Alternate Biceps Curl.mp4',
    'triceps polia alta com corda': '$_videoBasePath/upperArms/Triceps Pushdown.mp4',
    'triceps corda': '$_videoBasePath/upperArms/Triceps Pushdown.mp4',
    'triceps pushdown': '$_videoBasePath/upperArms/Triceps Pushdown.mp4',
    'triceps polia': '$_videoBasePath/upperArms/Triceps Pushdown.mp4',

    // Pernas
    'agachamento livre com barra': '$_videoBasePath/quadriceps/Full Squat.mp4',
    'agachamento livre': '$_videoBasePath/quadriceps/Full Squat.mp4',
    'agachamento': '$_videoBasePath/quadriceps/Full Squat.mp4',
    'full squat': '$_videoBasePath/quadriceps/Full Squat.mp4',
    'stiff': '$_videoBasePath/hips/Smith Deadlift.mp4',
    'stiff com halteres': '$_videoBasePath/hips/Smith Deadlift.mp4',
    'levantamento terra romeno': '$_videoBasePath/hips/Smith Deadlift.mp4',
    'mesa flexora': '$_videoBasePath/hamstrings/Lever Seated Leg Curl.mp4',
    'panturrilha em pe': '$_videoBasePath/calves/Barbell Standing Calf Raise.mp4',
    'panturrilha': '$_videoBasePath/calves/Barbell Standing Calf Raise.mp4',
  };

  // Fallback por grupo muscular primário
  static const Map<String, String> _muscleGroupFallback = {
    'chest': '$_basePath/chest/Bench Press.png',
    'peito': '$_basePath/chest/Bench Press.png',
    'shoulders': '$_basePath/shoulders/Arnold Press.png',
    'ombros': '$_basePath/shoulders/Arnold Press.png',
    'back': '$_basePath/back/Barbell Deadlift front view.png',
    'costas': '$_basePath/back/Barbell Deadlift front view.png',
    'biceps': '$_basePath/chest/Barbell Curl.png',
    'arms': '$_basePath/chest/Triceps Pushdown.png',
    'bracos': '$_basePath/chest/Triceps Pushdown.png',
    'triceps': '$_basePath/chest/Triceps Pushdown.png',
    'legs': '$_basePath/chest/Full Squat.png',
    'quadriceps': '$_basePath/chest/Full Squat.png',
    'pernas': '$_basePath/chest/Full Squat.png',
    'hamstrings': '$_basePath/hamstrings/Lever Seated Leg Curl.png',
    'calves': '$_basePath/calves/Barbell Standing Calf Raise.png',
    'core': '$_basePath/waist/Hyperextension.png',
  };

  /// Obtém prioritariamente o caminho da imagem oficial para o exercício informado
  static String? getImageForExercise({
    required String exerciseName,
    String? explicitImageUrl,
    String? primaryMuscleGroup,
    String? diagramType,
  }) {
    // 1. Se já tem explicitImageUrl válido, atualiza para o novo caminho se necessário
    if (explicitImageUrl != null && explicitImageUrl.isNotEmpty) {
      if (explicitImageUrl.contains('source/imgs/exercicies')) {
        return explicitImageUrl.replaceAll('source/imgs/exercicies', _basePath);
      }
      if (explicitImageUrl.startsWith('source/')) {
        return explicitImageUrl;
      }
    }

    // 2. Normaliza o nome do exercício
    final cleanName = _normalize(exerciseName);

    // 3. Busca exata no catálogo carregado de exercicios.json
    if (_catalogByName.containsKey(cleanName)) {
      final img = _catalogByName[cleanName]!['caminho_imagem'] as String?;
      if (img != null && img.isNotEmpty) return img;
    }

    // 4. Busca exata no mapa estático de exercícios
    if (_directExerciseMap.containsKey(cleanName)) {
      return _directExerciseMap[cleanName];
    }

    // 5. Busca parcial por palavras-chave no catálogo
    for (final entry in _catalogByName.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        final img = entry.value['caminho_imagem'] as String?;
        if (img != null && img.isNotEmpty) return img;
      }
    }

    // 6. Busca parcial por palavras-chave no mapa direto
    for (final entry in _directExerciseMap.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return entry.value;
      }
    }

    // 7. Busca por diagramType
    if (diagramType != null) {
      final cleanDiagram = diagramType.toLowerCase();
      switch (cleanDiagram) {
        case 'bench_press':
        case 'incline_press':
          return '$_basePath/chest/Bench Press.png';
        case 'squat':
          return '$_basePath/chest/Full Squat.png';
        case 'leg_press':
          return '$_basePath/quadriceps/Lever Seated Leg Press_1.png';
        case 'deadlift':
          return '$_basePath/back/Barbell Deadlift front view.png';
        case 'romanian_deadlift':
          return '$_basePath/hips/Smith Deadlift.png';
        case 'lat_pulldown':
        case 'barbell_row':
          return '$_basePath/chest/Bar Lateral Pulldown.png';
        case 'shoulder_press':
          return '$_basePath/shoulders/Smith Standing Behind Head Military Press.png';
        case 'lateral_raise':
          return '$_basePath/chest/Lateral Raise.png';
        case 'bicep_curl':
          return '$_basePath/chest/Barbell Curl.png';
        case 'tricep_pushdown':
          return '$_basePath/chest/Triceps Pushdown.png';
      }
    }

    // 8. Fallback pelo grupo muscular primário
    if (primaryMuscleGroup != null) {
      final key = primaryMuscleGroup.toLowerCase();
      if (_muscleGroupFallback.containsKey(key)) {
        return _muscleGroupFallback[key];
      }
    }

    return '$_basePath/chest/Bench Press.png';
  }

  /// Obtém prioritariamente o caminho do vídeo de execução do exercício, ou null se não houver vídeo
  static String? getVideoForExercise({
    required String exerciseName,
    String? explicitVideoUrl,
    String? primaryMuscleGroup,
    String? diagramType,
  }) {
    // 1. Se já fornecido diretamente
    if (explicitVideoUrl != null && explicitVideoUrl.isNotEmpty) {
      return explicitVideoUrl;
    }

    final cleanName = _normalize(exerciseName);

    // 2. Busca exata no catálogo carregado
    if (_catalogByName.containsKey(cleanName)) {
      final vid = _catalogByName[cleanName]!['caminho_video'] as String?;
      if (vid != null && vid.isNotEmpty) return vid;
    }

    // 3. Busca no mapa direto de vídeos
    if (_directVideoMap.containsKey(cleanName)) {
      return _directVideoMap[cleanName];
    }

    // 4. Busca parcial no catálogo
    for (final entry in _catalogByName.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        final vid = entry.value['caminho_video'] as String?;
        if (vid != null && vid.isNotEmpty) return vid;
      }
    }

    // 5. Busca parcial no mapa direto
    for (final entry in _directVideoMap.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return entry.value;
      }
    }

    // 6. Busca por diagramType
    if (diagramType != null) {
      final cleanDiagram = diagramType.toLowerCase();
      switch (cleanDiagram) {
        case 'bench_press':
          return '$_videoBasePath/chest/Bench Press.mp4';
        case 'incline_press':
          return '$_videoBasePath/chest/Incline Bench Press.mp4';
        case 'squat':
          return '$_videoBasePath/quadriceps/Full Squat.mp4';
        case 'deadlift':
          return '$_videoBasePath/hips/Barbell Deadlift.mp4';
        case 'romanian_deadlift':
          return '$_videoBasePath/hips/Smith Deadlift.mp4';
        case 'lat_pulldown':
          return '$_videoBasePath/back/Bar Lateral Pulldown.mp4';
        case 'barbell_row':
          return '$_videoBasePath/back/Bent Over Row.mp4';
        case 'shoulder_press':
          return '$_videoBasePath/shoulders/Arnold Press.mp4';
        case 'lateral_raise':
          return '$_videoBasePath/shoulders/Lateral Raise.mp4';
        case 'bicep_curl':
          return '$_videoBasePath/biceps/Barbell Curl.mp4';
        case 'tricep_pushdown':
          return '$_videoBasePath/upperArms/Triceps Pushdown.mp4';
      }
    }

    return null;
  }

  /// Informações completas do catálogo (nível, imagem, vídeo, grupo muscular)
  static Map<String, dynamic>? getExerciseInfo(String exerciseName) {
    final cleanName = _normalize(exerciseName);
    if (_catalogByName.containsKey(cleanName)) {
      return _catalogByName[cleanName];
    }
    for (final entry in _catalogByName.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return entry.value;
      }
    }
    return null;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .trim();
  }
}
