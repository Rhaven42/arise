/// Emplacements d'équipement du personnage.
///
/// En pixel art : [chest] (tenue complète), [top] (haut), [legs] (bas),
/// [feet] (chaussures), [hands] (gants) et [weapon]. [head], [shoulders],
/// [belt] et [back] restent pour relire les anciennes sauvegardes.
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
  top,
}

/// Emplacements où se porte un objet du catalogue actuel.
const List<EquipmentSlot> usedSlots = [
  EquipmentSlot.chest,
  EquipmentSlot.top,
  EquipmentSlot.legs,
  EquipmentSlot.feet,
  EquipmentSlot.hands,
  EquipmentSlot.weapon,
];

/// Pièces séparées, dans l'ordre où elles sont dessinées (le haut couvre la
/// taille du pantalon, les gants les manches).
const List<EquipmentSlot> pieceSlots = [
  EquipmentSlot.legs,
  EquipmentSlot.feet,
  EquipmentSlot.top,
  EquipmentSlot.hands,
];

/// Rareté d'un objet (du plus courant au plus rare).
enum Rarity { common, rare, epic, legendary, mythic }

/// Objet cosmétique : une tenue complète, une pièce séparée ou une arme.
/// Les objets n'apportent aucun avantage de jeu : ils changent seulement
/// l'apparence.
class EquipmentItem {
  const EquipmentItem({
    required this.id,
    required this.slot,
    required this.rarity,
    this.dyeable = false,
    this.baseId,
    this.tint,
    this.unlockAchievement,
  });

  /// Identifiant stable ; le sprite s'appelle comme l'objet (ou [baseId]).
  final String id;
  final EquipmentSlot slot;
  final Rarity rarity;

  /// L'objet peut être teint.
  final bool dyeable;

  /// Objet exclusif (récompense de boss) : il reprend le sprite de l'objet
  /// [baseId] avec sa propre teinte [tint]. Il ne se vend pas.
  final String? baseId;

  /// Teinte par défaut d'un objet exclusif (ARGB), remplaçable par une
  /// teinture.
  final int? tint;

  /// Haut fait à obtenir avant de pouvoir acheter l'objet, le cas échéant.
  final String? unlockAchievement;

  bool get isExclusive => baseId != null;

  /// Objet dont le sprite et la vignette sont utilisés.
  String get spriteId => baseId ?? id;
}

/// Récompenses exclusives des boss de rang (SPEC §30), dans l'ordre des
/// rangs E, D, C, B, A, S : des tenues teintes.
const List<EquipmentItem> bossRewardItems = [
  EquipmentItem(
    id: 'guardian_jacket',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
    baseId: 'awakened_leather',
    tint: 0xFF6E6A64,
  ),
  EquipmentItem(
    id: 'stag_cape',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
    baseId: 'silver_knight',
    tint: 0xFFB8C2CC,
  ),
  EquipmentItem(
    id: 'wind_hood',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
    baseId: 'sylvan_ranger',
    tint: 0xFF5E9C95,
  ),
  EquipmentItem(
    id: 'colossus_leggings',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    dyeable: true,
    baseId: 'obsidian_knight',
    tint: 0xFF3E3A40,
  ),
  EquipmentItem(
    id: 'comet_cape',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    dyeable: true,
    baseId: 'golden_king',
    tint: 0xFFB0302A,
  ),
  EquipmentItem(
    id: 'tempest_hood',
    slot: EquipmentSlot.chest,
    rarity: Rarity.mythic,
    dyeable: true,
    baseId: 'pale_coat',
    tint: 0xFF2E2440,
  ),
];

/// Tenues complètes vendues en boutique.
const List<EquipmentItem> outfitCatalog = [
  EquipmentItem(
    id: 'awakened_leather',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'hunter_leather',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'pale_coat',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'desert_sentinel',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'jade_monk',
    slot: EquipmentSlot.chest,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'warden_mail',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'wanderer_coat',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'scale_warden',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'north_lamellar',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'sylvan_ranger',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'oath_knight',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'city_guard',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'verdant_guardian',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'frost_warden',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'crimson_vanguard',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'ember_berserker',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'shadow_assassin',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'pirate_captain',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
    unlockAchievement: 'realm_sea',
  ),
  EquipmentItem(
    id: 'viking_raider',
    slot: EquipmentSlot.chest,
    rarity: Rarity.rare,
    dyeable: true,
    unlockAchievement: 'realm_north',
  ),
  EquipmentItem(
    id: 'dawn_plate',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'obsidian_knight',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'silver_knight',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'noble_gown',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'lotus_samurai',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'storm_templar',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'bone_reaver',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'arcane_battlemage',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'royal_mage',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
    unlockAchievement: 'realm_arcane',
  ),
  EquipmentItem(
    id: 'dragon_scale',
    slot: EquipmentSlot.chest,
    rarity: Rarity.epic,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'golden_king',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'abyss_knight',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'sun_paladin',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'infernal_warlord',
    slot: EquipmentSlot.chest,
    rarity: Rarity.legendary,
    dyeable: true,
  ),
];

/// Pièces séparées vendues en boutique (haut, bas, chaussures, gants) : elles
/// se portent sur les vêtements de base ; les chaussures et les gants aussi
/// sur une tenue complète.
const List<EquipmentItem> pieceCatalog = [
  EquipmentItem(
    id: 'forest_jerkin',
    slot: EquipmentSlot.top,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'padded_gambeson',
    slot: EquipmentSlot.top,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'chain_shirt',
    slot: EquipmentSlot.top,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'noble_doublet',
    slot: EquipmentSlot.top,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'fur_vest',
    slot: EquipmentSlot.top,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'iron_greaves',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'black_breeches',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'chain_chausses',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'ranger_trousers',
    slot: EquipmentSlot.legs,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'royal_breeches',
    slot: EquipmentSlot.legs,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'steel_sabatons',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'fur_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'elven_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'riding_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'golden_boots',
    slot: EquipmentSlot.feet,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'steel_gauntlets',
    slot: EquipmentSlot.hands,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'leather_gloves',
    slot: EquipmentSlot.hands,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'fingerless_gloves',
    slot: EquipmentSlot.hands,
    rarity: Rarity.common,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'silk_gloves',
    slot: EquipmentSlot.hands,
    rarity: Rarity.rare,
    dyeable: true,
  ),
  EquipmentItem(
    id: 'fur_bracers',
    slot: EquipmentSlot.hands,
    rarity: Rarity.common,
    dyeable: true,
  ),
];

/// Armes vendues en boutique.
const List<EquipmentItem> weaponCatalog = [
  EquipmentItem(
    id: 'sword_warden',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.common,
  ),
  EquipmentItem(
    id: 'axe_war',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.common,
  ),
  EquipmentItem(
    id: 'mace_spiked',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.common,
  ),
  EquipmentItem(
    id: 'dagger_desert',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.common,
  ),
  EquipmentItem(
    id: 'scimitar_jade',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'staff_dusk',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.rare,
  ),
  EquipmentItem(
    id: 'sword_frost',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'halberd_silver',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'hammer_runic',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.epic,
  ),
  EquipmentItem(
    id: 'sword_dawn',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.legendary,
  ),
  EquipmentItem(
    id: 'sword_ember',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.legendary,
  ),
  EquipmentItem(
    id: 'staff_ember',
    slot: EquipmentSlot.weapon,
    rarity: Rarity.mythic,
  ),
];

/// Tout ce que vend la boutique, dans l'ordre d'affichage.
const List<EquipmentItem> equipmentCatalog = [
  ...outfitCatalog,
  ...pieceCatalog,
  ...weaponCatalog,
];

/// Anciens objets (pièces 3D, jusqu'au 19/11/2026) et leur remplaçant :
/// chaque pièce d'un ensemble devient la tenue complète, les armes retirées
/// deviennent l'arme la plus proche. Les pièces isolées disparaissent.
const Map<String, String> legacyItemIds = {
  'city_guard_chest': 'city_guard',
  'city_guard_feet': 'city_guard',
  'city_guard_hands': 'city_guard',
  'city_guard_head': 'city_guard',
  'city_guard_legs': 'city_guard',
  'cleaver_battle': 'axe_war',
  'dagger_amethyst': 'dagger_desert',
  'dagger_blaze': 'dagger_desert',
  'dagger_fire_fang': 'dagger_desert',
  'dagger_golden': 'dagger_desert',
  'dagger_ice': 'dagger_desert',
  'dagger_sun': 'dagger_desert',
  'glaive_curved': 'halberd_silver',
  'golden_king_chest': 'golden_king',
  'golden_king_feet': 'golden_king',
  'golden_king_hands': 'golden_king',
  'golden_king_head': 'golden_king',
  'golden_king_legs': 'golden_king',
  'hunter_leather_chest': 'hunter_leather',
  'hunter_leather_feet': 'hunter_leather',
  'hunter_leather_hands': 'hunter_leather',
  'hunter_leather_head': 'hunter_leather',
  'hunter_leather_legs': 'hunter_leather',
  'leather_belt': 'awakened_leather',
  'leather_chest': 'awakened_leather',
  'leather_feet': 'awakened_leather',
  'leather_hands': 'awakened_leather',
  'leather_legs': 'awakened_leather',
  'lotus_samurai_chest': 'lotus_samurai',
  'lotus_samurai_feet': 'lotus_samurai',
  'lotus_samurai_hands': 'lotus_samurai',
  'lotus_samurai_legs': 'lotus_samurai',
  'mace_moon': 'mace_spiked',
  'mail_chest': 'warden_mail',
  'mail_feet': 'warden_mail',
  'mail_hands': 'warden_mail',
  'mail_head': 'warden_mail',
  'mail_legs': 'warden_mail',
  'noble_gown_chest': 'noble_gown',
  'noble_gown_legs': 'noble_gown',
  'north_lamellar_chest': 'north_lamellar',
  'north_lamellar_feet': 'north_lamellar',
  'north_lamellar_hands': 'north_lamellar',
  'north_lamellar_head': 'north_lamellar',
  'north_lamellar_legs': 'north_lamellar',
  'oath_knight_chest': 'oath_knight',
  'oath_knight_feet': 'oath_knight',
  'oath_knight_hands': 'oath_knight',
  'oath_knight_legs': 'oath_knight',
  'obsidian_knight_chest': 'obsidian_knight',
  'obsidian_knight_feet': 'obsidian_knight',
  'obsidian_knight_hands': 'obsidian_knight',
  'obsidian_knight_head': 'obsidian_knight',
  'obsidian_knight_legs': 'obsidian_knight',
  'pale_coat_chest': 'pale_coat',
  'plate_belt': 'dawn_plate',
  'plate_chest': 'dawn_plate',
  'plate_feet': 'dawn_plate',
  'plate_hands': 'dawn_plate',
  'plate_head': 'dawn_plate',
  'plate_legs': 'dawn_plate',
  'plate_shoulders': 'dawn_plate',
  'scale_warden_chest': 'scale_warden',
  'scale_warden_feet': 'scale_warden',
  'scale_warden_hands': 'scale_warden',
  'scale_warden_head': 'scale_warden',
  'scale_warden_legs': 'scale_warden',
  'scepter_lunar_orb': 'staff_dusk',
  'silver_knight_chest': 'silver_knight',
  'silver_knight_feet': 'silver_knight',
  'silver_knight_hands': 'silver_knight',
  'silver_knight_head': 'silver_knight',
  'silver_knight_legs': 'silver_knight',
  'staff_rose_amethyst': 'staff_dusk',
  'staff_solar_crystal': 'staff_ember',
  'sword_carved_bone': 'sword_warden',
  'sword_curved_shade': 'scimitar_jade',
  'sword_dusk': 'sword_frost',
  'sylvan_ranger_chest': 'sylvan_ranger',
  'sylvan_ranger_feet': 'sylvan_ranger',
  'sylvan_ranger_legs': 'sylvan_ranger',
  'wanderer_coat_chest': 'wanderer_coat',
  'wanderer_coat_feet': 'wanderer_coat',
  'wanderer_coat_hands': 'wanderer_coat',
  'wanderer_coat_legs': 'wanderer_coat',
};

/// Identifiant actuel d'un objet relu (ancienne sauvegarde comprise).
String currentItemId(String id) => legacyItemIds[id] ?? id;

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
