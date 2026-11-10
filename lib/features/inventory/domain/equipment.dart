/// Emplacements d'équipement du personnage.
enum EquipmentSlot {
  head,
  shoulders,
  chest,
  hands,
  belt,
  legs,
  feet,
  back,
  weapon,
}

/// Rareté d'un objet (du plus courant au plus rare).
enum Rarity { common, rare, epic, legendary, mythic }

/// Pièce de la tenue de départ masquée par un emplacement équipé.
const Map<EquipmentSlot, List<String>> starterOutfitBySlot = {
  EquipmentSlot.chest: ['outfit_tunic', 'outfit_tunic_skirt'],
  EquipmentSlot.legs: ['outfit_pants'],
  EquipmentSlot.feet: ['outfit_boots'],
  EquipmentSlot.belt: ['outfit_belt'],
};

/// Objet cosmétique d'Arisia. Les objets n'apportent aucun avantage de
/// jeu : ils changent seulement l'apparence.
class EquipmentItem {
  const EquipmentItem({
    required this.id,
    required this.slot,
    required this.rarity,
    this.setId,
    this.dyeable = false,
    this.hidesHair = false,
  });

  /// Identifiant stable ; la pièce 3D s'appelle `item_<id>`.
  final String id;
  final EquipmentSlot slot;
  final Rarity rarity;

  /// Ensemble auquel l'objet appartient, ou `null`.
  final String? setId;

  /// L'objet peut être teint (matériau `dye_<id>`).
  final bool dyeable;

  /// L'objet couvre la tête : la coiffure est masquée.
  final bool hidesHair;

  String get nodeName => 'item_$id';

  String get dyeMaterial => 'dye_$id';
}

/// Ensembles d'équipement.
const List<String> equipmentSets = [
  'awakened_leather',
  'warden_mail',
  'dawn_plate',
];

/// Catalogue complet des objets (créations originales, docs/ASSETS.md §3).
const List<EquipmentItem> equipmentCatalog = [
  // Cuir de l'Éveillé (commun).
  EquipmentItem(
    id: 'leather_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    setId: 'awakened_leather',
    dyeable: true,
  ),
  EquipmentItem(
    id: 'leather_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.common,
    setId: 'awakened_leather',
  ),
  EquipmentItem(
    id: 'leather_belt',
    slot: EquipmentSlot.belt,
    rarity: Rarity.common,
    setId: 'awakened_leather',
  ),
  EquipmentItem(
    id: 'leather_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    setId: 'awakened_leather',
    dyeable: true,
  ),
  EquipmentItem(
    id: 'leather_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    setId: 'awakened_leather',
  ),
  // Maille du Veilleur (rare).
  EquipmentItem(
    id: 'mail_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.rare,
    setId: 'warden_mail',
    hidesHair: true,
  ),
  EquipmentItem(
    id: 'mail_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    setId: 'warden_mail',
  ),
  EquipmentItem(
    id: 'mail_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.rare,
    setId: 'warden_mail',
  ),
  EquipmentItem(
    id: 'mail_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    setId: 'warden_mail',
  ),
  EquipmentItem(
    id: 'mail_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    setId: 'warden_mail',
  ),
  // Plates de l'Aube (épique).
  EquipmentItem(
    id: 'plate_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.epic,
    setId: 'dawn_plate',
    hidesHair: true,
  ),
  EquipmentItem(
    id: 'plate_shoulders',
    slot: EquipmentSlot.shoulders,
    rarity: Rarity.epic,
    setId: 'dawn_plate',
  ),
  EquipmentItem(
    id: 'plate_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    setId: 'dawn_plate',
  ),
  EquipmentItem(
    id: 'plate_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.epic,
    setId: 'dawn_plate',
  ),
  EquipmentItem(
    id: 'plate_belt',
    slot: EquipmentSlot.belt,
    rarity: Rarity.epic,
    setId: 'dawn_plate',
  ),
  EquipmentItem(
    id: 'plate_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.epic,
    setId: 'dawn_plate',
  ),
  EquipmentItem(
    id: 'plate_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    setId: 'dawn_plate',
  ),
  // Capes, capuche et armes d'apparat.
  EquipmentItem(
    id: 'cape_wanderer',
    slot: EquipmentSlot.back,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'cape_dawn',
    slot: EquipmentSlot.back,
    rarity: Rarity.legendary,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'hood_twilight',
    slot: EquipmentSlot.head,
    rarity: Rarity.epic,
    dyeable: true,
    hidesHair: true,
  ),
  EquipmentItem(
    id: 'sword_dawn',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.legendary,
  ),
  EquipmentItem(
    id: 'staff_ember',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.mythic,
  ),
];

/// Objet du catalogue, ou `null` s'il n'existe pas (sauvegarde ancienne).
EquipmentItem? itemById(String id) {
  for (final item in equipmentCatalog) {
    if (item.id == id) return item;
  }
  return null;
}
