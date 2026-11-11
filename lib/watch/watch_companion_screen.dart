import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/watch_sync_service.dart';
import '../models/workout.dart';
import 'screens/watch_home_screen.dart';

/// Simulador Interativo do Smartwatch no Celular
/// Permite visualizar e testar o funcionamento exato do app de relógio
/// em formatos circular (Galaxy Watch / Wear OS) ou retangular (Apple Watch),
/// com sincronização reativa em tempo real com os treinos do celular.
class WatchCompanionScreen extends StatefulWidget {
  const WatchCompanionScreen({super.key});

  @override
  State<WatchCompanionScreen> createState() => _WatchCompanionScreenState();
}

class _WatchCompanionScreenState extends State<WatchCompanionScreen> {
  bool _isCircular = true; // true: Galaxy/Pixel Watch, false: Apple Watch

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070606),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.watch_rounded, color: AppColors.primaryOrange, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Port Smartwatch (Wearable)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner de Status de Sincronização em Tempo Real
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF00E676),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ValueListenableBuilder<List<Workout>>(
                      valueListenable: WatchSyncService.instance.workoutsNotifier,
                      builder: (context, workouts, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sincronização Ativa em Tempo Real',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${workouts.length} treinos espelhados instantaneamente.',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Seletor de Formato do Relógio (Circular / Apple Watch)
                  Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isCircular = true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isCircular ? AppColors.primaryOrange : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isCircular ? AppColors.primaryOrange : AppColors.cardBorder,
                            ),
                          ),
                          child: Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: _isCircular ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() => _isCircular = false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: !_isCircular ? AppColors.primaryOrange : AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !_isCircular ? AppColors.primaryOrange : AppColors.cardBorder,
                            ),
                          ),
                          child: Icon(
                            Icons.crop_square_rounded,
                            size: 16,
                            color: !_isCircular ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Carcaça física do Smartwatch (Moldura Bezel e Tela OLED)
            Expanded(
              child: Center(
                child: Container(
                  width: _isCircular ? 330 : 290,
                  height: _isCircular ? 330 : 340,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151414),
                    borderRadius: BorderRadius.circular(_isCircular ? 165 : 44),
                    border: Border.all(
                      color: const Color(0xFF383333),
                      width: 9,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.9),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_isCircular ? 160 : 36),
                    child: WatchHomeScreen(
                      key: ValueKey(_isCircular),
                      isCircular: _isCircular,
                    ),
                  ),
                ),
              ),
            ),

            // Rodapé explicativo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                _isCircular
                    ? '⌚ Modo Wear OS (Galaxy Watch 4/5/6, Pixel Watch) • Resolução 390x390 circular'
                    : '⌚ Modo watchOS (Apple Watch Series 7/8/9/Ultra) • Resolução compacta OLED',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
