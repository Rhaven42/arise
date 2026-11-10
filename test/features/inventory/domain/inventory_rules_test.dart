import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogue : identifiants uniques, trois ensembles complets', () {
    final ids = equipmentCatalog.map((i) => i.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final set in equipmentSets) {
      expect(equipmentCatalog.where((i) => i.setId == set), isNotEmpty);
    }
    for (final slot in EquipmentSlot.values) {
      expect(equipmentCatalog.where((i) => i.slot == slot), isNotEmpty);
    }
    expect(itemById('cape_dawn')?.slot, EquipmentSlot.back);
    expect(itemById('inconnu'), isNull);
  });

  test('équiper : objet possédé, un seul par emplacement', () {
    const bag = Inventory(owned: ['leather_chest', 'mail_chest']);
    expect(equip(bag, 'plate_chest').issue, EquipIssue.notOwned);
    expect(equip(bag, 'inconnu').issue, EquipIssue.unknownItem);
    final first = equip(bag, 'leather_chest').inventory;
    final second = equip(first, 'mail_chest').inventory;
    expect(second.equipped, {EquipmentSlot.chest: 'mail_chest'});
    expect(unequip(second, EquipmentSlot.chest).equipped, isEmpty);
  });

  test('tenue affichée : pièces masquées, teinture, coiffure cachée', () {
    const bag = Inventory(
      owned: ['leather_chest', 'mail_head', 'cape_wanderer'],
      equipped: {
        EquipmentSlot.chest: 'leather_chest',
        EquipmentSlot.back: 'cape_wanderer',
      },
      dyes: {'cape_wanderer': 0xFF3E6B34},
    );
    final loadout = loadoutOf(bag);
    expect(loadout.itemNodes, ['item_leather_chest', 'item_cape_wanderer']);
    expect(loadout.hiddenOutfit, ['outfit_tunic', 'outfit_tunic_skirt']);
    expect(loadout.dyes, {'dye_cape_wanderer': 0xFF3E6B34});
    expect(loadout.hidesHair, isFalse);

    final trying = loadoutOf(bag, tryOn: itemById('mail_head'));
    expect(trying.hidesHair, isTrue);
    expect(trying.itemNodes, contains('item_mail_head'));
    // L'essayage remplace l'objet du même emplacement.
    final swap = loadoutOf(bag, tryOn: itemById('plate_chest'));
    expect(swap.itemNodes, isNot(contains('item_leather_chest')));
  });

  test('coiffures de la boutique', () {
    final locked = gameConfig.shop.lockedHairStyles.first;
    const empty = Inventory();
    expect(hairStyleAvailable(empty, 1), isTrue);
    expect(hairStyleAvailable(empty, locked), isFalse);
    expect(hairStyleAvailable(empty, locked, worn: locked), isTrue);
    expect(
      hairStyleAvailable(Inventory(hairStyles: [locked]), locked),
      isTrue,
    );
    expect(
      availableHairStyles(empty, count: 10),
      hasLength(10 - gameConfig.shop.lockedHairStyles.length),
    );
  });

  test('nettoyage d’un inventaire relu', () {
    final clean = sanitizeInventory(
      const Inventory(
        owned: ['leather_belt', 'leather_belt', 'inconnu', 'cape_dawn'],
        hairStyles: [8, 6, 8],
        equipped: {
          EquipmentSlot.belt: 'leather_belt',
          EquipmentSlot.head: 'cape_dawn',
          EquipmentSlot.weapon: 'sword_dawn',
        },
        dyes: {'leather_belt': 1, 'cape_dawn': 2, 'cape_wanderer': 3},
      ),
    );
    expect(clean.owned, ['leather_belt', 'cape_dawn']);
    expect(clean.hairStyles, [6, 8]);
    expect(clean.equipped, {EquipmentSlot.belt: 'leather_belt'});
    expect(clean.dyes, {'cape_dawn': 2});
  });

  test('l’inventaire se relit à l’identique en JSON', () {
    const bag = Inventory(
      owned: ['sword_dawn'],
      equipped: {EquipmentSlot.weapon: 'sword_dawn'},
    );
    expect(Inventory.fromJson(bag.toJson()), bag);
  });
}
