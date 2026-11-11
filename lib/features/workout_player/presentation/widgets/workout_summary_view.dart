import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/anatomy/muscle_legend.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/presentation/exercise_labels.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/quests/domain/quest_board_rules.dart';
import 'package:arise/features/trials/domain/trial_rules.dart';
import 'package:arise/features/trials/presentation/trial_labels.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/domain/session_summary.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Récapitulatif de fin de séance : XP, effort, muscles travaillés.
class WorkoutSummaryView extends StatelessWidget {
  const WorkoutSummaryView({
    required this.session,
    required this.exercises,
    required this.onClose,
    super.key,
    this.progress,
    this.questOutcome,
    this.trialOutcome,
  });

  final CompletedSession session;

  /// Effets sur la progression (absents pour un ancien enregistrement).
  final SessionProgress? progress;

  /// Quêtes accomplies grâce à la séance.
  final QuestReport? questOutcome;

  /// Issue de l'épreuve de rang jouée.
  final TrialOutcome? trialOutcome;
  final Map<String, Exercise> exercises;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final roles = workedMuscles(session, exercises);
    final done = session.sets.where((s) => !s.skipped).length;

    String names(BodyView view, MuscleRole role) {
      final list = [
        for (final entry in roles.entries)
          if (entry.key.view == view && entry.value == role)
            l10n.muscle(entry.key),
      ];
      return list.isEmpty ? l10n.noneLabel : list.join(', ');
    }

    return ListView(
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        if (session.stoppedForPain) ...[
          _Caution(title: l10n.workoutPainTitle, body: l10n.workoutPainBody),
          const SizedBox(height: AriseSpacing.md),
        ],
        if (trialOutcome case final outcome?) ...[
          _TrialResult(outcome: outcome),
          const SizedBox(height: AriseSpacing.md),
        ],
        SystemWindow(
          header: l10n.systemWindowHeader,
          title: session.completed
              ? l10n.workoutSummaryTitle
              : l10n.workoutSummaryStoppedTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: l10n.workoutSummaryXpSemantics(session.xpEarned),
                child: ExcludeSemantics(
                  child: Text(
                    l10n.workoutSummaryXp(session.xpEarned),
                    style: TextStyle(
                      fontFamily: AriseTypography.display,
                      fontVariations: AriseTypography.weight(900),
                      fontSize: 40,
                      color: AriseColors.goldBright,
                      shadows: const [
                        Shadow(color: AriseColors.mana, blurRadius: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AriseSpacing.sm),
              Text(
                l10n.workoutSummaryDuration(
                  session.activeSeconds ~/ 60,
                  session.activeSeconds % 60,
                ),
                style: textTheme.bodyLarge,
              ),
              Text(
                l10n.workoutSummarySets(
                  done,
                  session.plannedEfforts > 0
                      ? session.plannedEfforts
                      : session.sets.length,
                ),
                style: textTheme.bodyLarge,
              ),
              if (progress case final progress?)
                ..._progressLines(l10n, textTheme, progress),
              if (questOutcome case final outcome?)
                ..._questLines(l10n, textTheme, outcome),
              const SizedBox(height: AriseSpacing.sm),
              Text(l10n.workoutSummaryProvisional, style: textTheme.bodySmall),
            ],
          ),
        ),
        if (session.exceededDailyCap) ...[
          const SizedBox(height: AriseSpacing.md),
          _Caution(body: l10n.workoutSummaryCapWarning),
        ],
        const SizedBox(height: AriseSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.workoutSummaryMuscles,
            style: textTheme.headlineSmall?.copyWith(color: AriseColors.gold),
          ),
        ),
        const SizedBox(height: AriseSpacing.sm),
        Row(
          children: [
            for (final view in BodyView.values)
              Expanded(
                child: Column(
                  children: [
                    Text(l10n.bodyViewLabel(view.name)),
                    const SizedBox(height: AriseSpacing.xs),
                    SizedBox(
                      height: 260,
                      child: BodyMap(
                        view: view,
                        highlights: roles,
                        semanticLabel: l10n.bodyMapSemantics(
                          view.name,
                          names(view, MuscleRole.primary),
                          names(view, MuscleRole.secondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AriseSpacing.sm),
        const MuscleLegend(),
        const SizedBox(height: AriseSpacing.xl),
        AriseButton(label: l10n.workoutSummaryClose, onPressed: onClose),
      ],
    );
  }
}

/// Lignes du bilan consacrées à la progression.
List<Widget> _progressLines(
  AppLocalizations l10n,
  TextTheme textTheme,
  SessionProgress progress,
) {
  final highlight = textTheme.titleMedium?.copyWith(
    color: AriseColors.goldBright,
  );
  final state = progress.state;
  return [
    const SizedBox(height: AriseSpacing.sm),
    if (progress.multiplier > 1)
      Text(
        l10n.progressStreakBonus(
          progress.multiplier.toStringAsFixed(2).replaceAll('.', ','),
        ),
        style: textTheme.bodyLarge,
      ),
    if (progress.multiplier < 1)
      Text(l10n.progressPenaltyMalus, style: textTheme.bodyLarge),
    if (progress.classXp > 0)
      Text(
        l10n.progressClassBonus(progress.classXp),
        style: textTheme.bodyLarge,
      ),
    if (!progress.sessionCoins.isZero)
      Text(
        l10n.progressSessionCoins(formatCoins(l10n, progress.sessionCoins)),
        style: textTheme.bodyLarge,
      ),
    if (progress.levelsGained > 0) ...[
      Text(l10n.progressLevelUp(state.level), style: highlight),
      Text(
        l10n.progressRewards(
          formatCoins(l10n, progress.levelCoins),
          progress.statPointsGained,
        ),
        style: textTheme.bodyLarge,
      ),
    ],
    if (progress.dayValidated)
      Text(
        l10n.progressDayValidated(state.streakDays),
        style: textTheme.bodyLarge,
      ),
    if (!progress.chestCoins.isZero)
      Text(
        l10n.progressChest(formatCoins(l10n, progress.chestCoins)),
        style: highlight,
      ),
    if (progress.rankLocked)
      Text(
        l10n.progressRankLocked(l10n.rankName(state.rank.name)),
        style: textTheme.bodyLarge?.copyWith(color: AriseColors.mana),
      ),
  ];
}

/// Lignes du bilan consacrées aux quêtes.
List<Widget> _questLines(
  AppLocalizations l10n,
  TextTheme textTheme,
  QuestReport report,
) {
  final outcome = report.daily;
  final board = report.board;
  final highlight = textTheme.titleMedium?.copyWith(
    color: AriseColors.goldBright,
  );
  final reward = outcome.reward;
  return [
    const SizedBox(height: AriseSpacing.sm),
    if (outcome.penaltyCleared)
      Text(l10n.progressPenaltyCleared, style: textTheme.bodyLarge),
    if (reward != null)
      Text(
        l10n.questRewardEarned(
          reward.xp,
          formatCoins(l10n, reward.coins),
          reward.willpower,
        ),
        style: highlight,
      ),
    if (outcome.gain case final gain? when gain.levelsGained > 0)
      Text(l10n.progressLevelUp(outcome.state.level), style: highlight),
    if (outcome.dayValidated)
      Text(
        l10n.questDayValidated(outcome.state.streakDays),
        style: textTheme.bodyLarge,
      ),
    if (!outcome.chest.isZero)
      Text(
        l10n.progressChest(formatCoins(l10n, outcome.chest)),
        style: highlight,
      ),
    if (board.roomCleared case final room?)
      Text(
        l10n.dungeonRoomCleared(
          l10n.dungeonRoomName(board.board.dungeon!.theme.name, room + 1),
        ),
        style: highlight,
      ),
    if (board.dungeonCompleted)
      Text(
        board.lootItem == null
            ? l10n.dungeonLootCoins(formatCoins(l10n, board.lootCoins))
            : l10n.dungeonLootItem(l10n.itemName(board.lootItem!.id)),
        style: highlight,
      ),
    if (board.weeklyReward case final reward?)
      Text(
        l10n.weeklyRewardEarned(reward.xp, formatCoins(l10n, reward.coins)),
        style: highlight,
      ),
    if (board.eventReward case final reward?)
      Text(
        l10n.eventRewardEarned(
          l10n.eventName(board.event!.event.id),
          reward.xp,
          formatCoins(l10n, reward.coins),
        ),
        style: highlight,
      ),
  ];
}

/// Annonce de l'issue d'une épreuve de rang : victoire (avec une courte
/// animation d'apparition, coupée si le téléphone limite les animations)
/// ou défaite sans perte.
class _TrialResult extends StatelessWidget {
  const _TrialResult({required this.outcome});

  final TrialOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final trial = outcome.trial;
    final boss = bossLabel(l10n, trial);
    if (!outcome.won) {
      final retry = outcome.retryAt;
      return _Caution(
        body: l10n.trialDefeat(
          boss,
          retry == null ? '' : formatTrialMoment(retry),
        ),
      );
    }
    final window = SystemWindow(
      header: l10n.systemWindowHeader,
      title: l10n.trialVictoryTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.trialVictoryBody(boss, nextRankLabel(l10n, trial)),
            style: textTheme.titleMedium?.copyWith(
              color: AriseColors.goldBright,
            ),
          ),
          const SizedBox(height: AriseSpacing.sm),
          Text(
            l10n.trialTitleEarned(l10n.titleName(trial.titleId)),
            style: textTheme.bodyLarge,
          ),
          Text(
            l10n.trialItemEarned(rewardItemLabel(l10n, trial.rewardItem)),
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
    if (MediaQuery.of(context).disableAnimations) return window;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
      child: window,
    );
  }
}

/// Encadré de prudence (douleur, dépassement du plafond quotidien).
class _Caution extends StatelessWidget {
  const _Caution({required this.body, this.title});

  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AriseColors.stoneDark,
          border: Border.all(color: AriseColors.danger, width: 2),
          borderRadius: BorderRadius.circular(AriseSpacing.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AriseSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.health_and_safety, color: AriseColors.danger),
              const SizedBox(width: AriseSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title case final title?)
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: AriseColors.danger,
                        ),
                      ),
                    Text(body, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
