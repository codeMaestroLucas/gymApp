import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Container adaptativo para relógios inteligentes (Smartwatches)
/// Suporta tanto telas circulares (Galaxy Watch / Pixel Watch / Wear OS)
/// quanto telas retangulares com cantos arredondados (Apple Watch).
class WatchScreenContainer extends StatelessWidget {
  final Widget child;
  final bool isCircular;
  final Color backgroundColor;

  const WatchScreenContainer({
    super.key,
    required this.child,
    this.isCircular = true,
    this.backgroundColor = AppColors.backgroundDark,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.shortestSide < 250;

    // Em relógios reais (160-220dp lógicos), o padding deve ser compacto
    // para evitar perda de área útil e cortes de texto
    final hPad = isCircular ? (isCompact ? 10.0 : 20.0) : (isCompact ? 6.0 : 12.0);
    final vPad = isCircular ? (isCompact ? 12.0 : 24.0) : (isCompact ? 8.0 : 14.0);

    return Container(
      color: Colors.black,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCircular ? 200 : 36),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hPad,
                vertical: vPad,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
