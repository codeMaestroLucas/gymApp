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
    return Container(
      color: Colors.black,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double size = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            // Para relógios circulares (Wear OS / Galaxy Watch / Pixel Watch),
            // calculamos margens de segurança baseadas no diâmetro da viewport para garantir
            // que nenhum elemento seja cortado pelos arcos e evitando overflow em relógios compactos (192dp).
            final double hPad = isCircular
                ? (size * 0.06).clamp(10.0, 26.0)
                : (size * 0.03).clamp(6.0, 14.0);
            final double vPad = isCircular
                ? (size * 0.08).clamp(12.0, 32.0)
                : (size * 0.04).clamp(8.0, 16.0);

            return ClipRRect(
              borderRadius: BorderRadius.circular(isCircular ? (size / 2) : 36),
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
            );
          },
        ),
      ),
    );
  }
}
