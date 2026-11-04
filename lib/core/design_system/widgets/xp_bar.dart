import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Barre d'expérience vers le niveau suivant.
class XpBar extends StatelessWidget {
  const XpBar({required this.current, required this.goal, super.key})
    : assert(current >= 0, 'XP négative'),
      assert(goal > 0, 'Seuil nul');

  final int current;
  final int goal;

  /// Progression bornée entre 0 et 1.
  double get progress => (current / goal).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: l10n.xpSemantics(current, goal),
      value: '${(progress * 100).round()} %',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: AriseColors.abyss,
                border: Border.all(color: AriseColors.woodLight),
                borderRadius: BorderRadius.circular(AriseSpacing.radius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AriseSpacing.radius - 1),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    heightFactor: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AriseColors.mana, AriseColors.goldBright],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AriseSpacing.xs),
            Text(
              l10n.xpProgress(current, goal),
              textAlign: TextAlign.end,
              style: textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
