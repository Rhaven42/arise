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
    this.baseId,
    this.tint,
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

  /// Objet exclusif (récompense de boss) : il reprend la pièce 3D de
  /// l'objet [baseId] avec sa propre teinte [tint]. Il ne se vend pas.
  final String? baseId;

  /// Teinte par défaut d'un objet exclusif (ARGB), remplaçable par une
  /// teinture.
  final int? tint;

  bool get isExclusive => baseId != null;

  /// Objet dont la pièce 3D et la vignette sont utilisées.
  String get modelId => baseId ?? id;

  String get nodeName => 'item_$modelId';

  String get dyeMaterial => 'dye_$modelId';
}

/// Récompenses exclusives des boss de rang (SPEC §30), dans l'ordre des
/// rangs E, D, C, B, A, S.
const List<EquipmentItem> bossRewardItems = [
  EquipmentItem(
    id: 'guardian_jacket',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
    baseId: 'leather_chest',
    tint: 0xFF6E6A64,
  ),
  EquipmentItem(
    id: 'stag_cape',
    slot: EquipmentSlot.back,
    rarity: Rarity.epic,
    dyeable: true,
    baseId: 'cape_wanderer',
    tint: 0xFFB8C2CC,
  ),
  EquipmentItem(
    id: 'wind_hood',
    slot: EquipmentSlot.head,
    rarity: Rarity.epic,
    dyeable: true,
    hidesHair: true,
    baseId: 'hood_twilight',
    tint: 0xFF5E9C95,
  ),
  EquipmentItem(
    id: 'colossus_leggings',
    slot: EquipmentSlot.legs,
    rarity: Rarity.legendary,
    dyeable: true,
    baseId: 'leather_legs',
    tint: 0xFF3E3A40,
  ),
  EquipmentItem(
    id: 'comet_cape',
    slot: EquipmentSlot.back,
    rarity: Rarity.legendary,
    dyeable: true,
    baseId: 'cape_dawn',
    tint: 0xFFB0302A,
  ),
  EquipmentItem(
    id: 'tempest_hood',
    slot: EquipmentSlot.head,
    rarity: Rarity.mythic,
    dyeable: true,
    hidesHair: true,
    baseId: 'hood_twilight',
    tint: 0xFF2E2440,
  ),
];

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
  for (final item in bossRewardItems) {
    if (item.id == id) return item;
  }
  return null;
}
