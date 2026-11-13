import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/stat_gem.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Écran des statistiques : valeur de chaque stat, ce qui la fait monter,
/// jauge vers le prochain point gagné et placement des points libres.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  static Key allocateKey(StatId stat) => Key('stats-allocate-${stat.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: const [StatsSheet()],
      ),
    );
  }
}

/// Fiche des statistiques (points libres, chaque stat, classe), affichée
/// sous le personnage sur la Fenêtre du Système.
class StatsSheet extends ConsumerWidget {
  const StatsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(progressionControllerProvider).value?.state;
    final controller = ref.read(progressionControllerProvider.notifier);
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FreePoints(state: state),
        for (final stat in StatId.values) ...[
          const SizedBox(height: AriseSpacing.md),
          _StatCard(
            stat: stat,
            state: state,
            onAllocate: state.freeStatPoints > 0
                ? () => unawaited(controller.allocate(stat))
                : null,
          ),
        ],
        if (state.rank.index >= gameConfig.classes.unlockRank.index) ...[
          const SizedBox(height: AriseSpacing.lg),
          AriseButton(
            label: l10n.statsHeroClass,
            icon: Icons.shield_moon_outlined,
            variant: AriseButtonVariant.secondary,
            onPressed: () => context.go(AppRoutes.heroClass),
          ),
        ],
      ],
    );
  }
}

class _FreePoints extends StatelessWidget {
  const _FreePoints({required this.state});

  final ProgressionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final points = state.freeStatPoints;
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.statsFreePoints(points),
              style: textTheme.titleLarge?.copyWith(
                color: points > 0 ? AriseColors.goldBright : AriseColors.gold,
              ),
            ),
          ),
          const SizedBox(height: AriseSpacing.xs),
          Text(
            points > 0
                ? l10n.statsFreeHint(gameConfig.progression.statPointsPerLevel)
                : l10n.statsNoFreeHint,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.stat,
    required this.state,
    required this.onAllocate,
  });

  final StatId stat;
  final ProgressionState state;
  final VoidCallback? onAllocate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = l10n.statName(stat.name);
    final value = state.stat(stat);
    final allocated = state.allocatedIn(stat);
    final toward = state.statXpTowardNextPoint(stat);
    final needed = gameConfig.progression.statXpPerPoint;
    final color = statGemColor(stat);
    return StoneFrame(
      padding: const EdgeInsets.all(AriseSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatGem(
            color: color,
            value: value,
            label: name,
            semanticsLabel: l10n.homeStatValue(name, value),
          ),
          const SizedBox(width: AriseSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleMedium),
                Text(l10n.statsHowTo(stat.name), style: textTheme.bodySmall),
                const SizedBox(height: AriseSpacing.xs),
                Text(
                  l10n.statsBreakdown(allocated, value - allocated),
                  style: textTheme.bodySmall?.copyWith(
                    color: AriseColors.parchmentMuted,
                  ),
                ),
                const SizedBox(height: AriseSpacing.xs),
                if (toward == null)
                  Text(
                    l10n.statsWillpowerNext,
                    style: textTheme.bodySmall?.copyWith(color: color),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: toward / needed,
                      minHeight: 6,
                      color: color,
                      backgroundColor: AriseColors.stoneDark,
                      semanticsLabel: l10n.statsNextPoint(toward, needed),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.statsNextPoint(toward, needed),
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (onAllocate != null)
            IconButton(
              key: StatsPage.allocateKey(stat),
              tooltip: l10n.homeAllocate(name),
              iconSize: 32,
              icon: const Icon(Icons.add_circle, color: AriseColors.goldBright),
              onPressed: onAllocate,
            ),
        ],
      ),
    );
  }
}
