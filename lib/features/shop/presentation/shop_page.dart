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
  ShopArticle? _tryOn;

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
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          issue == null
              ? l10n.shopBought(name)
              : purchaseIssueLabel(l10n, issue),
        ),
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
          _TryOnPreview(sheet: sheet, inventory: inventory, tryOn: _tryOn),
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
                    trying: _sameArticle(article, _tryOn),
                    price: priceOf(article),
                    onTryOn: sheet == null
                        ? null
                        : () => setState(
                            () => _tryOn = _sameArticle(article, _tryOn)
                                ? null
                                : article,
                          ),
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

  static bool _sameArticle(ShopArticle a, ShopArticle? b) => switch ((a, b)) {
    (ItemArticle(item: final x), ItemArticle(item: final y)) => x.id == y.id,
    (HairStyleArticle(style: final x), HairStyleArticle(style: final y)) =>
      x == y,
    _ => false,
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

/// Personnage enregistré, avec l'article essayé par-dessus sa tenue.
class _TryOnPreview extends ConsumerWidget {
  const _TryOnPreview({
    required this.sheet,
    required this.inventory,
    required this.tryOn,
  });

  final CharacterSheet? sheet;
  final Inventory inventory;
  final ShopArticle? tryOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final height = MediaQuery.sizeOf(context).height * 0.3;
    final base = sheet;
    if (base == null) {
      return SizedBox(
        height: height / 2,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AriseSpacing.md),
            child: Text(l10n.shopNoCharacter, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    final article = tryOn;
    final shown = article is HairStyleArticle
        ? base.copyWith(hairStyle: article.style)
        : base;
    final appearance = CharacterAppearance.of(
      shown,
      loadout: loadoutOf(
        inventory,
        tryOn: article is ItemArticle ? article.item : null,
      ),
    );
    return SizedBox(
      height: height,
      child: ref.watch(characterRendererProvider).build(appearance: appearance),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({
    required this.article,
    required this.owned,
    required this.trying,
    required this.price,
    required this.onTryOn,
    required this.onBuy,
  });

  final ShopArticle article;
  final bool owned;
  final bool trying;
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
      color: trying ? AriseColors.stoneLight : null,
      child: Padding(
        padding: const EdgeInsets.all(AriseSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: rarityColor(rarity)),
                const SizedBox(width: AriseSpacing.sm),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onTryOn != null)
                  TextButton.icon(
                    onPressed: onTryOn,
                    icon: Icon(
                      trying ? Icons.visibility : Icons.visibility_outlined,
                    ),
                    label: Text(trying ? l10n.shopTryingOn : l10n.shopTryOn),
                  ),
                const SizedBox(width: AriseSpacing.sm),
                if (owned)
                  LabeledTag(
                    icon: Icons.check,
                    label: l10n.shopOwned,
                    color: AriseColors.success,
                  )
                else
                  FilledButton(onPressed: onBuy, child: Text(l10n.shopBuy)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
