import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';

/// Visualizador em formato GIF para reprodução dos vídeos de execução dos exercícios.
/// Executa automaticamente em loop com velocidade de 1.25x, sem controles de play/pause
/// ou scrubber, funcionando exatamente como uma animação contínua (GIF).
class ExerciseVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String? thumbnailPath;
  final bool autoPlay;
  final bool looping;
  final double playbackSpeed;
  final double height;

  const ExerciseVideoPlayer({
    super.key,
    required this.videoPath,
    this.thumbnailPath,
    this.autoPlay = true,
    this.looping = true,
    this.playbackSpeed = 1.25,
    this.height = 220,
  });

  @override
  State<ExerciseVideoPlayer> createState() => _ExerciseVideoPlayerState();
}

class _ExerciseVideoPlayerState extends State<ExerciseVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath) {
      _disposePlayer();
      _initializePlayer();
    }
  }

  void _disposePlayer() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _hasError = false;
  }

  void _initializePlayer() {
    // Em testes de widget ou ambientes sem codec nativo mockado, exibe a foto limpa
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    try {
      _controller = VideoPlayerController.asset(widget.videoPath)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isInitialized = true;
          });
          if (widget.looping) {
            _controller?.setLooping(true);
          }
          _controller?.setPlaybackSpeed(widget.playbackSpeed);
          if (widget.autoPlay) {
            _controller?.play();
          }
        }).catchError((_) {
          if (!mounted) return;
          setState(() {
            _hasError = true;
          });
        });

      _controller?.addListener(_onControllerUpdate);
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0B0B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: (_hasError || _controller == null)
            ? _buildErrorOrThumbnailFallback()
            : (!_isInitialized)
                ? _buildLoadingState()
                : _buildVideoSurface(),
      ),
    );
  }

  Widget _buildVideoSurface() {
    final controller = _controller!;
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : (16 / 9),
      child: VideoPlayer(controller),
    );
  }

  Widget _buildLoadingState() {
    if (widget.thumbnailPath != null) {
      return Image.asset(
        widget.thumbnailPath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox(),
      );
    }
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
        ),
      ),
    );
  }

  Widget _buildErrorOrThumbnailFallback() {
    if (widget.thumbnailPath != null) {
      return Image.asset(
        widget.thumbnailPath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.fitness_center_rounded, color: AppColors.primaryOrange, size: 40),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.fitness_center_rounded, color: AppColors.primaryOrange, size: 40),
    );
  }
}
