import 'dart:math' as math;
import 'package:flutter/material.dart';

class SquigglyProgressBar extends StatefulWidget {
  final double progress;
  final double bufferProgress;
  final bool isInitialLoading;
  final bool isBuffering;
  final ValueChanged<double>? onSeek;
  final double height;
  final double amplitude;
  final double strokeWidth;
  final double waveCount;

  const SquigglyProgressBar({
    super.key,
    required this.progress,
    this.bufferProgress = 0.0,
    this.isInitialLoading = false,
    this.isBuffering = false,
    this.onSeek,
    this.height = 18.0,
    this.amplitude = 0.2,
    this.strokeWidth = 2.5,
    this.waveCount = 5.0,
  });

  @override
  State<SquigglyProgressBar> createState() => _SquigglyProgressBarState();
}

class _SquigglyProgressBarState extends State<SquigglyProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _phaseController;
  late final AnimationController _loadingController;
  late final AnimationController _transitionController;

  bool get _isLoading => widget.isInitialLoading || widget.isBuffering;

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
      value: _isLoading ? 1.0 : 0.0,
    );

    if (_isLoading) {
      _loadingController.repeat();
    }
  }

  @override
  void didUpdateWidget(SquigglyProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasLoading = oldWidget.isInitialLoading || oldWidget.isBuffering;
    final isNowLoading = widget.isInitialLoading || widget.isBuffering;

    if (isNowLoading != wasLoading) {
      if (isNowLoading) {
        _loadingController.repeat();
        _transitionController.forward();
      } else {
        _transitionController.reverse().then((_) {
          if (mounted && !widget.isInitialLoading && !widget.isBuffering) {
            _loadingController.stop();
            _loadingController.reset();
          }
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

  void _handleSeek(Offset localPosition) {
    if (_isLoading) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final width = renderBox.size.width;
    final fraction = (localPosition.dx / width).clamp(0.0, 1.0);
    widget.onSeek?.call(fraction);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _handleSeek(d.localPosition),
      onHorizontalDragUpdate: (d) => _handleSeek(d.localPosition),
      onHorizontalDragStart: (d) => _handleSeek(d.localPosition),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _phaseController,
            _loadingController,
            _transitionController,
          ]),
          builder: (context, _) {
            return SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CustomPaint(
                painter: _SquigglyPainter(
                  progress: widget.progress,
                  bufferProgress: widget.bufferProgress,
                  isInitialLoading: widget.isInitialLoading,
                  isBuffering: widget.isBuffering,
                  loadingValue: _loadingController.value,
                  transitionValue: _transitionController.value,
                  phase: _phaseController.value * 2 * math.pi,
                  playedColor: colorScheme.primary,
                  bufferedColor: const Color(0xFF808080),
                  unplayedColor: colorScheme.surfaceContainerHighest,
                  amplitude: widget.amplitude,
                  strokeWidth: widget.strokeWidth,
                  waveCount: widget.waveCount,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SquigglyPainter extends CustomPainter {
  final double progress;
  final double bufferProgress;
  final bool isInitialLoading;
  final bool isBuffering;
  final double loadingValue;
  final double transitionValue;
  final double phase;
  final Color playedColor;
  final Color bufferedColor;
  final Color unplayedColor;
  final double amplitude;
  final double strokeWidth;
  final double waveCount;

  const _SquigglyPainter({
    required this.progress,
    required this.bufferProgress,
    required this.isInitialLoading,
    required this.isBuffering,
    required this.loadingValue,
    required this.transitionValue,
    required this.phase,
    required this.playedColor,
    required this.bufferedColor,
    required this.unplayedColor,
    required this.amplitude,
    required this.strokeWidth,
    required this.waveCount,
  });

  Path _buildPath(
    Size size, {
    double startX = 0,
    double endX = 1.0,
    double? customPhase,
  }) {
    final actualAmplitude = size.height * amplitude;
    final midY = size.height / 2;
    final angularFreq = (2 * math.pi * waveCount) / size.width;
    final p = customPhase ?? phase;

    final path = Path();
    final actualStartX = size.width * startX;
    final actualEndX = size.width * endX;

    path.moveTo(
      actualStartX,
      midY + actualAmplitude * math.sin(angularFreq * actualStartX + p),
    );
    for (double x = actualStartX + 1; x <= actualEndX; x += 1.5) {
      final y = midY + actualAmplitude * math.sin(angularFreq * x + p);
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final progressX = size.width * progress;
    final bufferX = size.width * bufferProgress;

    // 1. Base Unplayed Path (Constant)
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _buildPath(size);

    // Draw the full background track (unplayed)
    canvas.drawPath(
      path,
      basePaint
        ..color = unplayedColor.withValues(alpha: 1.0)
        ..strokeWidth = strokeWidth,
    );

    // 2. Loading Animation (Sliding overlay)
    if (transitionValue > 0) {
      final segmentWidth = size.width * 0.4;
      final start = (loadingValue * (size.width + segmentWidth)) - segmentWidth;

      final paint = Paint()
        ..color = playedColor.withValues(alpha: transitionValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.5
        ..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            start.clamp(-segmentWidth, size.width),
            0,
            segmentWidth,
            size.height,
          ),
          const Radius.circular(8),
        ),
      );

      // Draw the SAME path but with the played color/width
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    // 3. Played & Buffered portions (only when NOT fully initial loading)
    if (transitionValue < 1.0) {
      final normalOpacity = 1.0 - transitionValue;

      // Buffered portion
      if (bufferProgress > progress) {
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(progressX, 0, bufferX - progressX, size.height),
            const Radius.circular(8),
          ),
        );
        canvas.drawPath(
          path,
          basePaint
            ..color = bufferedColor.withValues(alpha: normalOpacity)
            ..strokeWidth = strokeWidth * 1.2,
        );
        canvas.restore();
      }

      // Played portion
      if (progress > 0) {
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-10, 0, progressX + 10, size.height),
            const Radius.circular(8),
          ),
        );
        canvas.drawPath(
          path,
          basePaint
            ..color = playedColor.withValues(alpha: normalOpacity)
            ..strokeWidth = strokeWidth * 1.8,
        );
        canvas.restore();

        // 4. Playhead Dot
        final actualAmplitude = size.height * amplitude;
        final midY = size.height / 2;
        final angularFreq = (2 * math.pi * waveCount) / size.width;
        final dotY =
            midY + actualAmplitude * math.sin(angularFreq * progressX + phase);

        canvas.drawCircle(
          Offset(progressX, dotY),
          size.height * 0.4,
          Paint()
            ..color = playedColor.withAlpha((60 * normalOpacity).toInt())
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(
          Offset(progressX, dotY),
          size.height * 0.2,
          Paint()..color = playedColor.withValues(alpha: normalOpacity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SquigglyPainter old) =>
      old.progress != progress ||
      old.bufferProgress != bufferProgress ||
      old.isInitialLoading != isInitialLoading ||
      old.isBuffering != isBuffering ||
      old.loadingValue != loadingValue ||
      old.transitionValue != transitionValue ||
      old.phase != phase ||
      old.amplitude != amplitude ||
      old.strokeWidth != strokeWidth ||
      old.waveCount != waveCount;
}



