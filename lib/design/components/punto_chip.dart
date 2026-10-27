import 'package:flutter/material.dart';

import '../../design/tokens/tokens.dart';

/// Chip de estado premium para PuntoYcoma.
///
/// Usado para estados de señal, batería, modo de transporte, etc.
class PuntoChip extends StatelessWidget {
  const PuntoChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.textColor,
    this.borderRadius = PuntoBorders.circle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chipColor = color ?? scheme.surfaceContainerHighest;
    final chipTextColor = textColor ?? scheme.onSurfaceVariant;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: chipTextColor,
            ),
            const SizedBox(width: PuntoSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: chipTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de estado de señal (buena, degradada, limitada).
class PuntoSignalChip extends StatelessWidget {
  const PuntoSignalChip({
    super.key,
    required this.signal,
  });

  final String signal; // 'good', 'degraded', 'limited'

  @override
  Widget build(BuildContext context) {
    final data = _signalData(signal);
    return PuntoChip(
      label: _signalLabel(signal),
      icon: _signalIcon(signal),
      color: data['color'],
      textColor: data['textColor'],
      borderRadius: PuntoBorders.sm,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Map<String, Color?> _signalData(String signal) {
    switch (signal) {
      case 'good':
        return {
          'color': PuntoColors.signalGood.withValues(alpha: 0.15),
          'textColor': PuntoColors.signalGood,
        };
      case 'degraded':
        return {
          'color': PuntoColors.signalDegraded.withValues(alpha: 0.15),
          'textColor': PuntoColors.signalDegraded,
        };
      case 'limited':
      default:
        return {
          'color': PuntoColors.signalLimited.withValues(alpha: 0.15),
          'textColor': PuntoColors.signalLimited,
        };
    }
  }

  String _signalLabel(String signal) {
    switch (signal) {
      case 'good':
        return 'Buena señal';
      case 'degraded':
        return 'Señal degradada';
      case 'limited':
      default:
        return 'Señal limitada';
    }
  }

  IconData _signalIcon(String signal) {
    switch (signal) {
      case 'good':
        return Icons.wifi_rounded;
      case 'degraded':
        return Icons.wifi_rounded;
      case 'limited':
      default:
        return Icons.wifi_off_rounded;
    }
  }
}
