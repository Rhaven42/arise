import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/worlds/domain/world.dart';

/// Filtre de la boutique et du sac : univers, matière et emplacement.
/// Un critère `null` ne filtre rien : sans aucun choix, tout s'affiche ;
/// avec seulement « Gants », tous les gants de tous les univers.
class EquipmentFilter {
  const EquipmentFilter({this.world, this.material, this.slot});

  final World? world;
  final EquipmentMaterial? material;
  final EquipmentSlot? slot;

  /// Aucun critère choisi.
  bool get isEmpty => world == null && material == null && slot == null;

  bool matches(EquipmentItem item) =>
      (world == null || item.world == world) &&
      (material == null || item.material == material) &&
      (slot == null || item.slot == slot);

  EquipmentFilter withWorld(World? value) =>
      EquipmentFilter(world: value, material: material, slot: slot);

  EquipmentFilter withMaterial(EquipmentMaterial? value) =>
      EquipmentFilter(world: world, material: value, slot: slot);

  EquipmentFilter withSlot(EquipmentSlot? value) =>
      EquipmentFilter(world: world, material: material, slot: value);
}
