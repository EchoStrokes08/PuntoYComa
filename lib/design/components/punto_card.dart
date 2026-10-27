import 'package:flutter/material.dart';

import '../../design/tokens/tokens.dart';

/// Tarjeta premium de PuntoYcoma con sombra suave y bordes redondeados.
///
/// Usa el sistema de diseño para colores, radios y sombras consistentes.
class PuntoCard extends StatelessWidget {
  const PuntoCard({
    super.key,
    required this.child,
    this.color,
    this.borderRadius = PuntoBorders.md,
    this.elevation = PuntoEffects.card,
    this.border,
    this.padding,
    this.margin,
  });

  final Widget child;
  final Color? color;
  final double borderRadius;
  final List<BoxShadow>? elevation;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: elevation,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(PuntoSpacing.md),
        child: child,
      ),
    );
  }
}

/// Tarjeta de métrica premium con icono, valor y etiqueta.
class PuntoMetricCard extends StatelessWidget {
  const PuntoMetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.valueStyle,
    this.labelColor,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final TextStyle? valueStyle;
  final Color? labelColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PuntoCard(
      color: color ?? scheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(PuntoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 28,
            color: color ?? scheme.primary,
          ),
          const SizedBox(height: PuntoSpacing.sm),
          Text(
            value,
            style: valueStyle ?? Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: PuntoSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: labelColor ?? scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
