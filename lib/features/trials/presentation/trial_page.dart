import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/trials/domain/trial_rules.dart';
import 'package:arise/features/trials/presentation/trial_labels.dart';
import 'package:arise/features/trials/presentation/trials_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Message d'accès à l'épreuve (niveau, stat, délai), ou `null` si elle est
/// accessible.
String? trialBlockedLabel(AppLocalizations l10n, TrialAccess access) =>
    switch (access) {
      TrialAvailable() || TrialNone() => null,
      TrialNotYet(:final trial, :final unlockLevel) => l10n.trialNotYet(
        unlockLevel,
        bossLabel(l10n, trial),
      ),
      TrialStatTooLow(:final trial, :final current) => l10n.trialStatTooLow(
        l10n.statName(trial.requiredStat.name),
        current,
        trial.requiredValue,
        bossLabel(l10n, trial),
      ),
      TrialCoolingDown(:final trial, :final until) => l10n.trialCooldown(
        bossLabel(l10n, trial),
        formatTrialMoment(until),
      ),
    };

TrialDefinition? _trialOf(TrialAccess access) => switch (access) {
  TrialAvailable(:final trial) ||
  TrialNotYet(:final trial) ||
  TrialStatTooLow(:final trial) ||
  TrialCoolingDown(:final trial) => trial,
  TrialNone() => null,
};

/// Épreuve de rang sur la Fenêtre du Système.
class TrialPanel extends ConsumerWidget {
  const TrialPanel({super.key});

  static const openKey = Key('trial-open');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final access = ref.watch(trialAccessNowProvider).value;
    if (access == null) return const SizedBox.shrink();
    final trial = _trialOf(access);
    if (trial == null) return const SizedBox.shrink();
    final blocked = trialBlockedLabel(l10n, access);
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.trialCardTitle,
            style: textTheme.titleMedium?.copyWith(color: AriseColors.gold),
          ),
          const SizedBox(height: AriseSpacing.xs),
          Text(
            blocked ??
                l10n.trialAvailable(
                  bossLabel(l10n, trial),
                  nextRankLabel(l10n, trial),
                ),
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: AriseSpacing.sm),
          AriseButton(
            key: openKey,
            label: l10n.trialOpen,
            icon: Icons.shield_moon_outlined,
            variant: blocked == null
                ? AriseButtonVariant.primary
                : AriseButtonVariant.secondary,
            onPressed: () => context.go(AppRoutes.trial),
          ),
        ],
      ),
    );
  }
}

/// Présentation de l'épreuve : boss, objectif, condition, récompense et
/// consignes de prudence, puis lancement dans le lecteur de séance.
class TrialPage extends ConsumerWidget {
  const TrialPage({super.key});

  static const fightKey = Key('trial-fight');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final access = ref.watch(trialAccessNowProvider).value;
    final exercises =
        ref.watch(exercisesByIdProvider).value ?? const <String, Exercise>{};
    final trial = access == null ? null : _trialOf(access);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trialCardTitle)),
      body: access == null || trial == null
          ? const Center(
              child: CircularProgressIndicator(color: AriseColors.gold),
            )
          : ListView(
              padding: const EdgeInsets.all(AriseSpacing.md),
              children: [
                SystemWindow(
                  header: l10n.trialKind(trial.kind.name),
                  title: bossLabel(l10n, trial),
                  child: Text(
                    l10n.bossLore(trial.boss.name),
                    style: textTheme.bodyLarge?.copyWith(
                      fontFamily: AriseTypography.flavor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: AriseSpacing.lg),
                Text(
                  trialGoalLabel(l10n, trial, exercises),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AriseSpacing.sm),
                Text(
                  l10n.trialRequirement(
                    l10n.statName(trial.requiredStat.name),
                    trial.requiredValue,
                  ),
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: AriseSpacing.sm),
                Text(
                  l10n.trialRewardLine(
                    nextRankLabel(l10n, trial),
                    l10n.titleName(trial.titleId),
                    rewardItemLabel(l10n, trial.rewardItem),
                  ),
                  style: textTheme.bodyLarge?.copyWith(
                    color: AriseColors.goldBright,
                  ),
                ),
                const SizedBox(height: AriseSpacing.md),
                StoneFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.trialSafety, style: textTheme.bodyMedium),
                      const SizedBox(height: AriseSpacing.xs),
                      Text(l10n.trialRetryRule, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AriseSpacing.lg),
                if (trialBlockedLabel(l10n, access) case final blocked?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AriseSpacing.sm),
                    child: Text(
                      blocked,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AriseColors.mana,
                      ),
                    ),
                  ),
                AriseButton(
                  key: fightKey,
                  label: l10n.trialFight,
                  icon: Icons.bolt,
                  onPressed: access is TrialAvailable
                      ? () => context.go(AppRoutes.workout(trial.program.id))
                      : null,
                ),
              ],
            ),
    );
  }
}
