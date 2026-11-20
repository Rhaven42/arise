import 'dart:convert';
import 'dart:io';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogue : identifiants uniques, tenues et armes dessinées', () {
    final ids = equipmentCatalog.map((i) => i.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(outfitCatalog, hasLength(33));
    expect(weaponCatalog, hasLength(12));
    final meta = jsonDecode(
      File('assets/sprites/sprites.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final gabarits = {
      for (final body in (meta['bodies'] as Map<String, dynamic>).values)
        (body as Map<String, dynamic>)['gabarit'],
    };
    for (final item in [...outfitCatalog, ...bossRewardItems]) {
      expect(item.slot, EquipmentSlot.chest);
      for (final g in gabarits) {
        expect(
          File('assets/sprites/outfits/${item.spriteId}_$g.png').existsSync(),
          isTrue,
          reason: '${item.id} $g',
        );
      }
      expect(
        File('assets/sprites/icons/${item.spriteId}.png').existsSync(),
        isTrue,
      );
    }
    expect(pieceCatalog, hasLength(20));
    final pieces = meta['pieces'] as Map<String, dynamic>;
    for (final item in pieceCatalog) {
      expect(pieceSlots, contains(item.slot));
      expect(pieces[item.id], item.slot.name, reason: item.id);
      for (final g in gabarits) {
        expect(
          File('assets/sprites/pieces/${item.id}_$g.png').existsSync(),
          isTrue,
          reason: '${item.id} $g',
        );
      }
      expect(File('assets/sprites/icons/${item.id}.png').existsSync(), isTrue);
    }
    for (final item in weaponCatalog) {
      expect(item.slot, EquipmentSlot.weapon);
      expect(
        (meta['weapons'] as Map<String, dynamic>).containsKey(item.id),
        isTrue,
      );
    }
    expect(itemById('inconnu'), isNull);
  });

  test('anciens objets : chaque remplaçant existe', () {
    for (final entry in legacyItemIds.entries) {
      expect(itemById(entry.value), isNotNull, reason: entry.key);
      expect(itemById(entry.key), isNull, reason: entry.key);
    }
    expect(currentItemId('plate_chest'), 'dawn_plate');
    expect(currentItemId('sword_dawn'), 'sword_dawn');
  });

  test('équiper : objet possédé, un seul par emplacement', () {
    const bag = Inventory(owned: ['awakened_leather', 'warden_mail']);
    expect(equip(bag, 'dawn_plate').issue, EquipIssue.notOwned);
    expect(equip(bag, 'inconnu').issue, EquipIssue.unknownItem);
    final first = equip(bag, 'awakened_leather').inventory;
    final second = equip(first, 'warden_mail').inventory;
    expect(second.equipped, {EquipmentSlot.chest: 'warden_mail'});
    expect(unequip(second, EquipmentSlot.chest).equipped, isEmpty);
  });

  test('tenue complète ou haut et bas, chaussures et gants avec tout', () {
    const bag = Inventory(
      owned: [
        'awakened_leather',
        'forest_jerkin',
        'iron_greaves',
        'riding_boots',
        'silk_gloves',
      ],
    );
    var inv = equip(bag, 'forest_jerkin').inventory;
    inv = equip(inv, 'iron_greaves').inventory;
    inv = equip(inv, 'riding_boots').inventory;
    inv = equip(inv, 'silk_gloves').inventory;
    expect(inv.equipped, hasLength(4));
    // La tenue complète retire le haut et le bas, pas les chaussures ni les
    // gants.
    inv = equip(inv, 'awakened_leather').inventory;
    expect(inv.equipped, {
      EquipmentSlot.chest: 'awakened_leather',
      EquipmentSlot.feet: 'riding_boots',
      EquipmentSlot.hands: 'silk_gloves',
    });
    // Un bas retire la tenue.
    inv = equip(inv, 'iron_greaves').inventory;
    expect(inv.equipped.containsKey(EquipmentSlot.chest), isFalse);
    expect(inv.equipped[EquipmentSlot.legs], 'iron_greaves');
  });

  test('pièces portées : ordre de dessin, teinture, essayage', () {
    const bag = Inventory(
      owned: ['forest_jerkin', 'iron_greaves', 'silk_gloves', 'dawn_plate'],
      equipped: {
        EquipmentSlot.hands: 'silk_gloves',
        EquipmentSlot.top: 'forest_jerkin',
        EquipmentSlot.legs: 'iron_greaves',
      },
      dyes: {'forest_jerkin': 0xFF7A1E1E},
    );
    final loadout = loadoutOf(bag);
    expect(loadout.outfitId, isNull);
    expect(loadout.pieces, const [
      WornPiece('iron_greaves'),
      WornPiece('forest_jerkin', 0xFF7A1E1E),
      WornPiece('silk_gloves'),
    ]);
    // Essayer une tenue complète masque le haut et le bas, garde les gants.
    final trying = loadoutOf(bag, tryOn: itemById('dawn_plate'));
    expect(trying.outfitId, 'dawn_plate');
    expect(trying.pieces, const [WornPiece('silk_gloves')]);
  });

  test('tenue affichée : sprite, teinture, arme, essayage', () {
    const bag = Inventory(
      owned: ['awakened_leather', 'sword_warden', 'comet_cape'],
      equipped: {
        EquipmentSlot.chest: 'awakened_leather',
        EquipmentSlot.weapon: 'sword_warden',
      },
      dyes: {'awakened_leather': 0xFF3E6B34},
    );
    final loadout = loadoutOf(bag);
    expect(loadout.outfitId, 'awakened_leather');
    expect(loadout.outfitTint, 0xFF3E6B34);
    expect(loadout.weaponId, 'sword_warden');

    final trying = loadoutOf(bag, tryOn: itemById('dawn_plate'));
    expect(trying.outfitId, 'dawn_plate');
    expect(trying.outfitTint, isNull);
    expect(trying.weaponId, 'sword_warden');

    // Objet exclusif : sprite de sa tenue de base, avec sa teinte.
    final reward = loadoutOf(bag, tryOn: itemById('comet_cape'));
    expect(reward.outfitId, 'golden_king');
    expect(reward.outfitTint, itemById('comet_cape')?.tint);
    expect(loadoutOf(const Inventory()).outfitId, isNull);
  });

  test('coiffures de la boutique', () {
    final locked = gameConfig.shop.lockedHairStyles.first;
    const empty = Inventory();
    expect(hairStyleAvailable(empty, 1), isTrue);
    expect(hairStyleAvailable(empty, locked), isFalse);
    expect(hairStyleAvailable(empty, locked, worn: locked), isTrue);
    expect(hairStyleAvailable(Inventory(hairStyles: [locked]), locked), isTrue);
    expect(
      availableHairStyles(empty, count: 14),
      hasLength(14 - gameConfig.shop.lockedHairStyles.length),
    );
  });

  test('nettoyage d’un inventaire relu : anciens objets convertis', () {
    final clean = sanitizeInventory(
      const Inventory(
        owned: [
          'leather_chest',
          'leather_belt',
          'inconnu',
          'peasant_tunic',
          'dagger_ice',
          'sword_dawn',
        ],
        hairStyles: [8, 6, 8],
        equipped: {
          EquipmentSlot.belt: 'leather_belt',
          EquipmentSlot.legs: 'inconnu',
          EquipmentSlot.weapon: 'dagger_ice',
        },
        dyes: {'leather_chest': 1, 'dagger_ice': 2},
      ),
    );
    expect(clean.owned, ['awakened_leather', 'dagger_desert', 'sword_dawn']);
    expect(clean.hairStyles, [6, 8]);
    expect(clean.equipped, {
      EquipmentSlot.chest: 'awakened_leather',
      EquipmentSlot.weapon: 'dagger_desert',
    });
    expect(clean.dyes, {'awakened_leather': 1});
  });

  test('l’inventaire se relit à l’identique en JSON', () {
    const bag = Inventory(
      owned: ['sword_dawn'],
      equipped: {EquipmentSlot.weapon: 'sword_dawn'},
    );
    expect(Inventory.fromJson(bag.toJson()), bag);
  });
}
