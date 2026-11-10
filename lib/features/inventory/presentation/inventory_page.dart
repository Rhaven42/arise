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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          issue == null ? l10n.inventoryDyed : purchaseIssueLabel(l10n, issue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inventory = ref.watch(inventoryProvider).value ?? const Inventory();
    final sheet = ref.watch(savedCharacterProvider).value;
    final controller = ref.read(inventoryControllerProvider.notifier);
    final owned = [
      for (final item in equipmentCatalog)
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
                    appearance: CharacterAppearance.of(
                      sheet,
                      loadout: loadoutOf(inventory),
                    ),
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
                : ListView(
                    key: listKey,
                    padding: const EdgeInsets.all(AriseSpacing.sm),
                    children: [
                      for (final slot in EquipmentSlot.values)
                        if (owned.any((i) => i.slot == slot)) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AriseSpacing.sm,
                              AriseSpacing.md,
                              AriseSpacing.sm,
                              AriseSpacing.xs,
                            ),
                            child: Text(
                              slotLabel(l10n, slot),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          for (final item in owned.where((i) => i.slot == slot))
                            _ItemTile(
                              item: item,
                              equipped: inventory.equipped[slot] == item.id,
                              dye: inventory.dyes[item.id],
                              onToggle: () async {
                                if (inventory.equipped[slot] == item.id) {
                                  await controller.unequipSlot(slot);
                                } else {
                                  await controller.equipItem(item.id);
                                }
                              },
                              onDye: item.dyeable
                                  ? () => _dye(context, ref, item)
                                  : null,
                            ),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.equipped,
    required this.dye,
    required this.onToggle,
    required this.onDye,
  });

  final EquipmentItem item;
  final bool equipped;
  final int? dye;
  final VoidCallback onToggle;
  final VoidCallback? onDye;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = dye;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AriseSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(slotIcon(item.slot), color: rarityColor(item.rarity)),
                const SizedBox(width: AriseSpacing.sm),
                Expanded(
                  child: Text(
                    itemLabel(l10n, item),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (color != null)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(color: AriseColors.parchmentMuted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AriseSpacing.xs),
            Wrap(
              spacing: AriseSpacing.md,
              runSpacing: AriseSpacing.xs,
              children: [
                LabeledTag(
                  icon: rarityIcon(item.rarity),
                  label: rarityLabel(l10n, item.rarity),
                  color: rarityColor(item.rarity),
                ),
                if (equipped)
                  LabeledTag(
                    icon: Icons.check,
                    label: l10n.inventoryEquipped,
                    color: AriseColors.success,
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDye != null)
                  TextButton.icon(
                    onPressed: onDye,
                    icon: const Icon(Icons.format_color_fill),
                    label: Text(l10n.inventoryDye),
                  ),
                const SizedBox(width: AriseSpacing.sm),
                if (equipped)
                  OutlinedButton(
                    onPressed: onToggle,
                    child: Text(l10n.inventoryUnequip),
                  )
                else
                  FilledButton(
                    onPressed: onToggle,
                    child: Text(l10n.inventoryEquip),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
