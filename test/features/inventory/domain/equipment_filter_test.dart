import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/equipment_filter.dart';
import 'package:arise/features/worlds/domain/world.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final all = [...equipmentCatalog, ...bossRewardItems];

  test('sans critère, tout passe ; un seul emplacement, tous ses objets', () {
    expect(all.where(const EquipmentFilter().matches), hasLength(all.length));
    const gloves = EquipmentFilter(slot: EquipmentSlot.hands);
    expect(
      all.where(gloves.matches).map((i) => i.id),
      unorderedEquals([
        for (final i in all)
          if (i.slot == EquipmentSlot.hands) i.id,
      ]),
    );
  });

  test('univers et matière se combinent', () {
    const filter = EquipmentFilter(
      world: World.sea,
      material: EquipmentMaterial.leather,
    );
    final found = all.where(filter.matches).toList();
    expect(found, isNotEmpty);
    for (final item in found) {
      expect(item.world, World.sea);
      expect(item.material, EquipmentMaterial.leather);
    }
  });

  test('chaque tenue et pièce a une matière, jamais une arme', () {
    for (final item in all) {
      expect(
        item.material == null,
        item.slot == EquipmentSlot.weapon,
        reason: item.id,
      );
    }
  });

  test('chaque univers a ses objets, verrouillés par son haut fait', () {
    for (final world in World.values) {
      final items = all.where((i) => i.world == world).toList();
      expect(items, isNotEmpty, reason: world.name);
      for (final item in items) {
        expect(item.unlockAchievement, world.unlockAchievement);
      }
    }
    expect(isWorldUnlocked(World.medieval, const {}), isTrue);
    expect(isWorldUnlocked(World.north, const {}), isFalse);
    expect(isWorldUnlocked(World.north, const {'realm_north'}), isTrue);
  });
}
