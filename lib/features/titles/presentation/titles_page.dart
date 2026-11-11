import 'dart:async';

import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:arise/features/titles/presentation/titles_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Choix du titre affiché sous le nom et de l'aura du personnage.
class TitlesPage extends ConsumerWidget {
  const TitlesPage({super.key});

  static Key titleKey(String? id) => Key('title-${id ?? 'none'}');
  static Key auraKey(String? id) => Key('aura-${id ?? 'none'}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final view = ref.watch(titlesViewProvider).value;
    final sheet = ref.watch(savedCharacterProvider).value;
    final inventory = ref.watch(inventoryProvider).value ?? const Inventory();
    final controller = ref.read(titlesControllerProvider.notifier);
    if (view == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.titlesTitle)),
        body: const Center(
          child: CircularProgressIndicator(color: AriseColors.gold),
        ),
      );
    }
    final worn = view.worn;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.titlesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          if (sheet != null)
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.3,
              child: ref
                  .watch(characterRendererProvider)
                  .build(
                    appearance: CharacterAppearance.of(
                      sheet,
                      loadout: loadoutOf(inventory),
                    ).adorned(auraColor: view.aura?.color),
                  ),
            ),
          Text(l10n.titlesHint, style: textTheme.bodyMedium),
          const SizedBox(height: AriseSpacing.md),
          Text(l10n.titlesTitle, style: textTheme.titleLarge),
          if (view.earned.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AriseSpacing.sm),
              child: Text(l10n.titlesNone, style: textTheme.bodyLarge),
            )
          else
            RadioGroup<String?>(
              groupValue: worn.equippedTitle,
              onChanged: (id) => unawaited(controller.equipTitle(id)),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    key: titleKey(null),
                    value: null,
                    title: Text(l10n.titlesWearNone),
                  ),
                  for (final id in view.earned)
                    RadioListTile<String?>(
                      key: titleKey(id),
                      value: id,
                      title: Text(l10n.titleName(id)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AriseSpacing.md),
          Text(l10n.aurasSection, style: textTheme.titleLarge),
          if (view.auras.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AriseSpacing.sm),
              child: Text(l10n.aurasNone, style: textTheme.bodyLarge),
            )
          else
            RadioGroup<String?>(
              groupValue: worn.equippedAura,
              onChanged: (id) => unawaited(controller.equipAura(id)),
              child: Column(
                children: [
                  RadioListTile<String?>(
                    key: auraKey(null),
                    value: null,
                    title: Text(l10n.auraWearNone),
                  ),
                  for (final aura in view.auras)
                    RadioListTile<String?>(
                      key: auraKey(aura.id),
                      value: aura.id,
                      title: Text(l10n.auraName(aura.id)),
                      subtitle: Text(
                        l10n.auraUnlockedBy(l10n.titleName(aura.titleId)),
                      ),
                      secondary: Icon(
                        Icons.blur_circular,
                        color: Color(aura.color),
                        semanticLabel: l10n.auraName(aura.id),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
