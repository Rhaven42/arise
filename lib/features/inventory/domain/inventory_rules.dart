import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';

/// Teinte de teinture (identifiant stable + couleur ARGB).
class DyeColor {
  const DyeColor(this.id, this.color);

  final String id;
  final int color;
}

/// Teintes proposées pour la teinture.
const List<DyeColor> dyeColors = [
  DyeColor('crimson', 0xFF7A1E1E),
  DyeColor('rust', 0xFFB4502A),
  DyeColor('ochre', 0xFFC8A040),
  DyeColor('forest', 0xFF3E6B34),
  DyeColor('teal', 0xFF2E5E6E),
  DyeColor('night', 0xFF27406E),
  DyeColor('amethyst', 0xFF5A3A7A),
  DyeColor('umber', 0xFF3A2A1E),
  DyeColor('charcoal', 0xFF2A2A2E),
  DyeColor('linen', 0xFFD8D0C0),
];

/// Raisons d'un refus d'équipement.
enum EquipIssue { notOwned, unknownItem }

/// Porte un objet possédé, à la place de celui de son emplacement.
({Inventory inventory, EquipIssue? issue}) equip(
  Inventory inventory,
  String itemId,
) {
  final item = itemById(itemId);
  if (item == null) {
    return (inventory: inventory, issue: EquipIssue.unknownItem);
  }
  if (!inventory.owned.contains(itemId)) {
    return (inventory: inventory, issue: EquipIssue.notOwned);
  }
  return (
    inventory: inventory.copyWith(
      equipped: {...inventory.equipped, item.slot: itemId},
    ),
    issue: null,
  );
}

/// Retire l'objet d'un emplacement.
Inventory unequip(Inventory inventory, EquipmentSlot slot) =>
    inventory.copyWith(equipped: {...inventory.equipped}..remove(slot));

/// La coiffure est-elle utilisable ? Les coiffures vendues doivent avoir été
/// achetées, sauf celle déjà portée par le personnage enregistré.
bool hairStyleAvailable(
  Inventory inventory,
  int style, {
  int? worn,
  ShopConfig? config,
}) {
  final locked = (config ?? gameConfig.shop).lockedHairStyles;
  return !locked.contains(style) ||
      inventory.hairStyles.contains(style) ||
      style == worn;
}

/// Coiffures utilisables (pour le tirage aléatoire).
List<int> availableHairStyles(
  Inventory inventory, {
  required int count,
  int? worn,
  ShopConfig? config,
}) => [
  for (var i = 1; i <= count; i++)
    if (hairStyleAvailable(inventory, i, worn: worn, config: config)) i,
];

/// Nettoie un inventaire relu (sauvegarde, ancienne version) : anciens
/// objets remplacés par leur équivalent actuel, objets inconnus retirés,
/// objets portés possédés et à leur emplacement, teintes limitées aux
/// objets teignables possédés.
Inventory sanitizeInventory(Inventory inventory) {
  final owned = <String>[];
  for (final old in inventory.owned) {
    final id = currentItemId(old);
    if (itemById(id) != null && !owned.contains(id)) owned.add(id);
  }
  final equipped = <EquipmentSlot, String>{};
  inventory.equipped.forEach((_, old) {
    final id = currentItemId(old);
    final item = itemById(id);
    if (item != null && owned.contains(id)) equipped[item.slot] = id;
  });
  final dyes = <String, int>{};
  inventory.dyes.forEach((old, color) {
    final id = currentItemId(old);
    final item = itemById(id);
    if (item != null && item.dyeable && owned.contains(id)) dyes[id] = color;
  });
  return Inventory(
    owned: owned,
    hairStyles: inventory.hairStyles.toSet().toList()..sort(),
    equipped: equipped,
    dyes: dyes,
  );
}

/// Ce que le rendu doit afficher pour l'équipement porté.
class Loadout {
  const Loadout({this.outfitId, this.outfitTint, this.weaponId});

  /// Rien de porté : vêtements de base du personnage.
  static const Loadout none = Loadout();

  /// Sprite de la tenue portée, ou `null`.
  final String? outfitId;

  /// Teinte de la tenue (teinture ou couleur d'un objet exclusif), ou `null`.
  final int? outfitTint;

  /// Sprite de l'arme tenue, ou `null`.
  final String? weaponId;
}

/// Calcule l'apparence de l'équipement porté (un objet essayé en boutique
/// peut remplacer celui de son emplacement).
Loadout loadoutOf(Inventory inventory, {EquipmentItem? tryOn}) {
  EquipmentItem? worn(EquipmentSlot slot) {
    if (tryOn != null && tryOn.slot == slot) return tryOn;
    final id = inventory.equipped[slot];
    return id == null ? null : itemById(id);
  }

  final outfit = worn(EquipmentSlot.chest);
  final weapon = worn(EquipmentSlot.weapon);
  return Loadout(
    outfitId: outfit?.spriteId,
    outfitTint: outfit == null
        ? null
        : (outfit.dyeable ? inventory.dyes[outfit.id] : null) ?? outfit.tint,
    weaponId: weapon?.spriteId,
  );
}
