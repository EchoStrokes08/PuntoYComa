import 'package:flutter/material.dart';

import '../../design/tokens/tokens.dart';

/// Avatar circular premium con borde y sombra sutil.
class PuntoAvatar extends StatelessWidget {
  const PuntoAvatar({
    super.key,
    required this.child,
    this.radius = 28,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  final Widget child;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? scheme.surfaceContainer,
        border: Border.all(
          color: borderColor ?? scheme.primary,
          width: borderWidth,
        ),
        boxShadow: PuntoEffects.soft,
      ),
      child: ClipOval(
        child: Center(child: child),
      ),
    );
  }
}

/// Avatar con iniciales de texto.
class PuntoTextAvatar extends StatelessWidget {
  const PuntoTextAvatar({
    super.key,
    required this.text,
    this.radius = 28,
    this.backgroundColor,
    this.textStyle,
  });

  final String text;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PuntoAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? scheme.primaryContainer,
      child: Text(
        text.isEmpty ? '?' : text.substring(0, 1).toUpperCase(),
        style: textStyle ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onPrimary,
            ),
      ),
    );
  }
}
