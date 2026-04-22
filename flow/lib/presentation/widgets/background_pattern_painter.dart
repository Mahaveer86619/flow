import 'package:flutter/material.dart';

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 40.0;

    // Draw subtle flowing lines
    for (double i = -spacing; i < size.width + spacing; i += spacing) {
      final path = Path();
      path.moveTo(i, 0);
      path.quadraticBezierTo(
        i + spacing * 2,
        size.height * 0.5,
        i - spacing,
        size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
