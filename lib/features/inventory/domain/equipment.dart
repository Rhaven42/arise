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
    this.pack,
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

  /// Tenue importée (fichier 3D séparé `assets/outfits/<pack>/`) qui
  /// contient la pièce, ou `null` si elle est dans le modèle du personnage.
  final String? pack;

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
  'obsidian_knight',
  'silver_knight',
  'golden_king',
  'wanderer_coat',
  'noble_gown',
  'hunter_leather',
  'scale_warden',
  'north_lamellar',
  'sylvan_ranger',
  'oath_knight',
  'lotus_samurai',
  'city_guard',
  'pale_coat',
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
  // Modèles 3D créés par la propriétaire du projet (Tripo, compte Pro).
  EquipmentItem(
    id: 'great_helm_gilded',
    slot: EquipmentSlot.head,
    rarity: Rarity.epic,
    hidesHair: true,
  ),
  EquipmentItem(
    id: 'horned_helm_void',
    slot: EquipmentSlot.head,
    rarity: Rarity.legendary,
    hidesHair: true,
  ),
  EquipmentItem(
    id: 'staff_solar_crystal',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.legendary,
  ),
  EquipmentItem(
    id: 'scepter_lunar_orb',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'staff_rose_amethyst',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'staff_dusk',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'halberd_silver',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'sword_warden',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.common,
  ),
  EquipmentItem(
    id: 'sword_curved_shade',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'sword_carved_bone',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'sword_frost',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'sword_dusk',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'sword_ember',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.legendary,
  ),
  EquipmentItem(
    id: 'scimitar_jade',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'glaive_curved',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'dagger_desert',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.common,
  ),
  EquipmentItem(
    id: 'dagger_golden',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'dagger_ice',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'dagger_amethyst',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'dagger_fire_fang',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'dagger_sun',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'dagger_blaze',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.legendary,
  ),
  EquipmentItem(
    id: 'mace_spiked',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.common,
  ),
  EquipmentItem(
    id: 'mace_moon',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'axe_war',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.common,
  ),
  EquipmentItem(
    id: 'cleaver_battle',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'hammer_runic',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  // Chevalier d'Obsidienne (Sketchfab, Jhon Panesso, CC-BY).
  EquipmentItem(
    id: 'obsidian_knight_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.epic,
    setId: 'obsidian_knight',
    hidesHair: true,
    pack: 'obsidian_knight',
  ),
  EquipmentItem(
    id: 'obsidian_knight_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    setId: 'obsidian_knight',
    pack: 'obsidian_knight',
  ),
  EquipmentItem(
    id: 'obsidian_knight_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.epic,
    setId: 'obsidian_knight',
    pack: 'obsidian_knight',
  ),
  EquipmentItem(
    id: 'obsidian_knight_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.epic,
    setId: 'obsidian_knight',
    pack: 'obsidian_knight',
  ),
  EquipmentItem(
    id: 'obsidian_knight_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    setId: 'obsidian_knight',
    pack: 'obsidian_knight',
  ),
  // Chevalier d'Argent (Sketchfab, INKXO, CC-BY).
  EquipmentItem(
    id: 'silver_knight_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.epic,
    setId: 'silver_knight',
    hidesHair: true,
    pack: 'silver_knight',
  ),
  EquipmentItem(
    id: 'silver_knight_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    setId: 'silver_knight',
    pack: 'silver_knight',
  ),
  EquipmentItem(
    id: 'silver_knight_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.epic,
    setId: 'silver_knight',
    pack: 'silver_knight',
  ),
  EquipmentItem(
    id: 'silver_knight_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.epic,
    setId: 'silver_knight',
    pack: 'silver_knight',
  ),
  EquipmentItem(
    id: 'silver_knight_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    setId: 'silver_knight',
    pack: 'silver_knight',
  ),
  // Armure du Roi doré (Sketchfab, Pedro B. Goulart, CC-BY).
  EquipmentItem(
    id: 'golden_king_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.legendary,
    setId: 'golden_king',
    hidesHair: true,
    pack: 'golden_king',
  ),
  EquipmentItem(
    id: 'golden_king_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    setId: 'golden_king',
    pack: 'golden_king',
  ),
  EquipmentItem(
    id: 'golden_king_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.legendary,
    setId: 'golden_king',
    pack: 'golden_king',
  ),
  EquipmentItem(
    id: 'golden_king_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.legendary,
    setId: 'golden_king',
    pack: 'golden_king',
  ),
  EquipmentItem(
    id: 'golden_king_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.legendary,
    setId: 'golden_king',
    pack: 'golden_king',
  ),
  // Tenue de l'Errant (Sketchfab, DEYMAR, CC-BY).
  EquipmentItem(
    id: 'wanderer_coat_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    setId: 'wanderer_coat',
    pack: 'wanderer_coat',
  ),
  EquipmentItem(
    id: 'wanderer_coat_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.rare,
    setId: 'wanderer_coat',
    pack: 'wanderer_coat',
  ),
  EquipmentItem(
    id: 'wanderer_coat_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    setId: 'wanderer_coat',
    pack: 'wanderer_coat',
  ),
  EquipmentItem(
    id: 'wanderer_coat_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    setId: 'wanderer_coat',
    pack: 'wanderer_coat',
  ),
  // Atours de la Noble (Sketchfab, Meast, CC-BY).
  EquipmentItem(
    id: 'noble_gown_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    setId: 'noble_gown',
    pack: 'noble_gown',
  ),
  EquipmentItem(
    id: 'noble_gown_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.epic,
    setId: 'noble_gown',
    pack: 'noble_gown',
  ),
  // Cuir du Traqueur (Sketchfab, Blueprint Games, CC-BY).
  EquipmentItem(
    id: 'hunter_leather_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.common,
    setId: 'hunter_leather',
    hidesHair: true,
    pack: 'hunter_leather',
  ),
  EquipmentItem(
    id: 'hunter_leather_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    setId: 'hunter_leather',
    pack: 'hunter_leather',
  ),
  EquipmentItem(
    id: 'hunter_leather_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.common,
    setId: 'hunter_leather',
    pack: 'hunter_leather',
  ),
  EquipmentItem(
    id: 'hunter_leather_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    setId: 'hunter_leather',
    pack: 'hunter_leather',
  ),
  EquipmentItem(
    id: 'hunter_leather_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    setId: 'hunter_leather',
    pack: 'hunter_leather',
  ),
  // Écailles du Gardien (Sketchfab, nordwar, CC-BY).
  EquipmentItem(
    id: 'scale_warden_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.rare,
    setId: 'scale_warden',
    hidesHair: true,
    pack: 'scale_warden',
  ),
  EquipmentItem(
    id: 'scale_warden_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    setId: 'scale_warden',
    pack: 'scale_warden',
  ),
  EquipmentItem(
    id: 'scale_warden_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.rare,
    setId: 'scale_warden',
    pack: 'scale_warden',
  ),
  EquipmentItem(
    id: 'scale_warden_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    setId: 'scale_warden',
    pack: 'scale_warden',
  ),
  EquipmentItem(
    id: 'scale_warden_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    setId: 'scale_warden',
    pack: 'scale_warden',
  ),
  // Lamelles du Nord (Sketchfab, nordwar, CC-BY).
  EquipmentItem(
    id: 'north_lamellar_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.rare,
    setId: 'north_lamellar',
    hidesHair: true,
    pack: 'north_lamellar',
  ),
  EquipmentItem(
    id: 'north_lamellar_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    setId: 'north_lamellar',
    pack: 'north_lamellar',
  ),
  EquipmentItem(
    id: 'north_lamellar_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.rare,
    setId: 'north_lamellar',
    pack: 'north_lamellar',
  ),
  EquipmentItem(
    id: 'north_lamellar_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    setId: 'north_lamellar',
    pack: 'north_lamellar',
  ),
  EquipmentItem(
    id: 'north_lamellar_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    setId: 'north_lamellar',
    pack: 'north_lamellar',
  ),
  // Rôdeur sylvestre (Sketchfab, BiscuitEater, CC-BY).
  EquipmentItem(
    id: 'sylvan_ranger_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    setId: 'sylvan_ranger',
    pack: 'sylvan_ranger',
  ),
  EquipmentItem(
    id: 'sylvan_ranger_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    setId: 'sylvan_ranger',
    pack: 'sylvan_ranger',
  ),
  EquipmentItem(
    id: 'sylvan_ranger_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    setId: 'sylvan_ranger',
    pack: 'sylvan_ranger',
  ),
  // Chevalier du Serment (Sketchfab, klava88, CC-BY).
  EquipmentItem(
    id: 'oath_knight_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    setId: 'oath_knight',
    pack: 'oath_knight',
  ),
  EquipmentItem(
    id: 'oath_knight_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.rare,
    setId: 'oath_knight',
    pack: 'oath_knight',
  ),
  EquipmentItem(
    id: 'oath_knight_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    setId: 'oath_knight',
    pack: 'oath_knight',
  ),
  EquipmentItem(
    id: 'oath_knight_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    setId: 'oath_knight',
    pack: 'oath_knight',
  ),
  // Armure du Lotus (Sketchfab, stasbelyk13, CC-BY).
  EquipmentItem(
    id: 'lotus_samurai_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    setId: 'lotus_samurai',
    pack: 'lotus_samurai',
  ),
  EquipmentItem(
    id: 'lotus_samurai_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.epic,
    setId: 'lotus_samurai',
    pack: 'lotus_samurai',
  ),
  EquipmentItem(
    id: 'lotus_samurai_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.epic,
    setId: 'lotus_samurai',
    pack: 'lotus_samurai',
  ),
  EquipmentItem(
    id: 'lotus_samurai_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    setId: 'lotus_samurai',
    pack: 'lotus_samurai',
  ),
  // Garde de la Cité (Sketchfab, Taylor, CC-BY).
  EquipmentItem(
    id: 'city_guard_head',
    slot: EquipmentSlot.head,
    rarity: Rarity.rare,
    setId: 'city_guard',
    hidesHair: true,
    pack: 'city_guard',
  ),
  EquipmentItem(
    id: 'city_guard_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    setId: 'city_guard',
    pack: 'city_guard',
  ),
  EquipmentItem(
    id: 'city_guard_hands',
    slot: EquipmentSlot.hands,
    rarity: Rarity.rare,
    setId: 'city_guard',
    pack: 'city_guard',
  ),
  EquipmentItem(
    id: 'city_guard_legs',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    setId: 'city_guard',
    pack: 'city_guard',
  ),
  EquipmentItem(
    id: 'city_guard_feet',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    setId: 'city_guard',
    pack: 'city_guard',
  ),
  // Manteau pâle (Sketchfab, xdragonxallix, CC-BY).
  EquipmentItem(
    id: 'pale_coat_chest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    setId: 'pale_coat',
    dyeable: true,
    pack: 'pale_coat',
  ),
  // Pièces d'armure fournies par la propriétaire du projet (Tripo).
  EquipmentItem(
    id: 'studded_vest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'studded_vest',
  ),
  EquipmentItem(
    id: 'azure_plate',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'azure_plate',
  ),
  EquipmentItem(
    id: 'scarlet_steel',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'scarlet_steel',
  ),
  EquipmentItem(
    id: 'crimson_mark',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'crimson_mark',
  ),
  EquipmentItem(
    id: 'sage_robe',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'sage_robe',
  ),
  EquipmentItem(
    id: 'strap_harness',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'strap_harness',
  ),
  EquipmentItem(
    id: 'eye_plate',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'eye_plate',
  ),
  EquipmentItem(
    id: 'claw_vest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'claw_vest',
  ),
  EquipmentItem(
    id: 'gilded_scale',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    pack: 'gilded_scale',
  ),
  EquipmentItem(
    id: 'nomad_vest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    pack: 'nomad_vest',
  ),
  EquipmentItem(
    id: 'shadow_cuirass',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'shadow_cuirass',
  ),
  EquipmentItem(
    id: 'bone_raider',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'bone_raider',
  ),
  EquipmentItem(
    id: 'rust_plate',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    pack: 'rust_plate',
  ),
  EquipmentItem(
    id: 'iron_brigand',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'iron_brigand',
  ),
  EquipmentItem(
    id: 'bronze_guard',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'bronze_guard',
  ),
  EquipmentItem(
    id: 'night_vest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    pack: 'night_vest',
  ),
  EquipmentItem(
    id: 'black_cuirass',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'black_cuirass',
  ),
  EquipmentItem(
    id: 'steel_vest',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    pack: 'steel_vest',
  ),
  EquipmentItem(
    id: 'thorn_plate',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'thorn_plate',
  ),
  EquipmentItem(
    id: 'silver_cuirass',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'silver_cuirass',
  ),
  EquipmentItem(
    id: 'hunter_jerkin',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    pack: 'hunter_jerkin',
  ),
  EquipmentItem(
    id: 'forest_gown',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'forest_gown',
  ),
  EquipmentItem(
    id: 'raider_scarf',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'raider_scarf',
  ),
  EquipmentItem(
    id: 'lion_plate',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'lion_plate',
  ),
  EquipmentItem(
    id: 'dark_knight',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    pack: 'dark_knight',
  ),
  EquipmentItem(
    id: 'leather_corset',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'leather_corset',
  ),
  EquipmentItem(
    id: 'steel_breastplate',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'steel_breastplate',
  ),
  EquipmentItem(
    id: 'dusk_tabard',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    pack: 'dusk_tabard',
  ),
  EquipmentItem(
    id: 'ember_plate',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    pack: 'ember_plate',
  ),
  EquipmentItem(
    id: 'gambeson',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    pack: 'gambeson',
  ),
  EquipmentItem(
    id: 'peasant_tunic',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    pack: 'peasant_tunic',
  ),
  EquipmentItem(
    id: 'brown_leathers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    pack: 'brown_leathers',
  ),
  EquipmentItem(
    id: 'worn_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    pack: 'worn_trousers',
  ),
  EquipmentItem(
    id: 'layered_hakama',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'layered_hakama',
  ),
  EquipmentItem(
    id: 'crimson_tatters',
    slot: EquipmentSlot.legs,
    rarity: Rarity.epic,
    pack: 'crimson_tatters',
  ),
  EquipmentItem(
    id: 'red_greaves',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'red_greaves',
  ),
  EquipmentItem(
    id: 'riding_breeches',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    pack: 'riding_breeches',
  ),
  EquipmentItem(
    id: 'shadow_tatters',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'shadow_tatters',
  ),
  EquipmentItem(
    id: 'patch_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    pack: 'patch_trousers',
  ),
  EquipmentItem(
    id: 'forest_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    pack: 'forest_trousers',
  ),
  EquipmentItem(
    id: 'mystic_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'mystic_trousers',
  ),
  EquipmentItem(
    id: 'scout_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    pack: 'scout_trousers',
  ),
  EquipmentItem(
    id: 'azure_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'azure_trousers',
  ),
  EquipmentItem(
    id: 'duelist_leggings',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'duelist_leggings',
  ),
  EquipmentItem(
    id: 'pouch_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'pouch_trousers',
  ),
  EquipmentItem(
    id: 'plain_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    pack: 'plain_trousers',
  ),
  EquipmentItem(
    id: 'black_greaves',
    slot: EquipmentSlot.legs,
    rarity: Rarity.epic,
    pack: 'black_greaves',
  ),
  EquipmentItem(
    id: 'ranger_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    pack: 'ranger_trousers',
  ),
  EquipmentItem(
    id: 'rogue_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'rogue_trousers',
  ),
  EquipmentItem(
    id: 'sky_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    pack: 'sky_trousers',
  ),
  EquipmentItem(
    id: 'iron_strap_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    pack: 'iron_strap_boots',
  ),
  EquipmentItem(
    id: 'skull_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.legendary,
    pack: 'skull_boots',
  ),
  EquipmentItem(
    id: 'runic_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    pack: 'runic_boots',
  ),
  EquipmentItem(
    id: 'legend_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.legendary,
    pack: 'legend_boots',
  ),
  EquipmentItem(
    id: 'knight_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    pack: 'knight_boots',
  ),
  EquipmentItem(
    id: 'buckle_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    pack: 'buckle_boots',
  ),
  EquipmentItem(
    id: 'laced_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    pack: 'laced_boots',
  ),
  EquipmentItem(
    id: 'city_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    pack: 'city_boots',
  ),
  EquipmentItem(
    id: 'rider_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    pack: 'rider_boots',
  ),
  EquipmentItem(
    id: 'arcane_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    pack: 'arcane_boots',
  ),
  EquipmentItem(
    id: 'sylvan_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    pack: 'sylvan_boots',
  ),
  EquipmentItem(
    id: 'plate_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    pack: 'plate_boots',
  ),
  EquipmentItem(
    id: 'azure_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    pack: 'azure_boots',
  ),
  EquipmentItem(
    id: 'diamond_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    pack: 'diamond_boots',
  ),
  EquipmentItem(
    id: 'war_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    pack: 'war_boots',
  ),
  EquipmentItem(
    id: 'trail_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    pack: 'trail_boots',
  ),
  EquipmentItem(
    id: 'wanderer_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    pack: 'wanderer_boots',
  ),
  EquipmentItem(
    id: 'frost_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.epic,
    pack: 'frost_boots',
  ),
  EquipmentItem(
    id: 'cuff_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    pack: 'cuff_boots',
  ),
  EquipmentItem(
    id: 'strap_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    pack: 'strap_boots',
  ),
  EquipmentItem(
    id: 'night_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    pack: 'night_boots',
  ),
  EquipmentItem(
    id: 'knight_helm',
    slot: EquipmentSlot.head,
    rarity: Rarity.rare,
    hidesHair: true,
    pack: 'knight_helm',
  ),
  EquipmentItem(
    id: 'spiked_helm',
    slot: EquipmentSlot.head,
    rarity: Rarity.epic,
    hidesHair: true,
    pack: 'spiked_helm',
  ),
  EquipmentItem(
    id: 'shade_hood',
    slot: EquipmentSlot.head,
    rarity: Rarity.rare,
    hidesHair: true,
    pack: 'shade_hood',
  ),
  EquipmentItem(
    id: 'crest_helm',
    slot: EquipmentSlot.head,
    rarity: Rarity.epic,
    hidesHair: true,
    pack: 'crest_helm',
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
