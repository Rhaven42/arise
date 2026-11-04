import 'package:flutter/material.dart';

/// Variante visuelle d'un bouton.
enum AriseButtonVariant { primary, secondary }

/// Bouton du design system (cible tactile d'au moins 48 px).
///
/// `onPressed` à `null` désactive le bouton.
class AriseButton extends StatelessWidget {
  const AriseButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AriseButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AriseButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    final iconWidget = icon == null ? null : Icon(icon, size: 20);

    return switch (variant) {
      AriseButtonVariant.primary =>
        iconWidget == null
            ? FilledButton(onPressed: onPressed, child: text)
            : FilledButton.icon(
                onPressed: onPressed,
                icon: iconWidget,
                label: text,
              ),
      AriseButtonVariant.secondary =>
        iconWidget == null
            ? OutlinedButton(onPressed: onPressed, child: text)
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: iconWidget,
                label: text,
              ),
    };
  }
}
