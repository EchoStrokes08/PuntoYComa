import 'package:flutter/material.dart';

import '../../design/tokens/tokens.dart';

/// Botón primario de PuntoYcoma con estilo premium.
///
/// Touch target ≥ 48dp, label semántica para lectores de pantalla, y
/// animación de presión sutil.
class PuntoButton extends StatelessWidget {
  const PuntoButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = PuntoBorders.sm,
    this.minWidth = double.infinity,
    this.isLoading = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final String? hint;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final double minWidth;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? hint ?? '';
    final enabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      label: effectiveLabel.isNotEmpty ? effectiveLabel : null,
      hint: hint,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          minHeight: 48, // ≥ 48dp touch target (accessibility requirement)
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: enabled
                ? (backgroundColor ?? Theme.of(context).colorScheme.primary)
                : Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.2,
                  ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: enabled ? onPressed : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// BotónOutlined de PuntoYcoma con estilo premium.
class PuntoOutlinedButton extends StatelessWidget {
  const PuntoOutlinedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
    this.borderRadius = PuntoBorders.sm,
    this.minWidth = double.infinity,
  });

  final Widget child;
  final VoidCallback onPressed;
  final String? label;
  final String? hint;
  final double borderRadius;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? hint ?? '';
    return Semantics(
      button: true,
      label: effectiveLabel.isNotEmpty ? effectiveLabel : null,
      hint: hint,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          minHeight: 48, // ≥ 48dp touch target
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Center(
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de texto de PuntoYcoma con estilo premium.
class PuntoTextButton extends StatelessWidget {
  const PuntoTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
  });

  final Widget child;
  final VoidCallback onPressed;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? hint ?? '';
    return Semantics(
      button: true,
      label: effectiveLabel.isNotEmpty ? effectiveLabel : null,
      hint: hint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
