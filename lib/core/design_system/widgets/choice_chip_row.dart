import 'package:arise/core/theme/arise_spacing.dart';
import 'package:flutter/material.dart';

/// Option d'une [ChoiceChipRow].
class ChipOption<T> {
  const ChipOption(this.value, this.label);

  final T value;
  final String label;
}

/// Rangée de puces à choix unique qui défile horizontalement, précédée de
/// son titre ; la première puce ([allLabel]) remet le choix à `null`.
class ChoiceChipRow<T> extends StatelessWidget {
  const ChoiceChipRow({
    required this.title,
    required this.allLabel,
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String title;
  final String allLabel;
  final List<ChipOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, {required bool on, required T? value}) => Padding(
      padding: const EdgeInsets.only(right: AriseSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => onChanged(value),
      ),
    );
    return Semantics(
      container: true,
      label: title,
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AriseSpacing.md),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: AriseSpacing.sm),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            chip(allLabel, on: selected == null, value: null),
            for (final option in options)
              chip(
                option.label,
                on: option.value == selected,
                value: option.value,
              ),
          ],
        ),
      ),
    );
  }
}
