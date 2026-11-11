import 'package:arise/core/design_system/widgets/labeled_tag.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
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
  /// Emplacement filtré ; `null` = tout ; [_hairFilter] = coiffures.
  EquipmentSlot? _slot;
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
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: _TryOnView(article: article, sheet: sheet, inventory: inventory),
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
          SizedBox(
            height: 48,
            child: ListView(
              key: ShopPage.filtersKey,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AriseSpacing.md),
              children: [
                _FilterChip(
                  label: l10n.shopAll,
                  selected: _slot == null && !_hairFilter,
                  onSelected: () => setState(() {
                    _slot = null;
                    _hairFilter = false;
                  }),
                ),
                for (final slot in EquipmentSlot.values)
                  _FilterChip(
                    label: slotLabel(l10n, slot),
                    selected: _slot == slot,
                    onSelected: () => setState(() {
                      _slot = slot;
                      _hairFilter = false;
                    }),
                  ),
                _FilterChip(
                  label: l10n.shopHairStyles,
                  selected: _hairFilter,
                  onSelected: () => setState(() {
                    _slot = null;
                    _hairFilter = true;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: ShopPage.listKey,
              padding: const EdgeInsets.all(AriseSpacing.sm),
              children: [
                for (final article in articles)
                  _ArticleTile(
                    article: article,
                    owned: owns(inventory, article),
                    price: priceOf(article),
                    onTryOn: sheet == null
                        ? null
                        : () => _showOnCharacter(article, sheet, inventory),
                    onBuy: () => _buy(article, priceOf(article)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AriseSpacing.md),
                  child: Text(
                    l10n.shopNoRealMoney,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(ShopArticle article) => switch (article) {
    ItemArticle(:final item) =>
      !_hairFilter && (_slot == null || item.slot == _slot),
    HairStyleArticle() => _hairFilter || _slot == null,
  };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AriseSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

/// Grande vue 3D : le personnage enregistré porte l'article, par-dessus sa
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

/// Vignette de l'objet seul (rendue hors application, `assets/items/`).
class _ArticleImage extends StatelessWidget {
  const _ArticleImage({required this.article, required this.rarity});

  final ShopArticle article;
  final Rarity rarity;

  static String assetOf(ShopArticle article) => switch (article) {
    ItemArticle(:final item) => 'assets/items/${item.id}.png',
    HairStyleArticle(:final style) =>
      'assets/items/hairstyle_${style.toString().padLeft(2, '0')}.png',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      image: true,
      label: l10n.shopItemImage(articleLabel(l10n, article)),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AriseColors.stoneDark,
          borderRadius: BorderRadius.circular(AriseSpacing.radius),
          border: Border.all(color: rarityColor(rarity), width: 2),
        ),
        padding: const EdgeInsets.all(AriseSpacing.xs),
        child: Image.asset(
          assetOf(article),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({
    required this.article,
    required this.owned,
    required this.price,
    required this.onTryOn,
    required this.onBuy,
  });

  final ShopArticle article;
  final bool owned;
  final Coins price;
  final VoidCallback? onTryOn;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (rarity, icon, subtitle) = switch (article) {
      ItemArticle(:final item) => (
        item.rarity,
        slotIcon(item.slot),
        [
          slotLabel(l10n, item.slot),
          if (item.setId != null) l10n.equipmentSetName(item.setId!),
        ].join(' · '),
      ),
      HairStyleArticle() => (
        Rarity.rare,
        Icons.content_cut,
        l10n.shopHairStyles,
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AriseSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArticleImage(article: article, rarity: rarity),
            const SizedBox(width: AriseSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: rarityColor(rarity)),
                      const SizedBox(width: AriseSpacing.xs),
                      Expanded(
                        child: Text(
                          articleLabel(l10n, article),
                          style: Theme.of(context).textTheme.titleSmall,
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
                        icon: rarityIcon(rarity),
                        label: rarityLabel(l10n, rarity),
                        color: rarityColor(rarity),
                      ),
                      Text(subtitle),
                      Text(l10n.shopPrice(formatCoins(l10n, price))),
                    ],
                  ),
                  const SizedBox(height: AriseSpacing.xs),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AriseSpacing.sm,
                    runSpacing: AriseSpacing.xs,
                    children: [
                      if (onTryOn != null)
                        TextButton.icon(
                          onPressed: onTryOn,
                          icon: const Icon(Icons.accessibility_new),
                          label: Text(l10n.shopTryOn),
                        ),
                      if (owned)
                        LabeledTag(
                          icon: Icons.check,
                          label: l10n.shopOwned,
                          color: AriseColors.success,
                        )
                      else
                        FilledButton(
                          onPressed: onBuy,
                          child: Text(l10n.shopBuy),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
