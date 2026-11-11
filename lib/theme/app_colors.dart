import 'package:flutter/material.dart';

/// Paleta de cores extraída das telas de acompanhamento de treino e atividades.
class AppColors {
  AppColors._();

  // Cores de Fundo e Superfície
  static const Color backgroundDark = Color(0xFF0B0A0A);
  static const Color cardBackground = Color(0xFF1E1A1A);
  static const Color cardBorder = Color(0xFF2C2424);

  // Cores de Destaque e Interação
  static const Color primaryOrange = Color(0xFFFF6B00);
  static const Color accentYellow = Color(0xFFFFD000);
  static const Color accentRed = Color(0xFFFF3B30);

  // Cores de Texto e Ícones
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA39B98);

  // Cores adicionais funcionais e de feedback
  static const Color accentGreen = Color(0xFF34C759);
  static const Color cardLight = Color(0xFF272222);

  // Gradientes úteis para efeitos de fundo ou botões
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B00), Color(0xFFFF8C38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF221D1D), Color(0xFF171313)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
