import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/achievements/domain/achievement_rules.dart';
import 'package:arise/features/achievements/presentation/achievements_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hauts faits, par catégorie, avec leur avancement.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  static Key tileKey(String id) => Key('achievement-$id');

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  @override
  void initState() {
    super.initState();
    // Rattrapage : les hauts faits déjà mérités (avant la phase 9, après une
    // restauration) sont obtenus à l'ouverture de la page.
    unawaited(ref.read(achievementsControllerProvider.notifier).evaluate());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(achievementsStateProvider).value;
    final metrics = ref.watch(achievementMetricsProvider).value;
    final definitions = gameConfig.achievements.definitions;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: state == null || metrics == null
          ? const Center(
              child: CircularProgressIndicator(color: AriseColors.gold),
            )
          : ListView(
              padding: const EdgeInsets.all(AriseSpacing.md),
              children: [
                Text(
                  l10n.achievementsCount(
                    state.unlocked.length,
                    definitions.length,
                  ),
                  style: textTheme.titleMedium?.copyWith(
                    color: AriseColors.gold,
                  ),
                ),
                for (final category in AchievementCategory.values) ...[
                  const SizedBox(height: AriseSpacing.lg),
                  Text(
                    l10n.achievementCategory(category.name),
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: AriseSpacing.xs),
                  for (final d in definitions)
                    if (d.category == category)
                      _AchievementTile(
                        definition: d,
                        unlockedAt: state.unlocked[d.id],
                        progress: achievementProgress(d, metrics),
                      ),
                ],
              ],
            ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.definition,
    required this.unlockedAt,
    required this.progress,
  });

  final AchievementDefinition definition;
  final DateTime? unlockedAt;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final done = unlockedAt != null;
    final hidden = definition.secret && !done;
    final name = hidden
        ? l10n.achievementSecretName
        : l10n.achievementName(definition.id);
    final description = hidden
        ? l10n.achievementSecretHint
        : l10n.achievementDescription(definition.id);
    final title = definition.titleId;
    final status = done
        ? l10n.achievementUnlockedOn(
            formatCivilDate(CivilDate.ofLocal(unlockedAt!)),
          )
        : hidden
        ? ''
        : l10n.achievementProgress(progress, definition.threshold);
    return Padding(
      key: AchievementsPage.tileKey(definition.id),
      padding: const EdgeInsets.symmetric(vertical: AriseSpacing.xs),
      child: Semantics(
        label: [
          name,
          description,
          status,
        ].where((t) => t.isNotEmpty).join('. '),
        child: ExcludeSemantics(
          child: StoneFrame(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  done
                      ? Icons.emoji_events
                      : hidden
                      ? Icons.help_outline
                      : Icons.lock_outline,
                  color: done ? AriseColors.goldBright : null,
                  size: 28,
                ),
                const SizedBox(width: AriseSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: textTheme.titleMedium),
                      Text(description, style: textTheme.bodyMedium),
                      if (title != null && !hidden)
                        Text(
                          l10n.achievementRewardTitle(l10n.titleName(title)),
                          style: textTheme.bodySmall?.copyWith(
                            color: AriseColors.gold,
                          ),
                        ),
                      if (status.isNotEmpty) ...[
                        const SizedBox(height: AriseSpacing.xs),
                        if (!done)
                          LinearProgressIndicator(
                            value: progress / definition.threshold,
                            color: AriseColors.gold,
                            backgroundColor: AriseColors.gold.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        Text(status, style: textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
