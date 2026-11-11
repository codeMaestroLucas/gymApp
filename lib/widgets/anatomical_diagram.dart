import 'package:flutter/material.dart';
import '../services/exercise_image_service.dart';
import '../theme/app_colors.dart';

/// Diagrama anatômico e visualizador de execução de exercícios com pesos.
/// Exibe prioritariamente a imagem real da pasta source/imgs/exercicies,
/// com opções para alternar entre Biomecânica e Anatomia Muscular.
class AnatomicalDiagram extends StatefulWidget {
  final String diagramType;
  final String exerciseName;
  final String primaryMuscleGroup;
  final List<String> targetMuscles;
  final String? imageUrl;
  final double height;
  final bool showExecutionCues;

  const AnatomicalDiagram({
    super.key,
    required this.diagramType,
    required this.exerciseName,
    required this.primaryMuscleGroup,
    required this.targetMuscles,
    this.imageUrl,
    this.height = 195,
    this.showExecutionCues = true,
  });

  @override
  State<AnatomicalDiagram> createState() => _AnatomicalDiagramState();
}

class _AnatomicalDiagramState extends State<AnatomicalDiagram>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _activeViewIndex = 0; // 0: Imagem do Exercício, 1: Postura/Biomecânica, 2: Anatomia Muscular
  String? _resolvedImagePath;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _resolvedImagePath = ExerciseImageService.getImageForExercise(
      exerciseName: widget.exerciseName,
      explicitImageUrl: widget.imageUrl,
      primaryMuscleGroup: widget.primaryMuscleGroup,
      diagramType: widget.diagramType,
    );
  }

  @override
  void didUpdateWidget(covariant AnatomicalDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseName != widget.exerciseName ||
        oldWidget.imageUrl != widget.imageUrl) {
      _resolvedImagePath = ExerciseImageService.getImageForExercise(
        exerciseName: widget.exerciseName,
        explicitImageUrl: widget.imageUrl,
        primaryMuscleGroup: widget.primaryMuscleGroup,
        diagramType: widget.diagramType,
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF161212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Fundo com sutil malha grid técnica
          Positioned.fill(
            child: CustomPaint(
              painter: _TechGridPainter(),
            ),
          ),

          // Área da visualização principal
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                if (_activeViewIndex == 0 && _resolvedImagePath != null) {
                  return _buildAssetImageView();
                } else if (_activeViewIndex == 1 || _resolvedImagePath == null) {
                  return CustomPaint(
                    painter: _ExerciseExecutionPainter(
                      diagramType: widget.diagramType,
                      phaseProgress: _animController.value,
                    ),
                  );
                } else {
                  return CustomPaint(
                    painter: _MuscleAnatomyPainter(
                      muscleGroup: widget.primaryMuscleGroup,
                      targetMuscles: widget.targetMuscles,
                      pulseProgress: _animController.value,
                    ),
                  );
                }
              },
            ),
          ),

          // Seletor de visualização (Foto vs Postura vs Anatomia)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.cardBackground.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTabPill(
                    icon: Icons.image_rounded,
                    label: 'Foto',
                    isSelected: _activeViewIndex == 0,
                    onTap: () => setState(() => _activeViewIndex = 0),
                  ),
                  const SizedBox(width: 2),
                  _buildTabPill(
                    icon: Icons.fitness_center_rounded,
                    label: 'Vetor',
                    isSelected: _activeViewIndex == 1,
                    onTap: () => setState(() => _activeViewIndex = 1),
                  ),
                  const SizedBox(width: 2),
                  _buildTabPill(
                    icon: Icons.accessibility_new_rounded,
                    label: 'Músculos',
                    isSelected: _activeViewIndex == 2,
                    onTap: () => setState(() => _activeViewIndex = 2),
                  ),
                ],
              ),
            ),
          ),

          // Legenda inferior com grupos musculares e indicador
          Positioned(
            left: 12,
            bottom: 8,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          widget.targetMuscles.isNotEmpty
                              ? widget.targetMuscles.join(' • ')
                              : widget.primaryMuscleGroup.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primaryOrange.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    _activeViewIndex == 0
                        ? 'DIAGRAMA OFICIAL'
                        : (_activeViewIndex == 1 ? 'FASE DINÂMICA' : 'MAPA MUSCULAR'),
                    style: const TextStyle(
                      color: AppColors.primaryOrange,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetImageView() {
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 26, left: 14, right: 14),
      alignment: Alignment.center,
      child: Image.asset(
        _resolvedImagePath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Se falhar o carregamento do arquivo, renderiza o diagrama vetorial
          return CustomPaint(
            painter: _ExerciseExecutionPainter(
              diagramType: widget.diagramType,
              phaseProgress: _animController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabPill({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter que renderiza uma grade técnica sutil de fundo
class _TechGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF231D1D).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter para biomecânica da execução do exercício com pesos
class _ExerciseExecutionPainter extends CustomPainter {
  final String diagramType;
  final double phaseProgress;

  _ExerciseExecutionPainter({
    required this.diagramType,
    required this.phaseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.45, size.height * 0.48);

    switch (diagramType.toLowerCase()) {
      case 'bench_press':
      case 'incline_press':
        _drawBenchPress(canvas, size, center);
        break;
      case 'squat':
      case 'leg_press':
        _drawSquat(canvas, size, center);
        break;
      case 'lat_pulldown':
      case 'barbell_row':
        _drawLatPulldown(canvas, size, center);
        break;
      case 'deadlift':
      case 'romanian_deadlift':
        _drawDeadlift(canvas, size, center);
        break;
      case 'shoulder_press':
      case 'lateral_raise':
        _drawShoulderPress(canvas, size, center);
        break;
      case 'bicep_curl':
      case 'tricep_pushdown':
        _drawArmCurl(canvas, size, center);
        break;
      default:
        _drawGenericExercise(canvas, size, center);
    }
  }

  void _drawBenchPress(Canvas canvas, Size size, Offset center) {
    final benchPaint = Paint()
      ..color = const Color(0xFF383030)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final bodyPaint = Paint()
      ..color = const Color(0xFF8E8380)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5;

    final weightPlatePaint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.fill;

    final benchY = center.dy + 25;
    canvas.drawLine(Offset(center.dx - 55, benchY), Offset(center.dx + 55, benchY), benchPaint);
    canvas.drawLine(Offset(center.dx - 35, benchY), Offset(center.dx - 35, benchY + 22), benchPaint);
    canvas.drawLine(Offset(center.dx + 35, benchY), Offset(center.dx + 35, benchY + 22), benchPaint);

    canvas.drawCircle(Offset(center.dx - 38, benchY - 10), 10, bodyPaint);
    canvas.drawLine(Offset(center.dx - 28, benchY - 7), Offset(center.dx + 25, benchY - 7), bodyPaint);
    canvas.drawLine(Offset(center.dx + 25, benchY - 7), Offset(center.dx + 42, benchY + 22), bodyPaint);

    final barOffset = 18 * phaseProgress;
    final currentBarY = (center.dy - 22) + barOffset;

    canvas.drawLine(Offset(center.dx - 10, benchY - 7), Offset(center.dx - 5, currentBarY), activePaint);
    canvas.drawLine(Offset(center.dx + 10, benchY - 7), Offset(center.dx + 15, currentBarY), activePaint);

    canvas.drawLine(Offset(center.dx - 50, currentBarY), Offset(center.dx + 50, currentBarY), barPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 48, currentBarY), width: 8, height: 28),
        const Radius.circular(2),
      ),
      weightPlatePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 48, currentBarY), width: 8, height: 28),
        const Radius.circular(2),
      ),
      weightPlatePaint,
    );
  }

  void _drawSquat(Canvas canvas, Size size, Offset center) {
    final bodyPaint = Paint()
      ..color = const Color(0xFF8E8380)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;

    final squatDepth = 16 * phaseProgress;
    final hipY = center.dy + 8 + squatDepth;
    final torsoTopY = hipY - 38;

    canvas.drawCircle(Offset(center.dx, torsoTopY - 10), 9, bodyPaint);
    canvas.drawLine(Offset(center.dx, torsoTopY), Offset(center.dx - 6, hipY), bodyPaint);

    final kneeX = center.dx + 18 - (squatDepth * 0.4);
    final kneeY = hipY + 18;
    canvas.drawLine(Offset(center.dx - 6, hipY), Offset(kneeX, kneeY), activePaint);

    canvas.drawLine(Offset(kneeX, kneeY), Offset(center.dx + 12, center.dy + 45), bodyPaint);
    canvas.drawLine(Offset(center.dx - 40, center.dy + 46), Offset(center.dx + 40, center.dy + 46),
        Paint()..color = AppColors.cardBorder..strokeWidth = 2);

    canvas.drawLine(Offset(center.dx - 40, torsoTopY + 2), Offset(center.dx + 40, torsoTopY + 2), barPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 38, torsoTopY + 2), width: 7, height: 26),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.primaryOrange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 38, torsoTopY + 2), width: 7, height: 26),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.primaryOrange,
    );
  }

  void _drawLatPulldown(Canvas canvas, Size size, Offset center) {
    final machinePaint = Paint()..color = const Color(0xFF3A3030)..strokeWidth = 3;
    final bodyPaint = Paint()..color = const Color(0xFF8E8380)..strokeWidth = 6..strokeCap = StrokeCap.round;
    final activePaint = Paint()..color = AppColors.primaryOrange..strokeWidth = 5..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(center.dx - 45, center.dy - 45), Offset(center.dx + 45, center.dy - 45), machinePaint);
    canvas.drawCircle(Offset(center.dx, center.dy - 45), 5, machinePaint);

    final pullY = (center.dy - 35) + (22 * phaseProgress);
    canvas.drawLine(Offset(center.dx, center.dy - 45), Offset(center.dx, pullY), machinePaint);

    canvas.drawLine(Offset(center.dx - 42, pullY + 4), Offset(center.dx + 42, pullY + 4),
        Paint()..color = Colors.white..strokeWidth = 3.5);

    canvas.drawCircle(Offset(center.dx, center.dy - 2), 8, bodyPaint);
    canvas.drawLine(Offset(center.dx, center.dy + 6), Offset(center.dx, center.dy + 35), activePaint);

    canvas.drawLine(Offset(center.dx - 8, center.dy + 10), Offset(center.dx - 35, pullY + 4), bodyPaint);
    canvas.drawLine(Offset(center.dx + 8, center.dy + 10), Offset(center.dx + 35, pullY + 4), bodyPaint);

    canvas.drawLine(Offset(center.dx - 25, center.dy + 35), Offset(center.dx + 25, center.dy + 35), machinePaint);
  }

  void _drawDeadlift(Canvas canvas, Size size, Offset center) {
    final bodyPaint = Paint()..color = const Color(0xFF8E8380)..strokeWidth = 6..strokeCap = StrokeCap.round;
    final activePaint = Paint()..color = AppColors.primaryOrange..strokeWidth = 6..strokeCap = StrokeCap.round;

    final liftDelta = 18 * phaseProgress;
    final barY = (center.dy + 32) - liftDelta;

    final hipY = (center.dy + 14) - (liftDelta * 0.7);
    canvas.drawCircle(Offset(center.dx - 4, hipY - 32), 8, bodyPaint);
    canvas.drawLine(Offset(center.dx - 4, hipY - 24), Offset(center.dx - 8, hipY), activePaint);

    canvas.drawLine(Offset(center.dx - 8, hipY), Offset(center.dx + 8, center.dy + 36), activePaint);
    canvas.drawLine(Offset(center.dx - 2, hipY - 20), Offset(center.dx + 12, barY), bodyPaint);

    canvas.drawLine(Offset(center.dx - 36, barY), Offset(center.dx + 45, barY),
        Paint()..color = Colors.white..strokeWidth = 3.5);

    canvas.drawCircle(Offset(center.dx - 32, barY), 12, Paint()..color = AppColors.primaryOrange);
    canvas.drawCircle(Offset(center.dx + 40, barY), 12, Paint()..color = AppColors.primaryOrange);
  }

  void _drawShoulderPress(Canvas canvas, Size size, Offset center) {
    final bodyPaint = Paint()..color = const Color(0xFF8E8380)..strokeWidth = 6..strokeCap = StrokeCap.round;
    final deltoidsPaint = Paint()..color = AppColors.primaryOrange..strokeWidth = 6..strokeCap = StrokeCap.round;

    final barMove = 22 * phaseProgress;
    final barY = (center.dy - 10) - barMove;

    canvas.drawCircle(Offset(center.dx, center.dy), 9, bodyPaint);
    canvas.drawLine(Offset(center.dx, center.dy + 9), Offset(center.dx, center.dy + 40), bodyPaint);

    canvas.drawLine(Offset(center.dx - 18, center.dy + 13), Offset(center.dx + 18, center.dy + 13), deltoidsPaint);

    canvas.drawLine(Offset(center.dx - 18, center.dy + 13), Offset(center.dx - 28, barY), bodyPaint);
    canvas.drawLine(Offset(center.dx + 18, center.dy + 13), Offset(center.dx + 28, barY), bodyPaint);

    canvas.drawLine(Offset(center.dx - 45, barY), Offset(center.dx + 45, barY),
        Paint()..color = Colors.white..strokeWidth = 3.5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 42, barY), width: 7, height: 24),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.primaryOrange,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 42, barY), width: 7, height: 24),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.primaryOrange,
    );
  }

  void _drawArmCurl(Canvas canvas, Size size, Offset center) {
    final bodyPaint = Paint()..color = const Color(0xFF8E8380)..strokeWidth = 6..strokeCap = StrokeCap.round;
    final bicepPaint = Paint()..color = AppColors.primaryOrange..strokeWidth = 6..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(center.dx - 15, center.dy - 20), 9, bodyPaint);
    canvas.drawLine(Offset(center.dx - 15, center.dy - 11), Offset(center.dx - 15, center.dy + 35), bodyPaint);

    final shoulder = Offset(center.dx - 10, center.dy - 5);
    final elbow = Offset(center.dx - 8, center.dy + 15);
    canvas.drawLine(shoulder, elbow, bicepPaint);

    final hand = Offset(
      elbow.dx + 20 * (1 - phaseProgress),
      elbow.dy - 15 * phaseProgress,
    );
    canvas.drawLine(elbow, hand, bodyPaint);
    canvas.drawCircle(hand, 7, Paint()..color = AppColors.primaryOrange);
  }

  void _drawGenericExercise(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 28, paint);
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = AppColors.accentYellow.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ExerciseExecutionPainter oldDelegate) =>
      oldDelegate.phaseProgress != phaseProgress || oldDelegate.diagramType != diagramType;
}

/// Painter para anatomia humana com destaque muscular néon nos músculos alvo
class _MuscleAnatomyPainter extends CustomPainter {
  final String muscleGroup;
  final List<String> targetMuscles;
  final double pulseProgress;

  _MuscleAnatomyPainter({
    required this.muscleGroup,
    required this.targetMuscles,
    required this.pulseProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.45, size.height * 0.48);

    final basePaint = Paint()
      ..color = const Color(0xFF2C2424)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF483E3E)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final glowAlpha = (0.7 + (0.3 * pulseProgress)).clamp(0.0, 1.0);
    final activeHighlight = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.fill;

    final secondaryHighlight = Paint()
      ..color = AppColors.accentYellow.withValues(alpha: glowAlpha * 0.8)
      ..style = PaintingStyle.fill;

    // Cabeça
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy - 56), width: 18, height: 22),
      basePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy - 56), width: 18, height: 22),
      outlinePaint,
    );

    // Trapézio
    final isTrapActive = _isMuscleActive(['trapézio', 'costas', 'back', 'ombros']);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 42), width: 22, height: 12),
        const Radius.circular(4),
      ),
      isTrapActive ? secondaryHighlight : basePaint,
    );

    // Peitoral Maior
    final isChest = _isMuscleActive(['peito', 'peitoral', 'chest']);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 12, center.dy - 25), width: 20, height: 18),
        const Radius.circular(5),
      ),
      isChest ? activeHighlight : basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 12, center.dy - 25), width: 20, height: 18),
        const Radius.circular(5),
      ),
      isChest ? activeHighlight : basePaint,
    );

    // Ombros / Deltoides
    final isShoulders = _isMuscleActive(['ombro', 'deltoide', 'shoulders']);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 27, center.dy - 30), width: 14, height: 16),
      isShoulders ? activeHighlight : (isChest ? secondaryHighlight : basePaint),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 27, center.dy - 30), width: 14, height: 16),
      isShoulders ? activeHighlight : (isChest ? secondaryHighlight : basePaint),
    );

    // Braços (Bíceps / Tríceps)
    final isArms = _isMuscleActive(['bíceps', 'tríceps', 'braço', 'arms', 'antebraço']);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 32, center.dy - 10), width: 10, height: 22),
        const Radius.circular(4),
      ),
      isArms ? activeHighlight : (isChest ? secondaryHighlight : basePaint),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 32, center.dy - 10), width: 10, height: 22),
        const Radius.circular(4),
      ),
      isArms ? activeHighlight : (isChest ? secondaryHighlight : basePaint),
    );

    // Abdômen e Core
    final isCore = _isMuscleActive(['abdômen', 'core', 'reto abdominal', 'oblíquos']);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy - 6), width: 24, height: 18),
        const Radius.circular(4),
      ),
      isCore ? activeHighlight : basePaint,
    );

    // Pernas (Quadríceps e Glúteos)
    final isLegs = _isMuscleActive(['pernas', 'quadríceps', 'glúteo', 'coxas', 'legs']);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx - 11, center.dy + 20), width: 17, height: 32),
        const Radius.circular(6),
      ),
      isLegs ? activeHighlight : basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx + 11, center.dy + 20), width: 17, height: 32),
        const Radius.circular(6),
      ),
      isLegs ? activeHighlight : basePaint,
    );

    // Panturrilhas
    final isCalves = _isMuscleActive(['panturrilha', 'calves', 'pernas']);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - 11, center.dy + 48), width: 13, height: 20),
      isCalves ? activeHighlight : basePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 11, center.dy + 48), width: 13, height: 20),
      isCalves ? activeHighlight : basePaint,
    );
  }

  bool _isMuscleActive(List<String> keywords) {
    final lowerGroup = muscleGroup.toLowerCase();
    for (final kw in keywords) {
      if (lowerGroup.contains(kw)) return true;
      for (final t in targetMuscles) {
        if (t.toLowerCase().contains(kw)) return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _MuscleAnatomyPainter oldDelegate) =>
      oldDelegate.pulseProgress != pulseProgress || oldDelegate.muscleGroup != muscleGroup;
}
