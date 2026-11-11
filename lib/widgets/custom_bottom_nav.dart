import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Barra de navegação inferior customizada exatamente conforme o design solicitado:
/// - Aba Início: Ícone de Halter horizontal moderno em destaque laranja
/// - Aba Evolução: Ícone de gráfico de barras com linha ascendente de tendência
/// - Aba Perfil: Ícone de perfil / usuário
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              label: 'Início',
              iconBuilder: (color) => DumbbellNavIcon(color: color, size: 26),
            ),
            _buildNavItem(
              index: 1,
              label: 'Evolução',
              iconBuilder: (color) => EvolutionNavIcon(color: color, size: 24),
            ),
            _buildNavItem(
              index: 2,
              label: 'Perfil',
              iconBuilder: (color) => ProfileNavIcon(color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required Widget Function(Color color) iconBuilder,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primaryOrange : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => onIndexChanged(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconBuilder(color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone de Halter horizontal moderno conforme o design da imagem
class DumbbellNavIcon extends StatelessWidget {
  final Color color;
  final double size;

  const DumbbellNavIcon({
    super.key,
    required this.color,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.3,
      height: size,
      child: CustomPaint(
        painter: _DumbbellIconPainter(color: color),
      ),
    );
  }
}

class _DumbbellIconPainter extends CustomPainter {
  final Color color;

  _DumbbellIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    // Anilha esquerda externa (retângulo arredondado alto)
    final leftOuterRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.12, midY), width: w * 0.11, height: h * 0.72),
      const Radius.circular(3),
    );
    canvas.drawRRect(leftOuterRect, strokePaint);

    // Anilha esquerda interna (menor)
    final leftInnerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.25, midY), width: w * 0.09, height: h * 0.50),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(leftInnerRect, strokePaint);

    // Barra central horizontal com pegador
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.29, midY),
      Offset(w * 0.71, midY),
      barPaint,
    );

    // Detalhe de recartilhado / pegada no centro da barra
    canvas.drawCircle(Offset(w * 0.5, midY), 1.6, fillPaint);

    // Anilha direita interna (menor)
    final rightInnerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.75, midY), width: w * 0.09, height: h * 0.50),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(rightInnerRect, strokePaint);

    // Anilha direita externa (retângulo arredondado alto)
    final rightOuterRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.88, midY), width: w * 0.11, height: h * 0.72),
      const Radius.circular(3),
    );
    canvas.drawRRect(rightOuterRect, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DumbbellIconPainter oldDelegate) => oldDelegate.color != color;
}

/// Ícone de Evolução com barras e linha ascendente conforme o design da imagem
class EvolutionNavIcon extends StatelessWidget {
  final Color color;
  final double size;

  const EvolutionNavIcon({
    super.key,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EvolutionIconPainter(color: color),
      ),
    );
  }
}

class _EvolutionIconPainter extends CustomPainter {
  final Color color;

  _EvolutionIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // 3 Barras verticais crescentes
    final barWidth = w * 0.17;
    final radius = Radius.circular(barWidth / 2);

    // Barra 1 (baixa)
    final b1Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.55, barWidth, h * 0.40),
      radius,
    );
    canvas.drawRRect(b1Rect, fillPaint);

    // Barra 2 (média)
    final b2Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.41, h * 0.35, barWidth, h * 0.60),
      radius,
    );
    canvas.drawRRect(b2Rect, fillPaint);

    // Barra 3 (alta)
    final b3Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.74, h * 0.15, barWidth, h * 0.80),
      radius,
    );
    canvas.drawRRect(b3Rect, fillPaint);

    // Linha ascendente que corta os picos com seta
    final path = Path();
    path.moveTo(w * 0.06, h * 0.48);
    path.lineTo(w * 0.35, h * 0.28);
    path.lineTo(w * 0.60, h * 0.36);
    path.lineTo(w * 0.94, h * 0.06);

    canvas.drawPath(path, strokePaint);

    // Ponta de flecha ou ponto terminal
    canvas.drawCircle(Offset(w * 0.94, h * 0.06), 2.2, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _EvolutionIconPainter oldDelegate) => oldDelegate.color != color;
}

/// Ícone de Perfil outline moderno
class ProfileNavIcon extends StatelessWidget {
  final Color color;
  final double size;

  const ProfileNavIcon({
    super.key,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProfileIconPainter(color: color),
      ),
    );
  }
}

class _ProfileIconPainter extends CustomPainter {
  final Color color;

  _ProfileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Cabeça circular
    final headRadius = w * 0.22;
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.30),
      headRadius,
      strokePaint,
    );

    // Ombros e corpo curvado
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.15, h * 0.92);
    bodyPath.quadraticBezierTo(
      w * 0.18,
      h * 0.62,
      w * 0.50,
      h * 0.62,
    );
    bodyPath.quadraticBezierTo(
      w * 0.82,
      h * 0.62,
      w * 0.85,
      h * 0.92,
    );

    canvas.drawPath(bodyPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ProfileIconPainter oldDelegate) => oldDelegate.color != color;
}
