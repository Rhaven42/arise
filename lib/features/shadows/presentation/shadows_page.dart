import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/design_system/widgets/system_window.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/shadows/domain/shadow_rules.dart';
import 'package:arise/features/shadows/domain/shadows_state.dart';
import 'package:arise/features/shadows/presentation/shadows_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nom affiché d'une Ombre (boss ou donjon d'origine).
String shadowLabel(AppLocalizations l10n, ShadowOrigin origin) =>
    l10n.shadowName(origin.name);

/// Armée d'Ombres : extraction, activation, bonus.
class ShadowsPage extends ConsumerStatefulWidget {
  const ShadowsPage({super.key});

  static Key extractKey(String key) => Key('shadow-extract-$key');
  static Key toggleKey(String id) => Key('shadow-toggle-$id');

  @override
  ConsumerState<ShadowsPage> createState() => _ShadowsPageState();
}

class _ShadowsPageState extends ConsumerState<ShadowsPage> {
  @override
  void initState() {
    super.initState();
    // Les boss vaincus avant la phase 9 offrent aussi leur Ombre.
    unawaited(ref.read(shadowsControllerProvider.notifier).offerFromBosses());
  }

  Future<void> _extract(ShadowOrigin origin) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final shadow = await ref
        .read(shadowsControllerProvider.notifier)
        .extract(origin.key);
    if (shadow == null) return;
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.shadowExtracted(shadowLabel(l10n, origin))),
        ),
      );
  }

  Future<void> _toggle(Shadow shadow) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final issue = await ref
        .read(shadowsControllerProvider.notifier)
        .toggle(shadow.id);
    if (issue != ShadowIssue.full) return;
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.shadowsFull)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(shadowsStateProvider).value;
    final progression = ref.watch(progressionControllerProvider).value?.state;
    final sheet = ref.watch(savedCharacterProvider).value;
    final inventory = ref.watch(inventoryProvider).value ?? const Inventory();
    if (state == null || progression == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.shadowsTitle)),
        body: const Center(
          child: CircularProgressIndicator(color: AriseColors.gold),
        ),
      );
    }
    final heroClass = progression.heroClass;
    final active = activeShadows(state, heroClass: heroClass);
    final bonus = (shadowBonus(heroClass) * 100).round();
    final unlocked =
        progression.rank.index >= gameConfig.shadows.unlockRank.index;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shadowsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          if (sheet != null && state.shadows.isNotEmpty)
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.32,
              child: ref
                  .watch(characterRendererProvider)
                  .build(
                    appearance: CharacterAppearance.of(
                      sheet,
                      loadout: loadoutOf(inventory),
                    ).adorned(shadows: [for (final s in active) s.index]),
                  ),
            ),
          Text(l10n.shadowsIntro(bonus), style: textTheme.bodyLarge),
          if (!unlocked && state.shadows.isEmpty && state.pending.isEmpty) ...[
            const SizedBox(height: AriseSpacing.md),
            StoneFrame(
              child: Text(l10n.shadowsLocked, style: textTheme.titleMedium),
            ),
          ],
          if (state.pending.isNotEmpty) ...[
            const SizedBox(height: AriseSpacing.md),
            SystemWindow(
              header: l10n.systemWindowHeader,
              title: l10n.shadowsPending,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final origin in state.pending)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AriseSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            shadowLabel(l10n, origin),
                            style: textTheme.titleMedium,
                          ),
                          Text(
                            l10n.shadowBonus(
                              bonus,
                              l10n.statName(origin.stat.name),
                            ),
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AriseSpacing.xs),
                          AriseButton(
                            key: ShadowsPage.extractKey(origin.key),
                            label: l10n.shadowExtract,
                            icon: Icons.auto_awesome,
                            onPressed: () => unawaited(_extract(origin)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AriseSpacing.md),
          Text(l10n.shadowsArmy, style: textTheme.titleLarge),
          Text(
            l10n.shadowsActiveCount(active.length, maxActiveShadows(heroClass)),
            style: textTheme.bodyMedium,
          ),
          if (state.shadows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AriseSpacing.sm),
              child: Text(l10n.shadowsEmpty, style: textTheme.bodyLarge),
            ),
          for (final shadow in state.shadows)
            SwitchListTile(
              key: ShadowsPage.toggleKey(shadow.id),
              value: active.contains(shadow),
              onChanged: (_) => unawaited(_toggle(shadow)),
              title: Text(shadowLabel(l10n, shadow.origin)),
              subtitle: Text(
                [
                  l10n.shadowBonus(
                    bonus,
                    l10n.statName(shadow.origin.stat.name),
                  ),
                  if (active.contains(shadow))
                    l10n.shadowActive
                  else
                    l10n.shadowResting,
                ].join(' · '),
              ),
            ),
        ],
      ),
    );
  }
}
