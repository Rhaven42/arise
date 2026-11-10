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
  if (item == null)
    return (inventory: inventory, issue: EquipIssue.unknownItem);
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

/// Nettoie un inventaire relu (sauvegarde, ancienne version) : objets
/// inconnus retirés, objets portés possédés et à leur emplacement, teintes
/// limitées aux objets teignables possédés.
Inventory sanitizeInventory(Inventory inventory) {
  final owned = <String>[];
  for (final id in inventory.owned) {
    if (itemById(id) != null && !owned.contains(id)) owned.add(id);
  }
  final equipped = <EquipmentSlot, String>{};
  inventory.equipped.forEach((slot, id) {
    final item = itemById(id);
    if (item != null && item.slot == slot && owned.contains(id)) {
      equipped[slot] = id;
    }
  });
  final dyes = <String, int>{};
  inventory.dyes.forEach((id, color) {
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
  const Loadout({
    required this.itemNodes,
    required this.hiddenOutfit,
    required this.dyes,
    required this.hidesHair,
  });

  /// Rien de porté : tenue de départ complète.
  static const Loadout none = Loadout(
    itemNodes: [],
    hiddenOutfit: [],
    dyes: {},
    hidesHair: false,
  );

  /// Pièces 3D visibles (`item_<id>`).
  final List<String> itemNodes;

  /// Pièces de la tenue de départ à masquer.
  final List<String> hiddenOutfit;

  /// Couleur par matériau teint (`dye_<id>`).
  final Map<String, int> dyes;

  /// La coiffure est cachée (casque, capuche).
  final bool hidesHair;
}

/// Calcule l'apparence de l'équipement porté (un objet essayé en boutique
/// peut remplacer celui de son emplacement).
Loadout loadoutOf(Inventory inventory, {EquipmentItem? tryOn}) {
  final worn = <EquipmentSlot, EquipmentItem>{};
  inventory.equipped.forEach((slot, id) {
    final item = itemById(id);
    if (item != null) worn[slot] = item;
  });
  if (tryOn != null) worn[tryOn.slot] = tryOn;
  final items = [
    for (final slot in EquipmentSlot.values)
      if (worn[slot] != null) worn[slot]!,
  ];
  return Loadout(
    itemNodes: [for (final item in items) item.nodeName],
    hiddenOutfit: [
      for (final item in items) ...?starterOutfitBySlot[item.slot],
    ],
    dyes: {
      for (final item in items)
        if (item.dyeable && inventory.dyes[item.id] != null)
          item.dyeMaterial: inventory.dyes[item.id]!,
    },
    hidesHair: items.any((item) => item.hidesHair),
  );
}
