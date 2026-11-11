import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/quests/domain/quest_board_rules.dart';
import 'package:arise/features/quests/presentation/quests_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Quête de la semaine, donjon hebdomadaire et événement en cours.
class QuestsPage extends ConsumerWidget {
  const QuestsPage({super.key});

  static Key enterRoomKey(int room) => Key('dungeon-enter-$room');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(questBoardProvider).value;
    final level =
        ref.watch(progressionControllerProvider).value?.state.level ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.questsPageTitle)),
      body: view == null
          ? const Center(
              child: CircularProgressIndicator(color: AriseColors.gold),
            )
          : ListView(
              padding: const EdgeInsets.all(AriseSpacing.md),
              children: [
                _WeeklySection(view: view, level: level),
                const SizedBox(height: AriseSpacing.lg),
                _DungeonSection(view: view),
                const SizedBox(height: AriseSpacing.lg),
                _EventSection(view: view),
              ],
            ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.label, required this.done, required this.of});

  final String label;
  final int done;
  final int of;

  @override
  Widget build(BuildContext context) {
    final finished = done >= of;
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
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: of == 0 ? 1 : done / of,
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

class _WeeklySection extends StatelessWidget {
  const _WeeklySection({required this.view, required this.level});

  final QuestBoardView view;
  final int level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final weekly = view.board.weekly!;
    final c = weeklyRewardPreview(level);
    return SystemWindow(
      header: l10n.systemWindowHeader,
      title: l10n.weeklyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < weekly.objectives.length; i++)
            _Progress(
              label: l10n.weeklyObjective(
                weekly.objectives[i].metric.name,
                view.weeklyProgress[i],
                weekly.objectives[i].target,
              ),
              done: view.weeklyProgress[i],
              of: weekly.objectives[i].target,
            ),
          const SizedBox(height: AriseSpacing.sm),
          Text(
            weekly.claimed
                ? l10n.weeklyClaimed
                : l10n.weeklyReward(c.xp, formatCoins(l10n, c.coins)),
            style: textTheme.bodyMedium?.copyWith(
              color: weekly.claimed ? AriseColors.goldBright : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DungeonSection extends ConsumerWidget {
  const _DungeonSection({required this.view});

  final QuestBoardView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final dungeon = view.board.dungeon!;
    final theme = dungeon.theme.name;
    final today = CivilDate.ofLocal(ref.watch(clockProvider)());
    final next = view.nextRoom;
    final waiting =
        next == null &&
        view.clearedDays.length < dungeonRoomCount &&
        view.clearedDays.isNotEmpty &&
        view.clearedDays.last == today;
    return StoneFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dungeonTitle,
            style: textTheme.titleMedium?.copyWith(color: AriseColors.gold),
          ),
          Text(l10n.dungeonThemeName(theme), style: textTheme.titleLarge),
          const SizedBox(height: AriseSpacing.xs),
          Text(
            l10n.dungeonThemeLore(theme),
            style: textTheme.bodyLarge?.copyWith(
              fontFamily: AriseTypography.flavor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AriseSpacing.xs),
          Text(l10n.dungeonRule, style: textTheme.bodyMedium),
          const SizedBox(height: AriseSpacing.sm),
          for (var room = 0; room < dungeonRoomCount; room++)
            if (room < view.clearedDays.length)
              _Progress(label: l10n.dungeonRoomDone(room + 1), done: 1, of: 1)
            else if (room == next)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AriseSpacing.xs),
                child: AriseButton(
                  key: QuestsPage.enterRoomKey(room),
                  label: l10n.dungeonEnter(room + 1),
                  icon: Icons.door_front_door_outlined,
                  onPressed: () =>
                      context.go(AppRoutes.workout(dungeonRoomProgramId(room))),
                ),
              )
            else
              _Progress(
                label: l10n.dungeonRoomLocked(room + 1),
                done: 0,
                of: 1,
              ),
          if (view.resting && !dungeon.looted)
            Text(l10n.questRestDay, style: textTheme.bodyMedium)
          else if (waiting)
            Text(l10n.dungeonRoomTomorrow, style: textTheme.bodyMedium),
          if (dungeon.looted)
            Text(
              l10n.dungeonCompleted,
              style: textTheme.titleMedium?.copyWith(
                color: AriseColors.goldBright,
              ),
            ),
        ],
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  const _EventSection({required this.view});

  final QuestBoardView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final edition = view.event;
    if (edition == null) {
      return StoneFrame(
        child: Text(l10n.eventNone, style: textTheme.bodyLarge),
      );
    }
    final claimed = view.board.claimedEvents.contains(edition.key);
    return SystemWindow(
      header: l10n.eventTitle,
      title: l10n.eventName(edition.event.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Progress(
            label: l10n.eventObjective(
              edition.event.metric.name,
              view.eventProgress,
              edition.event.target,
              formatCivilDate(edition.end),
            ),
            done: view.eventProgress,
            of: edition.event.target,
          ),
          if (claimed)
            Text(
              l10n.eventClaimed,
              style: textTheme.bodyMedium?.copyWith(
                color: AriseColors.goldBright,
              ),
            ),
        ],
      ),
    );
  }
}

/// Récompense annoncée de la quête hebdomadaire.
({int xp, Coins coins}) weeklyRewardPreview(int level) {
  final reward = weeklyReward(level);
  return (xp: reward.xp, coins: reward.coins);
}
