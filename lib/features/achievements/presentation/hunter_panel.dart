import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.hunterExploits,
              style: textTheme.titleMedium?.copyWith(
                color: AriseColors.gold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AriseSpacing.xs),
          Text(
            l10n.achievementsCount(
              unlocked,
              gameConfig.achievements.definitions.length,
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AriseSpacing.sm),
          Wrap(
            spacing: AriseSpacing.sm,
            runSpacing: AriseSpacing.sm,
            children: [
              AriseButton(
                key: achievementsKey,
                label: l10n.achievementsTitle,
                icon: Icons.emoji_events_outlined,
                onPressed: () => context.go(AppRoutes.achievements),
              ),
              AriseButton(
                key: titlesKey,
                label: l10n.titlesSeeAll,
                icon: Icons.workspace_premium_outlined,
                variant: AriseButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.titles),
              ),
              AriseButton(
                key: shadowsKey,
                label: l10n.shadowsTitle,
                icon: Icons.groups_outlined,
                variant: AriseButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.shadows),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
