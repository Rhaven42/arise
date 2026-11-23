import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/achievements/presentation/achievements_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Exploits sur la Fenêtre du Système : hauts faits obtenus, accès aux
/// titres et aux Ombres (le nom et le titre sont sur la fiche du héros).
class HunterPanel extends ConsumerWidget {
  const HunterPanel({super.key});

  static const achievementsKey = Key('hunter-achievements');
  static const titlesKey = Key('hunter-titles');
  static const shadowsKey = Key('hunter-shadows');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final unlocked =
        ref.watch(achievementsStateProvider).value?.unlocked.length ?? 0;
    return StoneFrame(
      padding: const EdgeInsets.symmetric(
        horizontal: AriseSpacing.sm,
        vertical: AriseSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: achievementsKey,
              onTap: () => context.go(AppRoutes.achievements),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AriseSpacing.sm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: AriseColors.gold,
                    ),
                    const SizedBox(width: AriseSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.achievementsCount(
                          unlocked,
                          gameConfig.achievements.definitions.length,
                        ),
                        style: textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            key: titlesKey,
            tooltip: l10n.titlesSeeAll,
            icon: const Icon(
              Icons.workspace_premium_outlined,
              color: AriseColors.gold,
            ),
            onPressed: () => context.go(AppRoutes.titles),
          ),
          IconButton(
            key: shadowsKey,
            tooltip: l10n.shadowsTitle,
            icon: const Icon(Icons.groups_outlined, color: AriseColors.gold),
            onPressed: () => context.go(AppRoutes.shadows),
          ),
        ],
      ),
    );
  }
}
