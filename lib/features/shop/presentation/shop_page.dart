import 'dart:async';

import 'package:arise/core/design_system/widgets/choice_chip_row.dart';
import 'package:arise/core/design_system/widgets/labeled_tag.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/achievements/presentation/achievements_providers.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/equipment_filter.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/inventory/presentation/inventory_labels.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/presentation/progression_labels.dart';
import 'package:arise/features/progression/presentation/progression_providers.dart';
import 'package:arise/features/shop/domain/shop_rules.dart';
import 'package:arise/features/shop/presentation/shop_labels.dart';
import 'package:arise/features/shop/presentation/shop_providers.dart';
import 'package:arise/features/worlds/domain/world.dart';
import 'package:arise/features/worlds/presentation/world_labels.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Boutique : essayage sur le personnage, achat en pièces après
/// confirmation. Aucun argent réel.
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  /// Liste des articles (repère pour les tests).
  static const listKey = Key('shop-list');

  /// Filtres par emplacement (repère pour les tests).
  static const filtersKey = Key('shop-filters');

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  /// Univers, matière et emplacement filtrés ; [_hairFilter] = coiffures.
  EquipmentFilter _filter = const EquipmentFilter();
  bool _hairFilter = false;

  Future<void> _buy(ShopArticle article, Coins price) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = articleLabel(l10n, article);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shopConfirmTitle),
        content: Text(l10n.shopConfirmBody(name, formatCoins(l10n, price))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.shopCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.shopBuy),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final issue = await ref.read(shopControllerProvider.notifier).buy(article);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            issue == null
                ? l10n.shopBought(name)
                : purchaseIssueLabel(l10n, issue),
          ),
        ),
      );
  }

  Future<void> _showOnCharacter(
    ShopArticle article,
    CharacterSheet sheet,
    Inventory inventory,
  ) {
    // Page plein écran : le héros en grand, avec l'article porté.
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            _TryOnView(article: article, sheet: sheet, inventory: inventory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inventory = ref.watch(inventoryProvider).value ?? const Inventory();
    final wallet =
        ref.watch(progressionControllerProvider).value?.state.wallet ??
        Coins.zero;
    final sheet = ref.watch(savedCharacterProvider).value;
    final achievements = {
      ...?ref.watch(achievementsStateProvider).value?.unlocked.keys,
    };
    final articles = [
      for (final article in shopArticles())
        if (_matches(article)) article,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AriseSpacing.md,
              vertical: AriseSpacing.xs,
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                l10n.shopWallet(formatCoins(l10n, wallet)),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Column(
            key: ShopPage.filtersKey,
            children: [
              ChoiceChipRow<String>(
                title: l10n.filterSlot,
                allLabel: l10n.shopAll,
                options: [
                  for (final slot in usedSlots)
                    ChipOption(slot.name, slotLabel(l10n, slot)),
                  ChipOption(_hairKind, l10n.shopHairStyles),
                ],
                selected: _hairFilter ? _hairKind : _filter.slot?.name,
                onChanged: (kind) => setState(() {
                  _hairFilter = kind == _hairKind;
                  _filter = _filter.withSlot(
                    usedSlots.where((s) => s.name == kind).firstOrNull,
                  );
                }),
              ),
              if (!_hairFilter) ...[
                ChoiceChipRow<World>(
                  title: l10n.filterWorld,
                  allLabel: l10n.filterAllWorlds,
                  options: [
                    for (final world in World.values)
                      ChipOption(world, worldLabel(l10n, world)),
                  ],
                  selected: _filter.world,
                  onChanged: (world) =>
                      setState(() => _filter = _filter.withWorld(world)),
                ),
                if (_filter.slot != EquipmentSlot.weapon)
                  ChoiceChipRow<EquipmentMaterial>(
                    title: l10n.filterMaterial,
                    allLabel: l10n.filterAllMaterials,
                    options: [
                      for (final material in EquipmentMaterial.values)
                        ChipOption(material, materialLabel(l10n, material)),
                    ],
                    selected: _filter.material,
                    onChanged: (material) => setState(
                      () => _filter = _filter.withMaterial(material),
                    ),
                  ),
              ],
            ],
          ),
          Expanded(
            child: CustomScrollView(
              key: ShopPage.listKey,
              slivers: [
                if (sheet == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AriseSpacing.sm),
                      child: Text(
                        l10n.shopNoCharacter,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (articles.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AriseSpacing.lg),
                      child: Text(
                        l10n.filterNoResult,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.all(AriseSpacing.sm),
                  sliver: SliverGrid.extent(
                    maxCrossAxisExtent: 130,
                    mainAxisSpacing: AriseSpacing.sm,
                    crossAxisSpacing: AriseSpacing.sm,
                    childAspectRatio: 0.72,
                    children: [
                      for (final article in articles)
                        _ArticleTile(
                          article: article,
                          owned: owns(inventory, article),
                          locked:
                              missingAchievement(article, achievements) != null,
                          price: priceOf(article),
                          onTap: () => _openArticle(
                            article,
                            owned: owns(inventory, article),
                            lockedBy: missingAchievement(article, achievements),
                            sheet: sheet,
                            inventory: inventory,
                          ),
                        ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AriseSpacing.md),
                    child: Text(
                      l10n.shopNoRealMoney,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fiche d'un article : détails, essayage et achat.
  Future<void> _openArticle(
    ShopArticle article, {
    required bool owned,
    required String? lockedBy,
    required CharacterSheet? sheet,
    required Inventory inventory,
  }) {
    final price = priceOf(article);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _ArticleSheet(
        article: article,
        owned: owned,
        lockedBy: lockedBy,
        price: price,
        onTryOn: sheet == null
            ? null
            : () => _showOnCharacter(article, sheet, inventory),
        onBuy: () {
          Navigator.of(sheetContext).pop();
          unawaited(_buy(article, price));
        },
      ),
    );
  }

  static const _hairKind = 'hair';

  bool _matches(ShopArticle article) => switch (article) {
    ItemArticle(:final item) => !_hairFilter && _filter.matches(item),
    HairStyleArticle() => _hairFilter || _filter.isEmpty,
  };
}

/// Grande vue : le personnage enregistré porte l'article, par-dessus sa
/// tenue (sans achat).
class _TryOnView extends ConsumerWidget {
  const _TryOnView({
    required this.article,
    required this.sheet,
    required this.inventory,
  });

  final ShopArticle article;
  final CharacterSheet sheet;
  final Inventory inventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final article = this.article;
    final shown = article is HairStyleArticle
        ? sheet.copyWith(hairStyle: article.style)
        : sheet;
    final appearance = CharacterAppearance.of(
      shown,
      loadout: loadoutOf(
        inventory,
        tryOn: article is ItemArticle ? article.item : null,
      ),
    );
    final name = sheet.name.isEmpty ? l10n.characterTitle : sheet.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shopPreviewTitle(name)),
        leading: IconButton(
          tooltip: l10n.shopClose,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AriseSpacing.sm),
            child: Text(
              articleLabel(l10n, article),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ref
                .watch(characterRendererProvider)
                .build(appearance: appearance),
          ),
          Padding(
            padding: const EdgeInsets.all(AriseSpacing.md),
            child: Text(
              l10n.shopPreviewHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Vignette de l'objet seul (sprite en pixel art, `assets/sprites/icons/`).
class _ArticleImage extends StatelessWidget {
  const _ArticleImage({required this.article, required this.rarity});

  final ShopArticle article;
  final Rarity rarity;

  static String assetOf(ShopArticle article) => switch (article) {
    ItemArticle(:final item) => 'assets/sprites/icons/${item.spriteId}.png',
    HairStyleArticle(:final style) =>
      'assets/sprites/icons/hairstyle_${style.toString().padLeft(2, '0')}.png',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      image: true,
      label: l10n.shopItemImage(articleLabel(l10n, article)),
      child: Container(
        decoration: BoxDecoration(
          color: AriseColors.stoneDark,
          borderRadius: BorderRadius.circular(AriseSpacing.radius),
          border: Border.all(color: rarityColor(rarity), width: 2),
        ),
        padding: const EdgeInsets.all(AriseSpacing.xs),
        child: Image.asset(
          assetOf(article),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }
}

/// Vignette d'un article : image, nom et prix (ou état).
class _ArticleTile extends StatelessWidget {
  const _ArticleTile({
    required this.article,
    required this.owned,
    required this.locked,
    required this.price,
    required this.onTap,
  });

  final ShopArticle article;
  final bool owned;
  final bool locked;
  final Coins price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final rarity = _rarityOf(article);
    return Material(
      color: AriseColors.stone,
      borderRadius: BorderRadius.circular(AriseSpacing.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AriseSpacing.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AriseSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ArticleImage(article: article, rarity: rarity),
              ),
              const SizedBox(height: AriseSpacing.xs),
              Text(
                articleLabel(l10n, article),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.labelMedium,
              ),
              const SizedBox(height: 2),
              if (owned)
                _Status(
                  icon: Icons.check,
                  label: l10n.shopOwned,
                  color: AriseColors.success,
                )
              else if (locked)
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AriseColors.parchmentMuted,
                )
              else
                Text(
                  formatCoins(l10n, price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: AriseColors.goldBright,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 2),
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    ],
  );
}

Rarity _rarityOf(ShopArticle article) => switch (article) {
  ItemArticle(:final item) => item.rarity,
  HairStyleArticle() => Rarity.rare,
};

/// Fiche d'un article : grande image, rareté et emplacement, prix,
/// essayage et achat.
class _ArticleSheet extends StatelessWidget {
  const _ArticleSheet({
    required this.article,
    required this.owned,
    required this.lockedBy,
    required this.price,
    required this.onTryOn,
    required this.onBuy,
  });

  final ShopArticle article;
  final bool owned;
  final String? lockedBy;
  final Coins price;
  final VoidCallback? onTryOn;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final rarity = _rarityOf(article);
    final (icon, slot) = switch (article) {
      ItemArticle(:final item) => (
        slotIcon(item.slot),
        slotLabel(l10n, item.slot),
      ),
      HairStyleArticle() => (Icons.content_cut, l10n.shopHairStyles),
    };
    return SafeArea(
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
                  width: 96,
                  height: 96,
                  child: _ArticleImage(article: article, rarity: rarity),
                ),
                const SizedBox(width: AriseSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        articleLabel(l10n, article),
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AriseSpacing.xs),
                      Wrap(
                        spacing: AriseSpacing.sm,
                        runSpacing: AriseSpacing.xs,
                        children: [
                          LabeledTag(
                            icon: rarityIcon(rarity),
                            label: rarityLabel(l10n, rarity),
                            color: rarityColor(rarity),
                          ),
                          LabeledTag(
                            icon: icon,
                            label: slot,
                            color: AriseColors.parchmentMuted,
                          ),
                        ],
                      ),
                      const SizedBox(height: AriseSpacing.xs),
                      Text(l10n.shopPrice(formatCoins(l10n, price))),
                    ],
                  ),
                ),
              ],
            ),
            if (lockedBy case final achievement? when !owned) ...[
              const SizedBox(height: AriseSpacing.sm),
              LabeledTag(
                icon: Icons.lock_outline,
                label: l10n.shopLockedBy(l10n.achievementName(achievement)),
                color: AriseColors.parchmentMuted,
              ),
            ],
            const SizedBox(height: AriseSpacing.md),
            Row(
              children: [
                if (onTryOn != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTryOn,
                      icon: const Icon(Icons.accessibility_new),
                      label: Text(l10n.shopTryOn),
                    ),
                  ),
                if (onTryOn != null) const SizedBox(width: AriseSpacing.sm),
                Expanded(
                  child: owned
                      ? Center(
                          child: LabeledTag(
                            icon: Icons.check,
                            label: l10n.shopOwned,
                            color: AriseColors.success,
                          ),
                        )
                      : FilledButton(
                          onPressed: lockedBy == null ? onBuy : null,
                          child: Text(l10n.shopBuy),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
