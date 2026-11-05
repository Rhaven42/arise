import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/rank_badge.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/design_system/widgets/xp_bar.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/core/utils/weekdays.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/planning/domain/schedule.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Fenêtre du Système : tableau de bord du chasseur.
class SystemHomePage extends ConsumerWidget {
  const SystemHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(playerProfileProvider).value;
    final progression = ref.watch(progressionControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.systemHomeTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
      body: profile == null || progression == null
          ? const Center(
              child: CircularProgressIndicator(color: AriseColors.gold),
            )
          : _SystemHomeBody(profile: profile, view: progression),
    );
  }
}

class _SystemHomeBody extends ConsumerWidget {
  const _SystemHomeBody({required this.profile, required this.view});

  final PlayerProfile profile;
  final ProgressionView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = view.state;
    final now = ref.watch(clockProvider)();
    final controller = ref.read(progressionControllerProvider.notifier);
    final restDays = (profile.restDays.toList()..sort())
        .map((day) => l10n.weekdayLong(weekdayKey(day)))
        .join(', ');
    final sessions = ref.watch(plannedSessionsProvider).value ?? const [];
    final programs = ref.watch(programsProvider).value ?? const [];
    final next = nextOccurrence(sessions, now);
    final nextProgram = next == null
        ? null
        : programs.where((p) => p.id == next.session.programId).firstOrNull;
    final sickUntil = state.sickUntil;

    return ListView(
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        if (view.report case final report?) ...[
          _ReportWindow(
            report: report,
            onDismiss: () => unawaited(controller.dismissReport()),
          ),
          const SizedBox(height: AriseSpacing.md),
        ],
        if (sickUntil != null && state.isSickOn(CivilDate.ofLocal(now)))
          SystemWindow(
            header: l10n.systemWindowHeader,
            title: l10n.homeSickTitle,
            child: Text(
              l10n.homeSickBody(formatCivilDate(sickUntil)),
              style: textTheme.bodyLarge,
            ),
          )
        else if (state.isPenaltyActive(now))
          SystemWindow(
            header: l10n.systemWindowHeader,
            title: l10n.homePenaltyTitle,
            child: Text(l10n.homePenaltyBody, style: textTheme.bodyLarge),
          )
        else
          SystemWindow(
            header: l10n.systemWindowHeader,
            title: l10n.systemWelcomeTitle,
            child: Text(l10n.systemWelcomeBody, style: textTheme.bodyLarge),
          ),
        const SizedBox(height: AriseSpacing.lg),
        _LevelPanel(state: state),
        const SizedBox(height: AriseSpacing.lg),
        _StatsPanel(
          state: state,
          onAllocate: (stat) => unawaited(controller.allocate(stat)),
        ),
        const SizedBox(height: AriseSpacing.lg),
        _StreakPanel(state: state),
        const SizedBox(height: AriseSpacing.lg),
        Text(
          next == null || nextProgram == null
              ? l10n.homeNoNextSession
              : l10n.homeNextSession(
                  nextProgram.name,
                  '${l10n.weekdayLong(weekdayKey(next.start.weekday))} '
                  '${DateFormat.Hm('fr').format(next.start)}',
                ),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AriseSpacing.xs),
        Text(
          l10n.systemGoal(l10n.goalLabel(profile.goal.name)),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AriseSpacing.xs),
        Text(l10n.systemRestDays(restDays), style: textTheme.bodyLarge),
        const SizedBox(height: AriseSpacing.lg),
        _HomeLink(
          icon: Icons.fitness_center,
          title: l10n.exercisesTitle,
          subtitle: l10n.homeExercisesHint,
          onTap: () => context.go(AppRoutes.exercises),
        ),
        _HomeLink(
          icon: Icons.list_alt,
          title: l10n.programsTitle,
          subtitle: l10n.homeProgramsHint,
          onTap: () => context.go(AppRoutes.programs),
        ),
        _HomeLink(
          icon: Icons.calendar_month,
          title: l10n.planningTitle,
          subtitle: l10n.homePlanningHint,
          onTap: () => context.go(AppRoutes.planning),
        ),
      ],
    );
  }
}

class _LevelPanel extends StatelessWidget {
  const _LevelPanel({required this.state});

  final ProgressionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final rankName = l10n.rankName(state.rank.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            RankBadge(rank: state.rank),
            const SizedBox(width: AriseSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.systemLevel(state.level),
                    style: textTheme.titleLarge,
                  ),
                  Text(
                    l10n.homeRankLabel(rankName),
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AriseSpacing.xs),
                  XpBar(
                    current: state.xpInLevel,
                    goal: state.isAtMaxLevel ? 1 : state.xpForNextLevel,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (state.isRankLocked && state.xpInLevel >= state.xpForNextLevel)
          Padding(
            padding: const EdgeInsets.only(top: AriseSpacing.sm),
            child: Text(
              l10n.progressRankLocked(rankName),
              style: textTheme.bodyMedium?.copyWith(color: AriseColors.mana),
            ),
          ),
        const SizedBox(height: AriseSpacing.sm),
        Row(
          children: [
            const Icon(Icons.diamond_outlined, color: AriseColors.mana),
            const SizedBox(width: AriseSpacing.xs),
            Text(
              l10n.homeCrystals(state.crystals),
              style: textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.state, required this.onAllocate});

  final ProgressionState state;
  final ValueChanged<StatId> onAllocate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final canAllocate = state.freeStatPoints > 0;
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.homeStatsTitle, style: textTheme.titleLarge),
          ),
          if (canAllocate)
            Text(
              l10n.homeFreePoints(state.freeStatPoints),
              style: textTheme.bodyMedium?.copyWith(
                color: AriseColors.goldBright,
              ),
            ),
          const SizedBox(height: AriseSpacing.sm),
          for (final stat in StatId.values)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.homeStatValue(
                      l10n.statName(stat.name),
                      state.stat(stat),
                    ),
                    style: textTheme.bodyLarge,
                  ),
                ),
                if (canAllocate)
                  IconButton(
                    tooltip: l10n.homeAllocate(l10n.statName(stat.name)),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AriseColors.gold,
                    ),
                    onPressed: () => onAllocate(stat),
                  )
                else
                  const SizedBox(height: AriseSpacing.minTouchTarget),
              ],
            ),
        ],
      ),
    );
  }
}

class _StreakPanel extends StatelessWidget {
  const _StreakPanel({required this.state});

  final ProgressionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final percent = ((streakMultiplier(state.streakDays) - 1) * 100).round();
    return StoneFrame(
      material: FrameMaterial.wood,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(l10n.homeStreakTitle, style: textTheme.titleLarge),
          ),
          const SizedBox(height: AriseSpacing.xs),
          Text(l10n.homeStreak(state.streakDays), style: textTheme.titleMedium),
          Text(
            l10n.homeBestStreak(state.bestStreak),
            style: textTheme.bodyMedium,
          ),
          if (percent > 0)
            Text(l10n.homeStreakBonus(percent), style: textTheme.bodyMedium),
          Text(
            l10n.homeShields(state.shields, gameConfig.streaks.maxShields),
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ReportWindow extends StatelessWidget {
  const _ReportWindow({required this.report, required this.onDismiss});

  final RolloverReport report;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return SystemWindow(
      header: l10n.systemWindowHeader,
      title: l10n.homeReportTitle,
      actions: [
        AriseButton(label: l10n.homeReportDismiss, onPressed: onDismiss),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (report.missedDays > 0)
            Text(
              l10n.homeReportMissed(report.missedDays),
              style: textTheme.bodyLarge,
            ),
          if (report.shieldsUsed > 0)
            Text(
              l10n.homeReportShieldUsed(report.shieldsUsed),
              style: textTheme.bodyLarge,
            ),
          if (report.streakLost > 0)
            Text(
              l10n.homeReportStreakLost(report.streakLost),
              style: textTheme.bodyLarge,
            ),
          if (report.penaltyStarted)
            Text(
              l10n.homePenaltyBody,
              style: textTheme.bodyMedium?.copyWith(color: AriseColors.danger),
            ),
          if (report.shieldsEarned > 0)
            Text(
              l10n.homeReportShieldEarned(report.shieldsEarned),
              style: textTheme.bodyLarge?.copyWith(
                color: AriseColors.goldBright,
              ),
            ),
        ],
      ),
    );
  }
}

/// Accès à une section du jeu depuis la Fenêtre du Système.
class _HomeLink extends StatelessWidget {
  const _HomeLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AriseSpacing.sm),
      child: StoneFrame(
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            leading: Icon(icon, color: AriseColors.gold),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
