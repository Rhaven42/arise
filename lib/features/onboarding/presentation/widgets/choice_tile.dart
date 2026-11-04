import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:flutter/material.dart';

/// Carte de choix unique (objectif, niveau…), accessible au lecteur d'écran.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AriseSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? AriseColors.stoneLight : AriseColors.stone,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AriseSpacing.radius),
            side: BorderSide(
              color: selected ? AriseColors.gold : AriseColors.woodLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AriseSpacing.radius),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AriseSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AriseSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: textTheme.titleMedium),
                          const SizedBox(height: AriseSpacing.xs),
                          Text(description, style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? AriseColors.gold
                          : AriseColors.parchmentMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
