import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/labeled_tag.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/world_palette.dart';
import 'package:arise/features/achievements/presentation/achievements_providers.dart';
import 'package:arise/features/worlds/domain/world.dart';
import 'package:arise/features/worlds/presentation/world_labels.dart';
import 'package:arise/features/worlds/presentation/world_style.dart';
import 'package:arise/features/worlds/presentation/worlds_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Univers : l'actif, ceux à rejoindre, et le haut fait qui ouvre chacun des
/// autres, avec son avancement.
class WorldsPage extends ConsumerWidget {
  const WorldsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeWorldProvider);
    final unlocked = {
      ...?ref.watch(achievementsStateProvider).value?.unlocked.keys,
    };
    final metrics = ref.watch(achievementMetricsProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.worldsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          Text(l10n.worldsIntro, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AriseSpacing.md),
          for (final world in World.values) ...[
            _WorldCard(
              world: world,
              active: world == active,
              open: isWorldUnlocked(world, unlocked),
              progress: switch (unlockDefinitionOf(world)) {
                final d? => (metrics[d.metric] ?? 0, d.threshold),
                null => null,
              },
              // L'application se reconstruit dans l'ambiance du nouvel
              // univers : le changement se voit sans message.
              onEnter: () => ref
                  .read(worldsControllerProvider.notifier)
                  .activate(world, unlocked),
            ),
            const SizedBox(height: AriseSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({
    required this.world,
    required this.active,
    required this.open,
    required this.progress,
    required this.onEnter,
  });

  final World world;
  final bool active;
  final bool open;

  /// Avancement du haut fait d'appel (valeur, seuil), `null` sans haut fait.
  final (int, int)? progress;
  final Future<bool> Function() onEnter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final palette = paletteOf(world);
    final achievement = world.unlockAchievement;
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aperçu de l'ambiance : bandeau aux couleurs et à la police de
          // l'univers.
          _Banner(palette: palette, title: worldLabel(l10n, world)),
          const SizedBox(height: AriseSpacing.sm),
          Text(l10n.worldDescription(world.name), style: textTheme.bodyMedium),
          const SizedBox(height: AriseSpacing.sm),
          if (active)
            LabeledTag(
              icon: Icons.check_circle_outline,
              label: l10n.worldActive,
              color: AriseColors.success,
            )
          else if (open)
            AriseButton(
              label: l10n.worldEnter,
              icon: Icons.login,
              onPressed: () => unawaited(onEnter()),
            )
          else ...[
            LabeledTag(
              icon: Icons.lock_outline,
              label: l10n.worldLockedBy(l10n.achievementName(achievement!)),
              color: AriseColors.parchmentMuted,
            ),
            if (progress case (final current, final goal)) ...[
              const SizedBox(height: AriseSpacing.xs),
              Semantics(
                label: l10n.worldProgress(
                  current,
                  goal,
                  gameConfig.achievements.realmWindowDays,
                ),
                child: LinearProgressIndicator(
                  value: (current / goal).clamp(0, 1).toDouble(),
                ),
              ),
              const SizedBox(height: AriseSpacing.xs),
              Text(
                l10n.worldProgress(
                  current,
                  goal,
                  gameConfig.achievements.realmWindowDays,
                ),
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Bandeau d'aperçu d'un univers.
class _Banner extends StatelessWidget {
  const _Banner({required this.palette, required this.title});

  final WorldPalette palette;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AriseSpacing.md,
        vertical: AriseSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AriseSpacing.radius),
        gradient: LinearGradient(
          colors: [palette.backdropTop, palette.wood, palette.backdropBottom],
        ),
        border: Border.all(color: palette.gold),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: palette.displayFont,
          fontSize: 24,
          color: palette.goldBright,
        ),
      ),
    );
  }
}
