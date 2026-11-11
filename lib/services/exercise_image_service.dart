/// Serviço para vincular e resolver prioritariamente imagens reais dos exercícios
/// da pasta 'source/imgs/exercicies'.
class ExerciseImageService {
  ExerciseImageService._();

  static const String _basePath = 'source/imgs/exercicies';

  // Mapa de resolução direta para exercícios clássicos e suas variações
  static const Map<String, String> _directExerciseMap = {
    // Peito / Chest
    'supino reto com barra': '$_basePath/chest/Bench Press.png',
    'supino reto': '$_basePath/chest/Bench Press.png',
    'supino inclinado': '$_basePath/chest/Incline Bench Press.png',
    'supino inclinado com halteres': '$_basePath/chest/Incline Bench Press.png',
    'supino declinado': '$_basePath/chest/Decline Dumbbell Fly.png',
    'crucifixo com halteres': '$_basePath/chest/Dumbbell Fly.png',
    'crucifixo na polia': '$_basePath/chest/Cable Standing Fly.png',
    'flexao de braco': '$_basePath/chest/Bench Press.png',

    // Ombros / Shoulders
    'desenvolvimento militar com barra': '$_basePath/shoulders/Smith Standing Behind Head Military Press.png',
    'desenvolvimento militar': '$_basePath/shoulders/Smith Standing Behind Head Military Press.png',
    'desenvolvimento com halteres': '$_basePath/shoulders/Arnold Press.png',
    'elevacao lateral com halteres': '$_basePath/chest/Lateral Raise.png',
    'elevacao lateral': '$_basePath/chest/Lateral Raise.png',
    'elevacao frontal': '$_basePath/shoulders/Dumbbell Standing Alternate Vertical Front Raises.png',
    'desenvolvimento arnold': '$_basePath/shoulders/Arnold Press.png',
    'face pull': '$_basePath/shoulders/Cable Standing Rear Delt Row.png',
    'encolhimento com barra': '$_basePath/back/Shrug.png',

    // Costas / Back
    'levantamento terra convencional': '$_basePath/back/Barbell Deadlift front view.png',
    'levantamento terra': '$_basePath/back/Barbell Deadlift front view.png',
    'puxada alta frontal na polia': '$_basePath/chest/Bar Lateral Pulldown.png',
    'puxada alta': '$_basePath/chest/Bar Lateral Pulldown.png',
    'remada curvada com barra': '$_basePath/chest/Bent Over Row.png',
    'remada curvada': '$_basePath/chest/Bent Over Row.png',
    'remada baixa': '$_basePath/back/Cable Low Seated Row.png',
    'barra fixa': '$_basePath/chest/Bar Lateral Pulldown.png',
    'remada unilateral com halter': '$_basePath/back/Lever Seated Row.png',
    'pulldown': '$_basePath/chest/Bar Lateral Pulldown.png',

    // Braços / Bíceps
    'rosca direta com barra w': '$_basePath/chest/Barbell Curl.png',
    'rosca direta': '$_basePath/chest/Barbell Curl.png',
    'rosca martelo': '$_basePath/chest/Hammer Curl.png',
    'rosca alternada': '$_basePath/chest/Alternate Biceps Curl.png',
    'rosca scott': '$_basePath/biceps/EZ Barbell Spider Curl_1.png',
    'rosca concentrada': '$_basePath/biceps/Barbell Standing Close Grip Curl.png',

    // Braços / Tríceps
    'triceps polia alta com corda': '$_basePath/chest/Triceps Pushdown.png',
    'triceps corda': '$_basePath/chest/Triceps Pushdown.png',
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

  /// Obtém prioritariamente o caminho do asset para o exercício informado
  static String? getImageForExercise({
    required String exerciseName,
    String? explicitImageUrl,
    String? primaryMuscleGroup,
    String? diagramType,
  }) {
    // 1. Se já tem explicitImageUrl que começa com source/, utiliza diretamente
    if (explicitImageUrl != null && explicitImageUrl.startsWith('source/')) {
      return explicitImageUrl;
    }

    // 2. Normaliza o nome do exercício
    final cleanName = _normalize(exerciseName);

    // 3. Busca exata no mapa de exercícios
    if (_directExerciseMap.containsKey(cleanName)) {
      return _directExerciseMap[cleanName];
    }

    // 4. Busca parcial por palavras-chave no nome do exercício
    for (final entry in _directExerciseMap.entries) {
      if (cleanName.contains(entry.key) || entry.key.contains(cleanName)) {
        return entry.value;
      }
    }

    // 5. Busca por diagramType
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

    // 6. Fallback pelo grupo muscular primário
    if (primaryMuscleGroup != null) {
      final key = primaryMuscleGroup.toLowerCase();
      if (_muscleGroupFallback.containsKey(key)) {
        return _muscleGroupFallback[key];
      }
    }

    return '$_basePath/chest/Bench Press.png';
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
