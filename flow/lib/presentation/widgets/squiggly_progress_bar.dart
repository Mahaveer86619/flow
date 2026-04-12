import 'dart:math' as math;
import 'package:flutter/material.dart';

class SquigglyProgressBar extends StatefulWidget {
  final double progress;
  final double bufferProgress;
  final bool isInitialLoading;
  final ValueChanged<double>? onSeek;

  const SquigglyProgressBar({
    super.key,
    required this.progress,
    this.bufferProgress = 0.0,
    this.isInitialLoading = false,
    this.onSeek,
  });

  @override
  State<SquigglyProgressBar> createState() => _SquigglyProgressBarState();
}

class _SquigglyProgressBarState extends State<SquigglyProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _phaseController;
  late final AnimationController _loadingController;
  late final AnimationController _transitionController;

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.isInitialLoading ? 1.0 : 0.0,
    );

    if (widget.isInitialLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(SquigglyProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInitialLoading != oldWidget.isInitialLoading) {
      if (widget.isInitialLoading) {
        _loadingController.repeat();
        _transitionController.forward();
      } else {
        _transitionController.reverse().then((_) {
          _loadingController.stop();
          _loadingController.reset();
        });
      }
    }
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _loadingController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  void _handleSeek(Offset localPosition, BoxConstraints constraints) {
    if (widget.isInitialLoading) return;
    final fraction = (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    widget.onSeek?.call(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (d) => _handleSeek(d.localPosition, constraints),
          onHorizontalDragUpdate: (d) =>
              _handleSeek(d.localPosition, constraints),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _phaseController,
                _loadingController,
                _transitionController,
              ]),
              builder: (context, _) {
                return SizedBox(
                  height: 18,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SquigglyPainter(
                      progress: widget.progress,
                      bufferProgress: widget.bufferProgress,
                      isInitialLoading: widget.isInitialLoading,
                      loadingValue: _loadingController.value,
                      transitionValue: _transitionController.value,
                      phase: _phaseController.value * 2 * math.pi,
                      playedColor: colorScheme.primary,
                      bufferedColor: const Color(0xFF808080),
                      unplayedColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SquigglyPainter extends CustomPainter {
  final double progress;
  final double bufferProgress;
  final bool isInitialLoading;
  final double loadingValue;
  final double transitionValue;
  final double phase;
  final Color playedColor;
  final Color bufferedColor;
  final Color unplayedColor;

  const _SquigglyPainter({
    required this.progress,
    required this.bufferProgress,
    required this.isInitialLoading,
    required this.loadingValue,
    required this.transitionValue,
    required this.phase,
    required this.playedColor,
    required this.bufferedColor,
    required this.unplayedColor,
  });

  Path _buildPath(
    Size size, {
    double startX = 0,
    double endX = 1.0,
    double? customPhase,
  }) {
    const waveCount = 5.0;
    final amplitude = size.height * 0.18;
    final midY = size.height / 2;
    final angularFreq = (2 * math.pi * waveCount) / size.width;
    final p = customPhase ?? phase;

    final path = Path();
    final actualStartX = size.width * startX;
    final actualEndX = size.width * endX;

    path.moveTo(
      actualStartX,
      midY + amplitude * math.sin(angularFreq * actualStartX + p),
    );
    for (double x = actualStartX + 1; x <= actualEndX; x += 1.5) {
      final y = midY + amplitude * math.sin(angularFreq * x + p);
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = _buildPath(size);
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (transitionValue > 0) {
      // Draw loading state (M3 style sliding segment)
      final paint = Paint()
        ..color = unplayedColor.withOpacity(transitionValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(fullPath, paint);

      final segmentWidth = size.width * 0.3;
      final start = (loadingValue * (size.width + segmentWidth)) - segmentWidth;

      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(start.clamp(0, size.width), 0, segmentWidth, size.height),
      );
      canvas.drawPath(
        fullPath,
        paint
          ..color = playedColor.withOpacity(transitionValue)
          ..strokeWidth = 3.5,
      );
      canvas.restore();
    }

    if (transitionValue < 1.0) {
      // Draw normal state with inverse opacity
      final opacity = 1.0 - transitionValue;
      final progressX = size.width * progress;
      final bufferX = size.width * bufferProgress;

      // 1. Unplayed
      canvas.drawPath(
        fullPath,
        basePaint
          ..color = unplayedColor.withOpacity(opacity)
          ..strokeWidth = 2.5,
      );

      // 2. Buffered portion
      if (bufferProgress > progress) {
        canvas.save();
        canvas.clipRect(
          Rect.fromLTWH(progressX, 0, bufferX - progressX, size.height),
        );
        canvas.drawPath(
          fullPath,
          basePaint
            ..color = bufferedColor.withOpacity(opacity)
            ..strokeWidth = 3.0,
        );
        canvas.restore();
      }

      // 3. Played portion
      if (progress > 0) {
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, 0, progressX, size.height));
        canvas.drawPath(
          fullPath,
          basePaint
            ..color = playedColor.withOpacity(opacity)
            ..strokeWidth = 3.5,
        );
        canvas.restore();

        const waveCount = 5.0;
        final amplitude = size.height * 0.28;
        final midY = size.height / 2;
        final angularFreq = (2 * math.pi * waveCount) / size.width;
        final dotY =
            midY + amplitude * math.sin(angularFreq * progressX + phase);

        canvas.drawCircle(
          Offset(progressX, dotY),
          8,
          Paint()
            ..color = playedColor.withAlpha((60 * opacity).toInt())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          Offset(progressX, dotY),
          4,
          Paint()..color = playedColor.withOpacity(opacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SquigglyPainter old) =>
      old.progress != progress ||
      old.bufferProgress != bufferProgress ||
      old.isInitialLoading != isInitialLoading ||
      old.loadingValue != loadingValue ||
      old.transitionValue != transitionValue ||
      old.phase != phase;
}
