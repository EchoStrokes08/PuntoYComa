import 'package:flutter/material.dart';

/// Animación de pulso para el radar del viaje armado.
///
/// El círculo del radar se expande y contrae suavemente en bucle,
/// transmitiendo que la alarma está activamente monitoreando la ruta.
class RadarPulse extends StatefulWidget {
  const RadarPulse({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.08,
    this.duration = const Duration(seconds: 2),
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
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

/// Animación de parpadeo para estados de alarma crítica.
///
/// Usada en la pantalla de alarma sonora para llamar la atención del usuario.
class AlarmBlink extends StatefulWidget {
  const AlarmBlink({super.key, required this.child});

  final Widget child;

  @override
  State<AlarmBlink> createState() => _AlarmBlinkState();
}

class _AlarmBlinkState extends State<AlarmBlink>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6 + (0.4 * _controller.value),
      child: widget.child,
    );
  }
}

/// Animación de revelado escalonado para listas de tarjetas.
///
/// Cada elemento aparece con un ligero retraso, creando un efecto de
/// revelado orgánico y premium.
///
/// Nota: es un `Column`; no debe recibir hijos con flex (`Spacer`,
/// `Expanded`) si su altura no está acotada por el padre.
class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 600),
    this.stagger = const Duration(milliseconds: 80),
  });

  final List<Widget> children;
  final Duration duration;
  final Duration stagger;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(widget.children.length, (index) {
        final delay = widget.stagger * index;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = (_controller.value -
                    delay.inMilliseconds / widget.duration.inMilliseconds)
                .clamp(0.0, 1.0);
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      }),
    );
  }
}
