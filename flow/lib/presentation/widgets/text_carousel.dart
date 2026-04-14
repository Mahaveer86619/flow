import 'dart:async';
import 'package:flutter/material.dart';

class TextCarousel extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double velocity;
  final Duration pauseDuration;
  final double gap;

  const TextCarousel({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection = TextDirection.ltr,
    this.velocity = 30.0, // pixels per second
    this.pauseDuration = const Duration(seconds: 2),
    this.gap = 40.0,
  });

  @override
  State<TextCarousel> createState() => _TextCarouselState();
}

class _TextCarouselState extends State<TextCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _running = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(TextCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _resetScrolling();
    }
  }

  @override
  void dispose() {
    _running = false;
    _scrollController.dispose();
    super.dispose();
  }

  void _resetScrolling() {
    _running = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _startScrolling() async {
    if (_running || !mounted) return;
    _running = true;

    while (_running && mounted) {
      if (!_scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      await Future.delayed(widget.pauseDuration);
      if (!_running || !mounted || !_scrollController.hasClients) break;

      final textWidth = _calculateTextWidth();
      final distance = textWidth + widget.gap;

      if (_scrollController.position.maxScrollExtent < distance) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final duration = Duration(
        milliseconds: (distance / widget.velocity * 1000).toInt(),
      );

      await _scrollController.animateTo(
        distance,
        duration: duration,
        curve: Curves.linear,
      );

      if (!_running || !mounted || !_scrollController.hasClients) break;
      _scrollController.jumpTo(0);
    }
  }

  double _calculateTextWidth() {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: widget.textDirection,
    )..layout();
    return textPainter.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textWidth = _calculateTextWidth();

        if (textWidth <= constraints.maxWidth) {
          _running = false;
          return Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
            textDirection: widget.textDirection,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
          );
        }

        if (!_running) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
        }

        final widgetText = Text(
          widget.text,
          style: widget.style,
          textAlign: widget.textAlign,
          textDirection: widget.textDirection,
          maxLines: 1,
          softWrap: false,
        );

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withOpacity(0),
                Colors.black,
                Colors.black,
                Colors.black.withOpacity(0),
              ],
              stops: const [0.0, 0.05, 0.95, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                widgetText,
                SizedBox(width: widget.gap),
                widgetText,
                SizedBox(width: widget.gap),
              ],
            ),
          ),
        );
      },
    );
  }
}
