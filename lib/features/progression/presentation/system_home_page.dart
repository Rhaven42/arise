import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/rank_badge.dart';
import 'package:arise/core/design_system/widgets/stat_gem.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/design_system/widgets/xp_bar.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/core/utils/weekdays.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/planning/domain/schedule.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/titles/presentation/titles_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Fenêtre du Système : tableau de bord du chasseur.
class SystemHomePage extends ConsumerWidget {
  const SystemHomePage({super.key, this.panels = const [], this.bottomBar});

  /// Panneaux d'autres fonctionnalités (quête du jour, épreuve de rang),
  /// assemblés par le routeur et affichés sous le message du Système.
  final List<Widget> panels;

  /// Barre d'action (assemblée par le routeur).
  final Widget? bottomBar;

  /// En-tête de la barre des statistiques (ouvre l'écran détaillé).
  static const statsKey = Key('home-stats');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(playerProfileProvider).value;
    final progression = ref.watch(progressionControllerProvider).value;

    return Scaffold(
      bottomNavigationBar: bottomBar,
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
          : _SystemHomeBody(
              profile: profile,
              view: progression,
              panels: panels,
            ),
    );
  }
}

class _SystemHomeBody extends ConsumerWidget {
  const _SystemHomeBody({
    required this.profile,
    required this.view,
    required this.panels,
  });

  final PlayerProfile profile;
  final ProgressionView view;
  final List<Widget> panels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = view.state;
    final now = ref.watch(clockProvider)();
    final controller = ref.read(progressionControllerProvider.notifier);
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
        _HeroHud(state: state),
        const SizedBox(height: AriseSpacing.md),
        // Barre des statistiques : le détail est sur l'écran des stats.
        _StatsPanel(
          state: state,
          onAllocate: (stat) => unawaited(controller.allocate(stat)),
          onOpen: () => context.go(AppRoutes.stats),
        ),
        if (view.report case final report?) ...[
          const SizedBox(height: AriseSpacing.md),
          _ReportWindow(
            report: report,
            onDismiss: () => unawaited(controller.dismissReport()),
          ),
        ],
        // Message du Système seulement quand il y a quelque chose à dire.
        if (sickUntil != null && state.isSickOn(CivilDate.ofLocal(now))) ...[
          const SizedBox(height: AriseSpacing.md),
          SystemWindow(
            header: l10n.systemWindowHeader,
            title: l10n.homeSickTitle,
            child: Text(
              l10n.homeSickBody(formatCivilDate(sickUntil)),
              style: textTheme.bodyLarge,
            ),
          ),
        ] else if (state.isPenaltyActive(now)) ...[
          const SizedBox(height: AriseSpacing.md),
          SystemWindow(
            header: l10n.systemWindowHeader,
            title: l10n.homePenaltyTitle,
            child: Text(l10n.homePenaltyBody, style: textTheme.bodyLarge),
          ),
        ],
        if (state.isRankLocked && state.xpInLevel >= state.xpForNextLevel)
          Padding(
            padding: const EdgeInsets.only(top: AriseSpacing.sm),
            child: Text(
              l10n.progressRankLocked(l10n.rankName(state.rank.name)),
              style: textTheme.bodyMedium?.copyWith(color: AriseColors.mana),
            ),
          ),
        for (final panel in panels) ...[
          const SizedBox(height: AriseSpacing.md),
          panel,
        ],
        const SizedBox(height: AriseSpacing.md),
        _TodayStrip(
          state: state,
          nextSession: next == null || nextProgram == null
              ? l10n.homeNoNextSession
              : l10n.homeNextSession(
                  nextProgram.name,
                  '${l10n.weekdayLong(weekdayKey(next.start.weekday))} '
                  '${DateFormat.Hm('fr').format(next.start)}',
                ),
        ),
        const SizedBox(height: AriseSpacing.md),
        _Shortcuts(
          items: [
            (Icons.fitness_center, l10n.exercisesTitle, AppRoutes.exercises),
            (Icons.list_alt, l10n.programsTitle, AppRoutes.programs),
            (Icons.calendar_month, l10n.planningTitle, AppRoutes.planning),
            (Icons.bar_chart, l10n.statsTitle, AppRoutes.stats),
            (
              Icons.accessibility_new,
              l10n.homeShortcutAnalysis,
              AppRoutes.analysis,
            ),
            (Icons.favorite_outline, l10n.healthTitle, AppRoutes.health),
          ],
        ),
      ],
    );
  }
}

/// Fiche du héros, façon MMO : médaillon de rang avec le niveau, nom,
/// titre porté, barre d'expérience et bourse.
class _HeroHud extends ConsumerWidget {
  const _HeroHud({required this.state});

  final ProgressionState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sheet = ref.watch(savedCharacterProvider).value;
    final title = ref.watch(titlesViewProvider).value?.worn.equippedTitle;
    final name = sheet == null || sheet.name.isEmpty
        ? l10n.heroUnnamed
        : sheet.name;
    return StoneFrame(
      padding: const EdgeInsets.all(AriseSpacing.sm),
      child: Row(
        children: [
          _Medallion(state: state),
          const SizedBox(width: AriseSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge,
                ),
                Text(
                  title == null ? l10n.hunterNoTitle : l10n.titleName(title),
                  style: textTheme.bodyLarge?.copyWith(
                    fontFamily: AriseTypography.flavor,
                    fontStyle: FontStyle.italic,
                    color: title == null
                        ? AriseColors.parchmentMuted
                        : AriseColors.goldBright,
                  ),
                ),
                Wrap(
                  spacing: AriseSpacing.sm,
                  children: [
                    Text(
                      l10n.systemLevel(state.level),
                      style: textTheme.labelLarge?.copyWith(
                        color: AriseColors.gold,
                      ),
                    ),
                    Text(
                      l10n.homeRankLabel(l10n.rankName(state.rank.name)),
                      style: textTheme.labelLarge?.copyWith(
                        color: RankBadge.colorOf(state.rank),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AriseSpacing.xs),
                XpBar(
                  current: state.xpInLevel,
                  goal: state.isAtMaxLevel ? 1 : state.xpForNextLevel,
                ),
                _Wallet(coins: state.wallet),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Médaillon de rang serti d'or, avec le niveau en pastille.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.state});

  final ProgressionState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AriseColors.goldBright.withValues(alpha: 0.35),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: RankBadge(rank: state.rank, size: 80),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: ExcludeSemantics(
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF3A2A10), Color(0xFF140D05)],
                  ),
                  border: Border.all(color: AriseColors.goldBright, width: 2),
                ),
                child: Text(
                  '${state.level}',
                  style: TextStyle(
                    fontFamily: AriseTypography.display,
                    fontVariations: AriseTypography.weight(800),
                    fontSize: 13,
                    color: AriseColors.goldBright,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bourse : pièces d'or, d'argent et de bronze (couleur + nom de la pièce).
class _Wallet extends StatelessWidget {
  const _Wallet({required this.coins});

  final Coins coins;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.titleMedium;
    return Semantics(
      label: l10n.homeWallet(formatCoins(l10n, coins)),
      excludeSemantics: true,
      child: Wrap(
        spacing: AriseSpacing.md,
        runSpacing: AriseSpacing.xs,
        children: [
          for (final (color, count) in [
            (AriseColors.coinGold, coins.gold()),
            (AriseColors.coinSilver, coins.silver()),
            (AriseColors.coinBronze, coins.bronze()),
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: color, size: 18),
                const SizedBox(width: AriseSpacing.xs),
                Text('$count', style: style),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.state,
    required this.onAllocate,
    required this.onOpen,
  });

  final ProgressionState state;
  final ValueChanged<StatId> onAllocate;

  /// Ouvre l'écran détaillé des statistiques.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final canAllocate = state.freeStatPoints > 0;
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: SystemHomePage.statsKey,
            onTap: onOpen,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.homeStatsTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: AriseColors.gold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AriseColors.gold),
              ],
            ),
          ),
          if (canAllocate)
            Text(
              l10n.homeFreePoints(state.freeStatPoints),
              style: textTheme.bodyMedium?.copyWith(
                color: AriseColors.goldBright,
              ),
            ),
          const SizedBox(height: AriseSpacing.sm),
          Row(
            children: [
              for (final stat in StatId.values)
                Expanded(
                  child: Column(
                    children: [
                      StatGem(
                        color: statGemColor(stat),
                        value: state.stat(stat),
                        label: l10n.statName(stat.name),
                        semanticsLabel: l10n.homeStatValue(
                          l10n.statName(stat.name),
                          state.stat(stat),
                        ),
                      ),
                      if (canAllocate)
                        IconButton(
                          tooltip: l10n.homeAllocate(l10n.statName(stat.name)),
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AriseColors.goldBright,
                          ),
                          onPressed: () => onAllocate(stat),
                        ),
                    ],
                  ),
                ),
            ],
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

/// Série du jour et prochaine séance, sur une seule carte.
class _TodayStrip extends StatelessWidget {
  const _TodayStrip({required this.state, required this.nextSession});

  final ProgressionState state;
  final String nextSession;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final percent = ((streakMultiplier(state.streakDays) - 1) * 100).round();
    return StoneFrame(
      material: FrameMaterial.wood,
      padding: const EdgeInsets.symmetric(
        horizontal: AriseSpacing.md,
        vertical: AriseSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AriseColors.ember),
              const SizedBox(width: AriseSpacing.xs),
              Expanded(
                child: Text(
                  percent > 0
                      ? '${l10n.homeStreak(state.streakDays)} · '
                            '${l10n.homeStreakBonus(percent)}'
                      : l10n.homeStreak(state.streakDays),
                  style: textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.shield_outlined, color: AriseColors.mana),
              const SizedBox(width: AriseSpacing.xs),
              Text(
                l10n.homeShields(state.shields, gameConfig.streaks.maxShields),
                style: textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AriseSpacing.xs),
          Text(nextSession, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Raccourcis vers les sections du jeu : une grille d'icônes.
class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.items});

  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AriseSpacing.sm,
      crossAxisSpacing: AriseSpacing.sm,
      childAspectRatio: 1.1,
      children: [
        for (final (icon, label, route) in items)
          StoneFrame(
            padding: EdgeInsets.zero,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => context.go(route),
                child: Padding(
                  padding: const EdgeInsets.all(AriseSpacing.xs),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AriseColors.gold, size: 28),
                      const SizedBox(height: AriseSpacing.xs),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
