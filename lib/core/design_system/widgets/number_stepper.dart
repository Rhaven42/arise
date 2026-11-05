import 'package:arise/core/theme/arise_spacing.dart';
import 'package:flutter/material.dart';

/// Réglage d'une valeur numérique par boutons − et +.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    required this.label,
    required this.value,
    required this.display,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.decreaseLabel,
    required this.increaseLabel,
    super.key,
  });

  final String label;
  final num value;
  final String display;
  final num step;
  final num min;
  final num max;
  final ValueChanged<num> onChanged;
  final String decreaseLabel;
  final String increaseLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: label,
      value: display,
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          IconButton(
            tooltip: decreaseLabel,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value - step >= min
                ? () => onChanged(value - step)
                : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: ExcludeSemantics(
              child: Text(
                display,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall,
              ),
            ),
          ),
          IconButton(
            tooltip: increaseLabel,
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value + step <= max
                ? () => onChanged(value + step)
                : null,
          ),
          const SizedBox(width: AriseSpacing.xs),
        ],
      ),
    );
  }
}
