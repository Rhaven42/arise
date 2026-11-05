import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Saisie de l'intensité ressentie, de 1 (très facile) à 10 (maximal).
class IntensityPicker extends StatefulWidget {
  const IntensityPicker({
    required this.title,
    required this.onSubmitted,
    super.key,
  });

  final String title;
  final ValueChanged<int> onSubmitted;

  @override
  State<IntensityPicker> createState() => _IntensityPickerState();
}

class _IntensityPickerState extends State<IntensityPicker> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final config = gameConfig.intensity;
    final selected = _selected;

    return SystemWindow(
      header: l10n.systemWindowHeader,
      title: widget.title,
      actions: [
        AriseButton(
          label: l10n.workoutIntensityValidate,
          onPressed: selected == null
              ? null
              : () => widget.onSubmitted(selected),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.workoutIntensityHint, style: textTheme.bodyMedium),
          const SizedBox(height: AriseSpacing.md),
          Wrap(
            spacing: AriseSpacing.sm,
            runSpacing: AriseSpacing.sm,
            children: [
              for (var rpe = config.rpeMin; rpe <= config.rpeMax; rpe++)
                ChoiceChip(
                  label: Text('$rpe'),
                  tooltip: l10n.workoutIntensityLabel('r$rpe'),
                  selected: selected == rpe,
                  onSelected: (_) => setState(() => _selected = rpe),
                ),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: AriseSpacing.sm),
            Text(
              '${l10n.workoutIntensityValue(selected)} · '
              '${l10n.workoutIntensityLabel('r$selected')}',
              style: textTheme.titleMedium,
            ),
          ],
          if (selected == config.rpeMax) ...[
            const SizedBox(height: AriseSpacing.sm),
            Text(
              l10n.workoutIntensityMaxWarning,
              style: textTheme.bodyMedium?.copyWith(
                color: AriseColors.danger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
