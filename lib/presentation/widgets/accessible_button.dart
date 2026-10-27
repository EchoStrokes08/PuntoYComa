import 'package:flutter/material.dart';

/// Botón con tamaño mínimo táctil de 48 dp y semántica para lectores de pantalla.
///
/// Todos los botones interactivos de la app deben usar este widget para cumplir
/// con los criterios de accesibilidad (WCAG 2.1 AA: 44x44 dp mínimo, aquí 48 dp).
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 18.0,
    this.minWidth = double.infinity,
  });

  final Widget child;
  final VoidCallback onPressed;
  final String? label;
  final String? hint;
  final Color? backgroundColor;
  final Color? foregroundColor;
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
          minHeight: 48, // ≥ 48 dp touch target (accessibility requirement)
        ),
        child: Material(
          color: backgroundColor ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
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

/// Filled button variant using the theme's filled button style.
class AccessibleFilledButton extends StatelessWidget {
  const AccessibleFilledButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
    this.borderRadius = 18.0,
  });

  final Widget child;
  final VoidCallback onPressed;
  final String? label;
  final String? hint;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 48, // ≥ 48 dp touch target
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          icon: _iconFromChild(child),
          label: _labelFromChild(child),
        ),
      ),
    );
  }

  Widget? _iconFromChild(Widget child) {
    if (child is Icon) return child;
    return null;
  }

  Widget _labelFromChild(Widget child) {
    if (child is! Icon) return child;
    return const SizedBox.shrink();
  }
}

/// Outlined button variant with accessible touch target.
class AccessibleOutlinedButton extends StatelessWidget {
  const AccessibleOutlinedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
    this.borderRadius = 18.0,
  });

  final Widget child;
  final VoidCallback onPressed;
  final String? label;
  final String? hint;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          minHeight: 48, // ≥ 48 dp touch target
        ),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          icon: _iconFromChild(child),
          label: _labelFromChild(child),
        ),
      ),
    );
  }

  Widget? _iconFromChild(Widget child) {
    if (child is Icon) return child;
    return null;
  }

  Widget _labelFromChild(Widget child) {
    if (child is! Icon) return child;
    return const SizedBox.shrink();
  }
}

/// Text button variant with accessible touch target.
class AccessibleTextButton extends StatelessWidget {
  const AccessibleTextButton({
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
    return Semantics(
      button: true,
      label: label,
      hint: hint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: TextButton(
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }
}
