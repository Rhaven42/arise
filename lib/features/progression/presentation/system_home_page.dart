import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/rank_badge.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/design_system/widgets/xp_bar.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/utils/weekdays.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Fenêtre du Système (tableau de bord complet en phase 4).
class SystemHomePage extends ConsumerWidget {
  const SystemHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(playerProfileProvider).value;

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
      body: profile == null
          ? const Center(
              child: CircularProgressIndicator(color: AriseColors.gold),
            )
          : _SystemHomeBody(profile: profile),
    );
  }
}

class _SystemHomeBody extends StatelessWidget {
  const _SystemHomeBody({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final progression = gameConfig.progression;
    final restDays = (profile.restDays.toList()..sort())
        .map((day) => l10n.weekdayLong(weekdayKey(day)))
        .join(', ');

    return ListView(
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        SystemWindow(
          header: l10n.systemWindowHeader,
          title: l10n.systemWelcomeTitle,
          child: Text(l10n.systemWelcomeBody, style: textTheme.bodyLarge),
        ),
        const SizedBox(height: AriseSpacing.lg),
        Row(
          children: [
            RankBadge(rank: gameConfig.ranks.first.id),
            const SizedBox(width: AriseSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.systemLevel(progression.startLevel),
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: AriseSpacing.xs),
                  XpBar(current: 0, goal: progression.tutorialXp),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AriseSpacing.lg),
        Text(
          l10n.systemGoal(l10n.goalLabel(profile.goal.name)),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AriseSpacing.xs),
        Text(l10n.systemRestDays(restDays), style: textTheme.bodyLarge),
      ],
    );
  }
}
