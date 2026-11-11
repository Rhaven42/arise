import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/quests/domain/quest_rules.dart';
import 'package:arise/features/quests/presentation/quests_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Quête du jour sur la Fenêtre du Système : objectifs, progression,
/// récompense et quête de pénalité.
class QuestPanel extends ConsumerWidget {
  const QuestPanel({super.key});

  static const startKey = Key('quest-start');
  static const boardKey = Key('quest-board');
  static const penaltyKey = Key('quest-penalty-start');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final view = ref.watch(questControllerProvider).value;
    final exercises =
        ref.watch(exercisesByIdProvider).value ?? const <String, Exercise>{};
    final level = ref.watch(progressionControllerProvider).value?.state.level;
    if (view == null || level == null) return const SizedBox.shrink();
    final quest = view.quest;

    final boardLink = AriseButton(
      key: boardKey,
      label: l10n.questsOpen,
      icon: Icons.map_outlined,
      variant: AriseButtonVariant.secondary,
      onPressed: () => context.go(AppRoutes.quests),
    );
    if (quest.restDay || !quest.hasObjectives) {
      return SystemWindow(
        header: l10n.systemWindowHeader,
        title: l10n.questDailyTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.questRestDay, style: textTheme.bodyLarge),
            const SizedBox(height: AriseSpacing.sm),
            boardLink,
          ],
        ),
      );
    }

    final reward = dailyQuestReward(level);
    return SystemWindow(
      header: l10n.systemWindowHeader,
      title: l10n.questDailyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < quest.objectives.length; i++)
            _ObjectiveLine(
              objective: quest.objectives[i],
              done: view.progress[i],
              exercise: exercises[quest.objectives[i].exerciseId],
            ),
          const SizedBox(height: AriseSpacing.sm),
          if (quest.claimed)
            Text(
              l10n.questCompleted,
              style: textTheme.titleMedium?.copyWith(
                color: AriseColors.goldBright,
              ),
            )
          else ...[
            Text(
              l10n.questReward(
                reward.xp,
                formatCoins(l10n, reward.coins),
                reward.willpower,
              ),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AriseSpacing.sm),
            AriseButton(
              key: startKey,
              label: l10n.questStart,
              icon: Icons.flag_outlined,
              onPressed: () =>
                  context.go(AppRoutes.workout(dailyQuestProgramId)),
            ),
          ],
          if (view.penaltyActive) ...[
            const SizedBox(height: AriseSpacing.md),
            Text(
              l10n.questPenaltyTitle,
              style: textTheme.titleMedium?.copyWith(color: AriseColors.mana),
            ),
            Text(l10n.questPenaltyHint, style: textTheme.bodyMedium),
            for (var i = 0; i < view.penaltyObjectives.length; i++)
              _ObjectiveLine(
                objective: view.penaltyObjectives[i],
                done: view.penaltyProgress[i],
                exercise: exercises[view.penaltyObjectives[i].exerciseId],
              ),
            const SizedBox(height: AriseSpacing.sm),
            AriseButton(
              key: penaltyKey,
              label: l10n.questPenaltyStart,
              icon: Icons.shield_outlined,
              variant: AriseButtonVariant.secondary,
              onPressed: () =>
                  context.go(AppRoutes.workout(penaltyQuestProgramId)),
            ),
          ],
          const SizedBox(height: AriseSpacing.sm),
          boardLink,
        ],
      ),
    );
  }
}

/// Un objectif : exercice, quantité réalisée et barre de progression.
class _ObjectiveLine extends StatelessWidget {
  const _ObjectiveLine({
    required this.objective,
    required this.done,
    required this.exercise,
  });

  final QuestObjective objective;
  final int done;
  final Exercise? exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final name = exercise?.name ?? objective.exerciseId;
    String amount(int value) => switch (objective.metric) {
      QuestMetric.reps => '$value',
      QuestMetric.seconds =>
        value >= 60 && value % 60 == 0
            ? l10n.durationMinutes(value ~/ 60)
            : l10n.durationSeconds(value),
    };
    final finished = done >= objective.target;
    final label = finished
        ? l10n.questObjectiveDone(name)
        : l10n.questObjective(name, amount(done), amount(objective.target));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AriseSpacing.xs),
      child: Semantics(
        label: label,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    finished ? Icons.check_circle : Icons.circle_outlined,
                    size: 18,
                    color: finished ? AriseColors.goldBright : null,
                  ),
                  const SizedBox(width: AriseSpacing.xs),
                  Expanded(child: Text(label, style: textTheme.bodyLarge)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: objective.target == 0 ? 1 : done / objective.target,
                color: AriseColors.gold,
                backgroundColor: AriseColors.gold.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
