import 'dart:math' as math;
import 'package:flutter/material.dart';

class SquigglyProgressBar extends StatefulWidget {
  final double progress;
  final ValueChanged<double>? onSeek;

  const SquigglyProgressBar({
    super.key,
    required this.progress,
    this.onSeek,
  });

  @override
  State<SquigglyProgressBar> createState() => _SquigglyProgressBarState();
}

class _SquigglyProgressBarState extends State<SquigglyProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phaseController;

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _phaseController.dispose();
    super.dispose();
  }

  void _handleSeek(Offset localPosition, BoxConstraints constraints) {
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
          child: AnimatedBuilder(
            animation: _phaseController,
            builder: (context, _) {
              return SizedBox(
                height: 18,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SquigglyPainter(
                    progress: widget.progress,
                    phase: _phaseController.value * 2 * math.pi,
                    playedColor: colorScheme.primary,
                    unplayedColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SquigglyPainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color playedColor;
  final Color unplayedColor;

  const _SquigglyPainter({
    required this.progress,
    required this.phase,
    required this.playedColor,
    required this.unplayedColor,
  });

  Path _buildPath(Size size) {
    const waveCount = 5.0;
    final amplitude = size.height * 0.18;
    final midY = size.height / 2;
    final angularFreq = (2 * math.pi * waveCount) / size.width;

    final path = Path();
    path.moveTo(0, midY + amplitude * math.sin(phase));
    for (double x = 1; x <= size.width; x += 1.5) {
      final y = midY + amplitude * math.sin(angularFreq * x + phase);
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    final progressX = size.width * progress;

    final unplayedPaint = Paint()
      ..color = unplayedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final playedPaint = Paint()
      ..color = playedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Unplayed portion
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(progressX, 0, size.width - progressX, size.height),
    );
    canvas.drawPath(path, unplayedPaint);
    canvas.restore();

    // Played portion
    if (progress > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, progressX, size.height));
      canvas.drawPath(path, playedPaint);
      canvas.restore();

      // Compute dot position on the wave
      const waveCount = 5.0;
      final amplitude = size.height * 0.28;
      final midY = size.height / 2;
      final angularFreq = (2 * math.pi * waveCount) / size.width;
      final dotY =
          midY + amplitude * math.sin(angularFreq * progressX + phase);

      // Glow
      canvas.drawCircle(
        Offset(progressX, dotY),
        8,
        Paint()
          ..color = playedColor.withAlpha(60)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Outer dot
      canvas.drawCircle(
        Offset(progressX, dotY),
        4,
        Paint()..color = playedColor,
      );
      // Inner white dot
      canvas.drawCircle(
        Offset(progressX, dotY),
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_SquigglyPainter old) =>
      old.progress != progress || old.phase != phase;
}
