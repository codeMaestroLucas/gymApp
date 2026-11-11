import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RestTimerSheet extends StatefulWidget {
  final int initialSeconds;
  final String exerciseName;

  const RestTimerSheet({
    super.key,
    required this.initialSeconds,
    required this.exerciseName,
  });

  static Future<void> show(BuildContext context,
      {required int initialSeconds, required String exerciseName}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RestTimerSheet(
        initialSeconds: initialSeconds,
        exerciseName: exerciseName,
      ),
    );
  }

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet> {
  late int _secondsLeft;
  late int _totalDuration;
  Timer? _timer;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.initialSeconds > 0 ? widget.initialSeconds : 60;
    _secondsLeft = _totalDuration;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _addTime(int seconds) {
    setState(() {
      _secondsLeft = (_secondsLeft + seconds).clamp(0, 600);
      _totalDuration = (_totalDuration + seconds).clamp(1, 600);
    });
  }

  void _resetTimer() {
    setState(() {
      _secondsLeft = widget.initialSeconds;
      _totalDuration = widget.initialSeconds;
      _isRunning = true;
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration > 0 ? _secondsLeft / _totalDuration : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de arraste
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'DESCANSO ENTRE SÉRIES',
            style: TextStyle(
              color: AppColors.primaryOrange.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.exerciseName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Anel de contagem regressiva
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppColors.backgroundDark,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _secondsLeft <= 5
                        ? AppColors.accentRed
                        : (_secondsLeft <= 15
                            ? AppColors.accentYellow
                            : AppColors.primaryOrange),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_secondsLeft),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _secondsLeft == 0 ? 'PRÓXIMA SÉRIE!' : 'restantes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _secondsLeft == 0
                          ? AppColors.accentGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 26),

          // Botões de ajuste rápido (+15s / -15s)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => _addTime(-15),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('-15s',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => _addTime(15),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('+15s',
                    style: TextStyle(color: AppColors.primaryOrange)),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                tooltip: 'Reiniciar',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botão principal Pausar / Continuar / Concluir
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _secondsLeft == 0
                  ? () => Navigator.pop(context)
                  : _togglePause,
              icon: Icon(
                _secondsLeft == 0
                    ? Icons.check_circle_outline_rounded
                    : (_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                size: 22,
              ),
              label: Text(
                _secondsLeft == 0
                    ? 'Ir para Próximo Exercício'
                    : (_isRunning ? 'Pausar Descanso' : 'Continuar'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondsLeft == 0
                    ? AppColors.accentGreen
                    : (_isRunning ? AppColors.accentYellow : AppColors.primaryOrange),
                foregroundColor: _isRunning && _secondsLeft > 0 ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
