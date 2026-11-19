import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/shop/domain/shop_rules.dart';
import 'package:flutter_test/flutter_test.dart';

ItemArticle _article(String id) => ItemArticle(itemById(id)!);

void main() {
  test('prix : communs selon l’emplacement, puis par rareté', () {
    expect(priceOf(_article('sword_warden')), Coins.of(silver: 3));
    expect(priceOf(_article('awakened_leather')), Coins.of(silver: 8));
    expect(priceOf(_article('warden_mail')), Coins.of(silver: 10));
    expect(priceOf(_article('dawn_plate')), Coins.of(silver: 40));
    expect(priceOf(_article('golden_king')), Coins.of(gold: 1, silver: 50));
    expect(priceOf(_article('staff_ember')), Coins.of(gold: 5));
    expect(
      priceOf(const HairStyleArticle(8)),
      Coins.of(silver: gameConfig.shop.hairStylePriceSilver),
    );
  });

  test('chaque article de la boutique a un prix', () {
    for (final article in shopArticles()) {
      expect(priceOf(article).bronzeTotal, greaterThan(0));
    }
    // Les prix montent avec la rareté.
    final byRarity = [
      for (final r in Rarity.values.skip(1))
        gameConfig.shop.rarityPriceSilver[r.name]!,
    ];
    expect(byRarity, orderedEquals([...byRarity]..sort()));
  });

  test('achat : débit, livraison et refus', () {
    final price = priceOf(_article('warden_mail')).bronzeTotal;
    final ok = purchase(
      balance: price + 5,
      inventory: const Inventory(),
      article: _article('warden_mail'),
    );
    expect(ok.issue, isNull);
    expect(ok.balance, 5);
    expect(ok.inventory.owned, ['warden_mail']);

    final again = purchase(
      balance: ok.balance + price,
      inventory: ok.inventory,
      article: _article('warden_mail'),
    );
    expect(again.issue, PurchaseIssue.alreadyOwned);
    expect(again.balance, ok.balance + price);

    final poor = purchase(
      balance: price - 1,
      inventory: const Inventory(),
      article: _article('warden_mail'),
    );
    expect(poor.issue, PurchaseIssue.notEnoughCoins);
    expect(poor.inventory.owned, isEmpty);

    expect(
      purchase(
        balance: 1 << 30,
        inventory: const Inventory(),
        article: const HairStyleArticle(1),
      ).issue,
      PurchaseIssue.notForSale,
    );
    final hair = purchase(
      balance: 1 << 30,
      inventory: const Inventory(),
      article: const HairStyleArticle(8),
    );
    expect(hair.inventory.hairStyles, [8]);
  });

  test('teinture : objet teignable possédé, coût en bronze', () {
    final cost = gameConfig.shop.dyeCostBronze;
    const bag = Inventory(owned: ['wanderer_coat', 'sword_warden']);
    final ok = dyeItem(
      balance: cost,
      inventory: bag,
      itemId: 'wanderer_coat',
      color: 0xFF7A1E1E,
    );
    expect(ok.issue, isNull);
    expect(ok.balance, 0);
    expect(ok.inventory.dyes, {'wanderer_coat': 0xFF7A1E1E});
    expect(
      dyeItem(
        balance: cost,
        inventory: bag,
        itemId: 'sword_warden',
        color: 1,
      ).issue,
      PurchaseIssue.notForSale,
    );
    expect(
      dyeItem(
        balance: cost,
        inventory: bag,
        itemId: 'golden_king',
        color: 1,
      ).issue,
      PurchaseIssue.notOwned,
    );
    expect(
      dyeItem(
        balance: cost - 1,
        inventory: bag,
        itemId: 'wanderer_coat',
        color: 1,
      ).issue,
      PurchaseIssue.notEnoughCoins,
    );
  });
}
