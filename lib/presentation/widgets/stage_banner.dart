import 'package:flutter/material.dart';

import '../../../domain/services/wake_up_policy.dart';

/// Banner que muestra la etapa actual de la alarma con el estado háptico.
class StageBanner extends StatelessWidget {
  const StageBanner({
    super.key,
    required this.stage,
  });

  final WakeUpStage stage;

  @override
  Widget build(BuildContext context) {
    final data = _stageData(stage);
    return Semantics(
      label: data.label,
      hint: data.hint,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: data.color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(data.icon, color: data.color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: data.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StageData _stageData(WakeUpStage s) {
    switch (s) {
      case WakeUpStage.monitoring:
        return const _StageData(
          label: 'Vigilando la ruta',
          hint: 'La alarma está activa y monitorea tu posición.',
          icon: Icons.radar_rounded,
          color: Colors.blue,
        );
      case WakeUpStage.gentleHaptic:
        return const _StageData(
          label: 'Vibración suave activa',
          hint: 'Estás entrando en el radio de alerta.',
          icon: Icons.vibration_rounded,
          color: Colors.green,
        );
      case WakeUpStage.persistentHaptic:
        return const _StageData(
          label: 'Vibración insistente',
          hint: 'Confirma si despierto con "Ya desperté".',
          icon: Icons.vibration_rounded,
          color: Colors.orange,
        );
      case WakeUpStage.audibleFallback:
        return const _StageData(
          label: 'Alarma sonora activa',
          hint: 'Prepara tu salida. La alarma suena.',
          icon: Icons.notifications_active_rounded,
          color: Colors.red,
        );
    }
  }
}

class _StageData {
  const _StageData({
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
