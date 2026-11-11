import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Gráfico customizado de volume semanal com gradiente neon laranja
class WeeklyVolumeChart extends StatelessWidget {
  final List<double> weeklyVolumes; // 7 dias (Seg a Dom) em Toneladas
  final List<String> dayLabels;

  const WeeklyVolumeChart({
    super.key,
    required this.weeklyVolumes,
    this.dayLabels = const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'],
  });

  @override
  Widget build(BuildContext context) {
    final maxVol = weeklyVolumes.isNotEmpty
        ? weeklyVolumes.reduce(math.max)
        : 10.0;
    final safeMax = maxVol > 0 ? maxVol * 1.2 : 10.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.only(top: 14, left: 10, right: 10, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(weeklyVolumes.length, (index) {
          final val = weeklyVolumes[index];
          final ratio = (val / safeMax).clamp(0.06, 1.0);
          final isToday = index == 2; // quarta-feira mock ou atual

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (val > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${val.toStringAsFixed(1)}t',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? AppColors.primaryOrange
                          : AppColors.textSecondary,
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),

              // Barra
              Container(
                width: 26,
                height: 90 * ratio,
                decoration: BoxDecoration(
                  gradient: val > 0
                      ? const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF8A3800),
                            AppColors.primaryOrange,
                          ],
                        )
                      : null,
                  color: val == 0 ? const Color(0xFF241F1F) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1)
                      : null,
                  boxShadow: val > 0
                      ? [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 8),

              // Rótulo do dia
              Text(
                dayLabels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday
                      ? AppColors.primaryOrange
                      : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Gráfico de curva suave para evolução corporal (Peso kg ao longo das semanas)
class BodyWeightCurveChart extends StatelessWidget {
  final List<double> weightPoints; // histórico de pesagens
  final List<String> dateLabels;

  const BodyWeightCurveChart({
    super.key,
    required this.weightPoints,
    required this.dateLabels,
  });

  @override
  Widget build(BuildContext context) {
    if (weightPoints.length < 2) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Adicione mais medições de peso para ver a curva',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: CustomPaint(
        painter: _WeightLineChartPainter(
          points: weightPoints,
          labels: dateLabels,
        ),
      ),
    );
  }
}

class _WeightLineChartPainter extends CustomPainter {
  final List<double> points;
  final List<String> labels;

  _WeightLineChartPainter({required this.points, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final double minVal = points.reduce(math.min) - 1.5;
    final double maxVal = points.reduce(math.max) + 1.5;
    final double range = maxVal - minVal;

    final paddingHorizontal = 24.0;
    final paddingVertical = 20.0;
    final chartWidth = size.width - (paddingHorizontal * 2);
    final chartHeight = size.height - (paddingVertical * 2);

    final linePaint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final fillPath = Path();

    final stepX = chartWidth / (points.length - 1);
    final coordinates = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = paddingHorizontal + (i * stepX);
      final y = paddingVertical +
          chartHeight -
          (((points[i] - minVal) / range) * chartHeight);
      coordinates.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, paddingVertical + chartHeight);
        fillPath.lineTo(x, y);
      } else {
        final prev = coordinates[i - 1];
        final controlX1 = prev.dx + (x - prev.dx) / 2;
        final controlX2 = prev.dx + (x - prev.dx) / 2;
        path.cubicTo(controlX1, prev.dy, controlX2, y, x, y);
        fillPath.cubicTo(controlX1, prev.dy, controlX2, y, x, y);
      }
    }

    fillPath.lineTo(
        coordinates.last.dx, paddingVertical + chartHeight);
    fillPath.close();

    // Gradiente preenchimento inferior
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primaryOrange.withValues(alpha: 0.35),
        AppColors.primaryOrange.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, paddingVertical, size.width, chartHeight),
      );

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Pontos e rótulos
    for (int i = 0; i < coordinates.length; i++) {
      final pt = coordinates[i];
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 5, dotBorderPaint);

      // Texto de peso acima do ponto
      final textSpan = TextSpan(
        text: '${points[i].toStringAsFixed(1)}kg',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(pt.dx - (textPainter.width / 2), pt.dy - 18));
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLineChartPainter oldDelegate) => true;
}
