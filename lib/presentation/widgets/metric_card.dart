import 'package:flutter/material.dart';

/// Tarjeta de métrica accesible con icono, valor y etiqueta.
///
/// Se usa para mostrar ETA, distancia restante y otros indicadores del viaje.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.valueStyle,
    this.labelColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final TextStyle? valueStyle;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(value, style: valueStyle ?? Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: labelColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
