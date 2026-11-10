import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/progression/domain/coins.dart';

/// Article de la boutique : un objet ou une coiffure.
sealed class ShopArticle {
  const ShopArticle();
}

class ItemArticle extends ShopArticle {
  const ItemArticle(this.item);

  final EquipmentItem item;
}

class HairStyleArticle extends ShopArticle {
  const HairStyleArticle(this.style);

  final int style;
}

/// Prix d'un article.
Coins priceOf(ShopArticle article, {GameConfig? config}) {
  final c = config ?? gameConfig;
  final silver = switch (article) {
    ItemArticle(:final item) => item.rarity == Rarity.common
        ? c.shop.commonPriceSilverBySlot[item.slot.name]!
        : c.shop.rarityPriceSilver[item.rarity.name]!,
    HairStyleArticle() => c.shop.hairStylePriceSilver,
  };
  return Coins.of(silver: silver, config: c.coins);
}

/// L'article est-il déjà possédé ?
bool owns(Inventory inventory, ShopArticle article) => switch (article) {
  ItemArticle(:final item) => inventory.owned.contains(item.id),
  HairStyleArticle(:final style) => inventory.hairStyles.contains(style),
};

/// Raisons d'un refus d'achat.
enum PurchaseIssue {
  alreadyOwned,
  notEnoughCoins,

  /// Article absent de la boutique, ou objet qui ne se teint pas.
  notForSale,

  /// Teinture d'un objet qui n'a pas été acheté.
  notOwned,
}

/// Résultat d'un achat : nouveau solde (bronze) et inventaire, ou refus.
typedef PurchaseResult = ({
  int balance,
  Inventory inventory,
  PurchaseIssue? issue,
});

/// Achète un article avec les pièces du joueur. Aucun argent réel : seules
/// les pièces gagnées en jouant sont acceptées.
PurchaseResult purchase({
  required int balance,
  required Inventory inventory,
  required ShopArticle article,
  GameConfig? config,
}) {
  final c = config ?? gameConfig;
  PurchaseResult refuse(PurchaseIssue issue) =>
      (balance: balance, inventory: inventory, issue: issue);
  if (article is HairStyleArticle &&
      !c.shop.lockedHairStyles.contains(article.style)) {
    return refuse(PurchaseIssue.notForSale);
  }
  if (owns(inventory, article)) return refuse(PurchaseIssue.alreadyOwned);
  final price = priceOf(article, config: c).bronzeTotal;
  if (balance < price) return refuse(PurchaseIssue.notEnoughCoins);
  final next = switch (article) {
    ItemArticle(:final item) => inventory.copyWith(
      owned: [...inventory.owned, item.id],
    ),
    HairStyleArticle(:final style) => inventory.copyWith(
      hairStyles: [...inventory.hairStyles, style]..sort(),
    ),
  };
  return (balance: balance - price, inventory: next, issue: null);
}


/// Teint un objet possédé, pour quelques pièces de bronze.
PurchaseResult dyeItem({
  required int balance,
  required Inventory inventory,
  required String itemId,
  required int color,
  GameConfig? config,
}) {
  final c = config ?? gameConfig;
  final item = itemById(itemId);
  PurchaseResult refuse(PurchaseIssue issue) =>
      (balance: balance, inventory: inventory, issue: issue);
  if (item == null || !item.dyeable) return refuse(PurchaseIssue.notForSale);
  if (!inventory.owned.contains(itemId)) return refuse(PurchaseIssue.notOwned);
  final cost = c.shop.dyeCostBronze;
  if (balance < cost) return refuse(PurchaseIssue.notEnoughCoins);
  return (
    balance: balance - cost,
    inventory: inventory.copyWith(dyes: {...inventory.dyes, itemId: color}),
    issue: null,
  );
}

/// Articles en vente, dans l'ordre d'affichage.
List<ShopArticle> shopArticles({GameConfig? config}) => [
  for (final item in equipmentCatalog) ItemArticle(item),
  for (final style in (config ?? gameConfig).shop.lockedHairStyles)
    HairStyleArticle(style),
];
