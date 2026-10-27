import 'package:flutter/material.dart';

import '../../../domain/services/trip_monitor.dart';
import 'accessible_button.dart';

/// Banner que explica el estado de confianza de la señal con un mensaje
/// accionable para el usuario.
///
/// Los estados son:
/// - [TripConfidence.high]: señal buena, GPS reciente.
/// - [TripConfidence.degraded]: señal degradada, estimando con velocidad real.
/// - [TripConfidence.limited]: señal limitada, sin GPS nuevo (túnel/salida de cobertura).
class ConfidenceBanner extends StatelessWidget {
  const ConfidenceBanner({
    super.key,
    required this.confidence,
    this.onLearnMore,
  });

  final TripConfidence? confidence;
  final VoidCallback? onLearnMore;

  @override
  Widget build(BuildContext context) {
    if (confidence == null) {
      return const _EmptyBanner();
    }

    final data = _confidenceData(confidence!);
    return Semantics(
      label: data.label,
      hint: data.hint,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: data.color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: data.color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: data.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.hint,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onLearnMore != null) ...[
              const SizedBox(width: 8),
              AccessibleTextButton(
                onPressed: onLearnMore!,
                label: 'Más información sobre señal',
                child: const Text('Más info'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ConfidenceData _confidenceData(TripConfidence c) {
    switch (c) {
      case TripConfidence.high:
        return _ConfidenceData(
          label: 'Buena señal',
          hint: 'GPS actualizado recientemente. La alarma es precisa.',
          icon: Icons.wifi_rounded,
          color: Colors.green,
        );
      case TripConfidence.degraded:
        return _ConfidenceData(
          label: 'Señal degradada',
          hint: 'Estimando con velocidad real. La alarma sigue activa.',
          icon: Icons.wifi_rounded,
          color: Colors.amber,
        );
      case TripConfidence.limited:
        return _ConfidenceData(
          label: 'Señal limitada',
          hint: 'Sin GPS nuevo hace más de 3 min. Se usará el último fix conocido.',
          icon: Icons.wifi_off_rounded,
          color: Colors.red,
        );
    }
  }
}

class _ConfidenceData {
  const _ConfidenceData({
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
  });
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
