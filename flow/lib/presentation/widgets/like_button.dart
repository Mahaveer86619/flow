import 'package:flutter/material.dart';

class LikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const LikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 28,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(_curve);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 30),
    ]).animate(_curve);
  }

  @override
  void didUpdateWidget(LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? const Color(0xFFEC4899);
    final inactiveColor = widget.inactiveColor ?? Colors.white.withAlpha(140);

    return GestureDetector(
      onTap: widget.onTap,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            widget.isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: widget.size,
            color: widget.isLiked ? activeColor : inactiveColor,
          ),
        ),
      ),
    );
  }
}
