import 'package:flutter/material.dart';

/// Petite pastille : icône et libellé de la même couleur. L'icône et le
/// texte portent l'information, la couleur ne fait que la renforcer.
class LabeledTag extends StatelessWidget {
  const LabeledTag({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}
