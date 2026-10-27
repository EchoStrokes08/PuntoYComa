import 'package:flutter/material.dart';

/// Animación de "respiración": escala suave entre [minScale] y [maxScale],
/// 4 s por ciclo, curva easeInOut, repetida en reversa.
///
/// Transmite calma y vigilancia silenciosa (héroe de la pantalla de inicio).
class BreathingScale extends StatefulWidget {
  const BreathingScale({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.04,
    this.duration = const Duration(seconds: 4),
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<BreathingScale> createState() => _BreathingScaleState();
}

class _BreathingScaleState extends State<BreathingScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _scale = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
