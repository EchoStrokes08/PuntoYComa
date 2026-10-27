import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/tokens/tokens.dart';

/// Botón primario de PuntoYcoma con estilo premium.
///
/// - Texto e íconos SIEMPRE en color legible (`onPrimary` por defecto):
///   el contenido no hereda el color del entorno, lo que evitaba texto
///   oscuro sobre el verde profundo del fondo.
/// - Feedback de pulsación: escala 0.98 + haptic leve.
/// - Touch target ≥ 48dp; altura por defecto 56 para CTA.
/// - Estado deshabilitado legible: superficie neutra clara y tinta atenuada.
class PuntoButton extends StatefulWidget {
  const PuntoButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = PuntoBorders.sm,
    this.fullWidth = false,
    this.height = 56,
    this.isLoading = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final String? hint;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;

  /// Cuando es true, el botón se expande para ocupar todo el ancho disponible
  /// (útil dentro de Column). Dentro de un Row, envuelve en Expanded.
  final bool fullWidth;

  /// Altura mínima del botón (≥ 48dp por accesibilidad).
  final double height;
  final bool isLoading;

  @override
  State<PuntoButton> createState() => _PuntoButtonState();
}

class _PuntoButtonState extends State<PuntoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = widget.label ?? widget.hint ?? '';
    final enabled = widget.onPressed != null && !widget.isLoading;

    final scheme = Theme.of(context).colorScheme;
    final background = enabled
        ? (widget.backgroundColor ?? scheme.primary)
        : scheme.onSurface.withValues(alpha: 0.08);
    final foreground = enabled
        ? (widget.foregroundColor ?? scheme.onPrimary)
        : scheme.onSurface.withValues(alpha: 0.6);

    return Semantics(
      button: true,
      label: effectiveLabel.isNotEmpty ? effectiveLabel : null,
      hint: widget.hint,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.fullWidth ? double.infinity : 0,
          minHeight: widget.height, // ≥ 48dp touch target (accesibilidad)
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.98).animate(
            CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            // Altura fija: el `Center` interior se expande a la altura máxima
            // disponible cuando las restricciones son acotadas (p. ej. el
            // `bottomNavigationBar` de un Scaffold deja altura suelta pero
            // finita) y el botón deshabilitado terminaba cubriendo toda la
            // pantalla y absorbiendo los taps del contenido. Con altura
            // explícita el botón mide exactamente `height` en cualquier
            // contexto y el contenido queda centrado de verdad.
            height: widget.height,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: enabled ? _handleTap : null,
                onHighlightChanged: (highlighted) {
                  if (highlighted) {
                    _pressController.forward();
                  } else {
                    _pressController.reverse();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: PuntoSpacing.md,
                    horizontal: PuntoSpacing.lg,
                  ),
                  child: Center(
                    child: _PuntoButtonContent(
                      foreground: foreground,
                      isLoading: widget.isLoading,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenido de botón con color garantizado: envuelve íconos y texto en
/// [IconTheme] y [DefaultTextStyle] del color efectivo del botón.
class _PuntoButtonContent extends StatelessWidget {
  const _PuntoButtonContent({
    required this.foreground,
    required this.isLoading,
    required this.child,
  });

  final Color foreground;
  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(foreground),
        ),
      );
    }
    return IconTheme(
      data: IconThemeData(color: foreground, size: 20),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
        child: child,
      ),
    );
  }
}

/// Botón outlined (secundario) de PuntoYcoma con estilo premium.
///
/// Borde fino del color de marca, fondo transparente y contenido en color
/// primario. Su peso visual es menor que el CTA principal.
class PuntoOutlinedButton extends StatefulWidget {
  const PuntoOutlinedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
    this.foregroundColor,
    this.backgroundColor,
    this.borderRadius = PuntoBorders.sm,
    this.fullWidth = false,
    this.height = 48,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final String? hint;

  /// Color de texto, íconos y borde. Por defecto el primario de la marca.
  final Color? foregroundColor;

  /// Relleno del botón (por defecto transparente). Útil sobre fondos de
  /// alarma, donde un scrim oscuro mejora el contraste.
  final Color? backgroundColor;
  final double borderRadius;

  /// Cuando es true, el botón se expande para ocupar todo el ancho disponible
  /// (útil dentro de Column). Dentro de un Row, envuelve en Expanded.
  final bool fullWidth;

  /// Altura mínima del botón (≥ 48dp por accesibilidad).
  final double height;

  @override
  State<PuntoOutlinedButton> createState() => _PuntoOutlinedButtonState();
}

class _PuntoOutlinedButtonState extends State<PuntoOutlinedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = widget.label ?? widget.hint ?? '';
    final enabled = widget.onPressed != null;

    final scheme = Theme.of(context).colorScheme;
    final foreground = enabled
        ? (widget.foregroundColor ?? scheme.primary)
        : scheme.onSurface.withValues(alpha: 0.5);

    return Semantics(
      button: true,
      label: effectiveLabel.isNotEmpty ? effectiveLabel : null,
      hint: widget.hint,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.fullWidth ? double.infinity : 0,
          minHeight: widget.height, // ≥ 48dp touch target
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.98).animate(
            CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            // Altura fija por la misma razón que en PuntoButton: el `Center`
            // interior se expande cuando las restricciones de altura son
            // acotadas (p. ej. el `bottomNavigationBar` de un Scaffold) y
            // crecía hasta cubrir la pantalla.
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: enabled
                    ? foreground
                    : scheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                onTap: enabled ? _handleTap : null,
                onHighlightChanged: (highlighted) {
                  if (highlighted) {
                    _pressController.forward();
                  } else {
                    _pressController.reverse();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: PuntoSpacing.md,
                    horizontal: PuntoSpacing.lg,
                  ),
                  child: Center(
                    child: _PuntoButtonContent(
                      foreground: foreground,
                      isLoading: false,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de texto de PuntoYcoma, para acciones terciarias.
class PuntoTextButton extends StatelessWidget {
  const PuntoTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.label,
    this.hint,
    this.foregroundColor,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final String? hint;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? hint ?? '';
    final enabled = onPressed != null;
    final scheme = Theme.of(context).colorScheme;
    final foreground = enabled
        ? (foregroundColor ?? scheme.primary)
        : scheme.onSurface.withValues(alpha: 0.5);

    return Semantics(
      button: true,
      label: effectiveLabel.isNotEmpty ? effectiveLabel : null,
      hint: hint,
      enabled: enabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.selectionClick();
                    onPressed?.call();
                  }
                : null,
            borderRadius: BorderRadius.circular(PuntoBorders.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: PuntoSpacing.sm + PuntoSpacing.xs,
                horizontal: PuntoSpacing.md,
              ),
              child: Center(
                child: _PuntoButtonContent(
                  foreground: foreground,
                  isLoading: false,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
