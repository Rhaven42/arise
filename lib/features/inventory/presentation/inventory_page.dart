import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/labeled_tag.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/inventory/presentation/inventory_labels.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/shop/presentation/shop_labels.dart';
import 'package:arise/features/shop/presentation/shop_providers.dart';
import 'package:arise/features/titles/presentation/titles_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inventaire : objets achetés, rangés par emplacement ; porter, retirer,
/// teindre.
class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  /// Liste des objets (repère pour les tests).
  static const listKey = Key('inventory-list');

  Future<void> _dye(
    BuildContext context,
    WidgetRef ref,
    EquipmentItem item,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final color = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AriseSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.inventoryDyeTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                l10n.inventoryDyeCost(
                  formatCoins(l10n, Coins(gameConfig.shop.dyeCostBronze)),
                ),
              ),
              const SizedBox(height: AriseSpacing.sm),
              Wrap(
                spacing: AriseSpacing.sm,
                runSpacing: AriseSpacing.sm,
                children: [
                  for (final dye in dyeColors)
                    Semantics(
                      button: true,
                      label: l10n.dyeColorName(dye.id),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(dye.color),
                        customBorder: const CircleBorder(),
                        child: Tooltip(
                          message: l10n.dyeColorName(dye.id),
                          child: Container(
                            width: AriseSpacing.minTouchTarget,
                            height: AriseSpacing.minTouchTarget,
                            decoration: BoxDecoration(
                              color: Color(dye.color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AriseColors.parchmentMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (color == null) return;
    final issue = await ref
        .read(shopControllerProvider.notifier)
        .dye(item.id, color);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            issue == null
                ? l10n.inventoryDyed
                : purchaseIssueLabel(l10n, issue),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inventory = ref.watch(inventoryProvider).value ?? const Inventory();
    final sheet = ref.watch(savedCharacterProvider).value;
    final aura = ref.watch(titlesViewProvider).value?.aura?.color;
    final controller = ref.read(inventoryControllerProvider.notifier);
    final owned = [
      for (final item in [...equipmentCatalog, ...bossRewardItems])
        if (inventory.owned.contains(item.id)) item,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryTitle),
        actions: [
          IconButton(
            tooltip: l10n.shopTitle,
            icon: const Icon(Icons.storefront_outlined),
            onPressed: () => context.go(AppRoutes.shop),
          ),
        ],
      ),
      body: Column(
        children: [
          if (sheet != null)
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.3,
              child: ref
                  .watch(characterRendererProvider)
                  .build(
                    // Aura portée (titres) autour du personnage.
                    appearance: CharacterAppearance.of(
                      sheet,
                      loadout: loadoutOf(inventory),
                    ).adorned(auraColor: aura),
                  ),
            ),
          Expanded(
            child: owned.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AriseSpacing.lg),
                      child: Text(
                        l10n.inventoryEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : CustomScrollView(
                    key: listKey,
                    slivers: [
                      for (final slot in usedSlots)
                        if (owned.any((i) => i.slot == slot)) ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AriseSpacing.md,
                              AriseSpacing.md,
                              AriseSpacing.md,
                              AriseSpacing.xs,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                slotLabel(l10n, slot),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AriseSpacing.sm,
                            ),
                            sliver: SliverGrid.extent(
                              maxCrossAxisExtent: 110,
                              mainAxisSpacing: AriseSpacing.sm,
                              crossAxisSpacing: AriseSpacing.sm,
                              childAspectRatio: 0.78,
                              children: [
                                for (final item in owned.where(
                                  (i) => i.slot == slot,
                                ))
                                  _ItemTile(
                                    item: item,
                                    equipped:
                                        inventory.equipped[slot] == item.id,
                                    dye: inventory.dyes[item.id],
                                    onTap: () => _openItem(
                                      context,
                                      ref,
                                      item,
                                      equipped:
                                          inventory.equipped[slot] == item.id,
                                      onToggle: () async {
                                        if (inventory.equipped[slot] ==
                                            item.id) {
                                          await controller.unequipSlot(slot);
                                        } else {
                                          await controller.equipItem(item.id);
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      const SliverToBoxAdapter(
                        child: SizedBox(height: AriseSpacing.lg),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Fiche d'un objet : porter ou retirer, teindre.
  Future<void> _openItem(
    BuildContext context,
    WidgetRef ref,
    EquipmentItem item, {
    required bool equipped,
    required Future<void> Function() onToggle,
  }) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AriseSpacing.md,
            0,
            AriseSpacing.md,
            AriseSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: _ItemImage(item: item),
                  ),
                  const SizedBox(width: AriseSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemLabel(l10n, item),
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AriseSpacing.xs),
                        LabeledTag(
                          icon: rarityIcon(item.rarity),
                          label: rarityLabel(l10n, item.rarity),
                          color: rarityColor(item.rarity),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AriseSpacing.md),
              Row(
                children: [
                  if (item.dyeable) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          unawaited(_dye(context, ref, item));
                        },
                        icon: const Icon(Icons.format_color_fill),
                        label: Text(l10n.inventoryDye),
                      ),
                    ),
                    const SizedBox(width: AriseSpacing.sm),
                  ],
                  Expanded(
                    child: equipped
                        ? OutlinedButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              unawaited(onToggle());
                            },
                            child: Text(l10n.inventoryUnequip),
                          )
                        : FilledButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              unawaited(onToggle());
                            },
                            child: Text(l10n.inventoryEquip),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vignette d'un objet (sprite en pixel art, `assets/sprites/icons/`).
class _ItemImage extends StatelessWidget {
  const _ItemImage({required this.item});

  final EquipmentItem item;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AriseColors.stoneDark,
      borderRadius: BorderRadius.circular(AriseSpacing.radius),
      border: Border.all(color: rarityColor(item.rarity), width: 2),
    ),
    padding: const EdgeInsets.all(AriseSpacing.xs),
    child: Image.asset(
      'assets/sprites/icons/${item.spriteId}.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) =>
          Icon(slotIcon(item.slot), color: rarityColor(item.rarity)),
    ),
  );
}

/// Vignette d'un objet possédé : image, nom, porté ou non, teinte.
class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.equipped,
    required this.dye,
    required this.onTap,
  });

  final EquipmentItem item;
  final bool equipped;
  final int? dye;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = dye;
    return Semantics(
      selected: equipped,
      child: Material(
        color: AriseColors.stone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AriseSpacing.radius),
          side: equipped
              ? const BorderSide(color: AriseColors.success, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AriseSpacing.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AriseSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _ItemImage(item: item)),
                      if (equipped)
                        const Positioned(
                          right: 2,
                          top: 2,
                          child: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AriseColors.success,
                          ),
                        ),
                      if (color != null)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AriseColors.parchmentMuted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AriseSpacing.xs),
                Text(
                  itemLabel(l10n, item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
