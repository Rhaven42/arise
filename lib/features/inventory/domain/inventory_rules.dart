import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

/// Emplacements libérés quand on porte un objet de [slot] : une tenue
/// complète remplace le haut et le bas, et inversement.
Set<EquipmentSlot> _displaced(EquipmentSlot slot) => switch (slot) {
  EquipmentSlot.chest => {EquipmentSlot.top, EquipmentSlot.legs},
  EquipmentSlot.top || EquipmentSlot.legs => {EquipmentSlot.chest},
  _ => const {},
};

/// Porte un objet possédé, à la place de celui de son emplacement (une tenue
/// complète retire le haut et le bas, un haut ou un bas retire la tenue).
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
      equipped: {
        for (final e in inventory.equipped.entries)
          if (!_displaced(item.slot).contains(e.key)) e.key: e.value,
        item.slot: itemId,
      },
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

/// Pièce séparée portée : sprite et teinte éventuelle.
@immutable
class WornPiece {
  const WornPiece(this.spriteId, [this.tint]);

  final String spriteId;
  final int? tint;

  @override
  bool operator ==(Object other) =>
      other is WornPiece && other.spriteId == spriteId && other.tint == tint;

  @override
  int get hashCode => Object.hash(spriteId, tint);
}

/// Ce que le rendu doit afficher pour l'équipement porté.
class Loadout {
  const Loadout({
    this.outfitId,
    this.outfitTint,
    this.weaponId,
    this.pieces = const [],
  });

  /// Rien de porté : vêtements de base du personnage.
  static const Loadout none = Loadout();

  /// Sprite de la tenue portée, ou `null`.
  final String? outfitId;

  /// Teinte de la tenue (teinture ou couleur d'un objet exclusif), ou `null`.
  final int? outfitTint;

  /// Sprite de l'arme tenue, ou `null`.
  final String? weaponId;

  /// Pièces séparées portées, dans l'ordre où elles se dessinent.
  final List<WornPiece> pieces;
}

/// Calcule l'apparence de l'équipement porté (un objet essayé en boutique
/// peut remplacer celui de son emplacement).
Loadout loadoutOf(Inventory inventory, {EquipmentItem? tryOn}) {
  // L'essayage libère les emplacements qu'un achat libérerait.
  final hidden = tryOn == null
      ? const <EquipmentSlot>{}
      : _displaced(tryOn.slot);
  EquipmentItem? worn(EquipmentSlot slot) {
    if (tryOn != null && tryOn.slot == slot) return tryOn;
    if (hidden.contains(slot)) return null;
    final id = inventory.equipped[slot];
    return id == null ? null : itemById(id);
  }

  int? tintOf(EquipmentItem item) =>
      (item.dyeable ? inventory.dyes[item.id] : null) ?? item.tint;

  final outfit = worn(EquipmentSlot.chest);
  final weapon = worn(EquipmentSlot.weapon);
  return Loadout(
    outfitId: outfit?.spriteId,
    outfitTint: outfit == null ? null : tintOf(outfit),
    weaponId: weapon?.spriteId,
    pieces: [
      for (final slot in pieceSlots)
        if (worn(slot) case final piece?)
          WornPiece(piece.spriteId, tintOf(piece)),
    ],
  );
}
