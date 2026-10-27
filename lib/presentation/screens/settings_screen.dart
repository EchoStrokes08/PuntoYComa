import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../view_models/view_models.dart';

/// Pantalla de ajustes: tema, háptica, sonido y notificaciones.
///
/// Secciones agrupadas en tarjetas blancas; el contenido hace scroll.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PuntoScaffold(
      header: const PuntoScreenHeader(title: 'Ajustes'),
      child: SingleChildScrollView(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: PuntoSpacing.sm),
              Text(
                'Configura tu experiencia de PuntoYcoma.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: PuntoSpacing.lg),

              // ── Apariencia ─────────────────────────────────────────
              _SettingsSection(
                title: 'Apariencia',
                children: [
                  _SettingsTile(
                    icon: Icons.brightness_6_rounded,
                    title: 'Modo claro',
                    selected: _viewModel.themeMode == ThemeMode.light,
                    onTap: () => _viewModel.setThemeMode(ThemeMode.light),
                  ),
                  _SettingsTile(
                    icon: Icons.brightness_3_rounded,
                    title: 'Modo oscuro',
                    selected: _viewModel.themeMode == ThemeMode.dark,
                    onTap: () => _viewModel.setThemeMode(ThemeMode.dark),
                  ),
                  _SettingsTile(
                    icon: Icons.brightness_auto_rounded,
                    title: 'Sistema',
                    selected: _viewModel.themeMode == ThemeMode.system,
                    onTap: () => _viewModel.setThemeMode(ThemeMode.system),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: PuntoSpacing.lg),

              // ── Vibración y sonido ─────────────────────────────────
              _SettingsSection(
                title: 'Vibración y sonido',
                children: [
                  ListTile(
                    leading: const Icon(Icons.vibration_rounded),
                    title: const Text('Fuerza de vibración'),
                    subtitle: Text(
                      _viewModel.hapticStrength.toStringAsFixed(1),
                    ),
                    trailing: SizedBox(
                      width: 150,
                      child: Slider(
                        value: _viewModel.hapticStrength,
                        onChanged: _viewModel.setHapticStrength,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_rounded),
                    title: const Text('Sonido al final'),
                    trailing: Switch(
                      value: _viewModel.alarmSoundEnabled,
                      onChanged: _viewModel.setAlarmSoundEnabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PuntoSpacing.lg),

              // ── Notificaciones ─────────────────────────────────────
              _SettingsSection(
                title: 'Notificaciones',
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_none_rounded),
                    title: const Text('Permitir notificaciones'),
                    trailing: Switch(
                      value: _viewModel.notificationsEnabled,
                      onChanged: _viewModel.setNotificationsEnabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PuntoSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sección de ajustes: título + tarjeta blanca con las opciones.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: PuntoSpacing.sm,
            bottom: PuntoSpacing.s12,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.onSurfaceLow,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
          ),
        ),
        PuntoCard(
          color: context.surfaceBright,
          borderRadius: PuntoBorders.md,
          elevation: PuntoEffects.soft,
          padding: const EdgeInsets.symmetric(vertical: PuntoSpacing.xs),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Opción de ajuste con ícono, título y check de selección.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      button: true,
      selected: selected,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: selected
            ? Icon(
                Icons.check_rounded,
                color: context.primary,
              )
            : null,
        onTap: onTap,
        shape: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: context.outlineVariant,
                  width: 1,
                ),
              ),
      ),
    );
  }
}
