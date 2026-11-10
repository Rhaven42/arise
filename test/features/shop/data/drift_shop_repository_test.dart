import 'package:arise/features/inventory/data/drift_inventory_repository.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/progression/data/drift_progression_repository.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/shop/data/drift_shop_repository.dart';
import 'package:arise/features/shop/domain/shop_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('un achat débite et livre ensemble, un refus ne change rien', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    DateTime clock() => testNow;
    final progression = DriftProgressionRepository(database, clock);
    final inventory = DriftInventoryRepository(database, clock);
    final shop = DriftShopRepository(database, clock);
    final cape = ItemArticle(itemById('cape_wanderer')!);
    final price = priceOf(cape).bronzeTotal;

    await progression.save(
      ProgressionState.initial(const CivilDate(2026, 11, 4))
          .copyWith(coins: price + 70),
    );
    expect(await shop.buy(cape), isNull);
    expect((await progression.read())?.coins, 70);
    expect((await inventory.read()).owned, ['cape_wanderer']);

    expect(await shop.buy(cape), PurchaseIssue.alreadyOwned);
    expect(
      await shop.buy(ItemArticle(itemById('staff_ember')!)),
      PurchaseIssue.notEnoughCoins,
    );
    expect((await progression.read())?.coins, 70);

    expect(await shop.dye('cape_wanderer', 0xFF27406E), isNull);
    expect((await progression.read())?.coins, 20);
    expect((await inventory.read()).dyes, {'cape_wanderer': 0xFF27406E});
  });

  test('sans progression, rien ne peut être acheté', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final shop = DriftShopRepository(database, () => testNow);
    expect(
      await shop.buy(ItemArticle(itemById('leather_belt')!)),
      PurchaseIssue.notEnoughCoins,
    );
  });
}
