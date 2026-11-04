import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:flutter/material.dart';

/// Fenêtre du « Système » : annonce des quêtes, récompenses et messages.
class SystemWindow extends StatelessWidget {
  const SystemWindow({
    required this.header,
    required this.title,
    required this.child,
    super.key,
    this.actions = const [],
  });

  /// En-tête court affiché dans le bandeau lumineux (ex. « Système »).
  final String header;
  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: '$header. $title',
      child: StoneFrame(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AriseColors.mana.withValues(alpha: 0.05),
                      AriseColors.mana.withValues(alpha: 0.35),
                      AriseColors.mana.withValues(alpha: 0.05),
                    ],
                  ),
                  border: const Border(
                    bottom: BorderSide(color: AriseColors.mana),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AriseSpacing.sm,
                  ),
                  child: Text(
                    header.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(
                      color: AriseColors.parchment,
                      letterSpacing: 4,
                      shadows: const [
                        Shadow(color: AriseColors.mana, blurRadius: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AriseSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      color: AriseColors.goldBright,
                      fontVariations: AriseTypography.weight(700),
                    ),
                  ),
                  const SizedBox(height: AriseSpacing.sm),
                  child,
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: AriseSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AriseSpacing.sm,
                      runSpacing: AriseSpacing.sm,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
