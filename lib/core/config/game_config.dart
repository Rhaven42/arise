// Constantes d'équilibrage d'ARISE.
//
// Seule source des valeurs du jeu : aucun nombre d'équilibrage ne doit être
// écrit ailleurs. Les règles du jeu (couche domain) lisent ces valeurs.

/// Identifiant stable d'un rang.
enum RankId { e, d, c, b, a, s, monarch }

/// Seuil d'entrée d'un rang.
class RankThreshold {
  const RankThreshold({required this.id, required this.minLevel});

  final RankId id;
  final int minLevel;

  Map<String, Object> toJson() => {'id': id.name, 'minLevel': minLevel};
}

class ProgressionConfig {
  const ProgressionConfig({
    required this.startLevel,
    required this.maxLevel,
    required this.xpCurveBase,
    required this.xpCurveExponent,
    required this.tutorialXp,
    required this.statPointsPerLevel,
    required this.silverPerLevelBase,
    required this.statXpPerPoint,
  });

  final int startLevel;
  final int maxLevel;
  final int xpCurveBase;
  final double xpCurveExponent;
  final int tutorialXp;
  final int statPointsPerLevel;

  /// Pièces d'argent d'un passage de niveau : base + niveau atteint.
  final int silverPerLevelBase;

  /// XP attribuée à une stat qui la fait monter d'un point automatiquement.
  final int statXpPerPoint;

  Map<String, Object> toJson() => {
    'startLevel': startLevel,
    'maxLevel': maxLevel,
    'xpCurveBase': xpCurveBase,
    'xpCurveExponent': xpCurveExponent,
    'tutorialXp': tutorialXp,
    'statPointsPerLevel': statPointsPerLevel,
    'silverPerLevelBase': silverPerLevelBase,
    'statXpPerPoint': statXpPerPoint,
  };
}

class IntensityConfig {
  const IntensityConfig({
    required this.rpeMin,
    required this.rpeMax,
    required this.multiplierMin,
    required this.multiplierMax,
    required this.effectiveSetMinRpe,
  });

  final int rpeMin;
  final int rpeMax;
  final double multiplierMin;
  final double multiplierMax;
  final int effectiveSetMinRpe;

  Map<String, Object> toJson() => {
    'rpeMin': rpeMin,
    'rpeMax': rpeMax,
    'multiplierMin': multiplierMin,
    'multiplierMax': multiplierMax,
    'effectiveSetMinRpe': effectiveSetMinRpe,
  };
}

class DailyEffortConfig {
  const DailyEffortConfig({
    required this.activeMinutesCap,
    required this.overCapXpMultiplier,
  });

  final int activeMinutesCap;
  final double overCapXpMultiplier;

  Map<String, Object> toJson() => {
    'activeMinutesCap': activeMinutesCap,
    'overCapXpMultiplier': overCapXpMultiplier,
  };
}

class StreaksConfig {
  const StreaksConfig({
    required this.bonusPerDay,
    required this.maxBonus,
    required this.chestMilestonesDays,
    required this.shieldEveryDays,
    required this.maxShields,
    required this.chestSilver,
    required this.willpowerPerStreakDay,
  });

  final double bonusPerDay;
  final double maxBonus;
  final List<int> chestMilestonesDays;
  final int shieldEveryDays;
  final int maxShields;

  /// Pièces d'argent du coffre de chaque palier (même ordre que les paliers).
  final List<int> chestSilver;

  /// Points de Volonté gagnés par jour de série validé.
  final int willpowerPerStreakDay;

  Map<String, Object> toJson() => {
    'bonusPerDay': bonusPerDay,
    'maxBonus': maxBonus,
    'chestMilestonesDays': chestMilestonesDays,
    'shieldEveryDays': shieldEveryDays,
    'maxShields': maxShields,
    'chestSilver': chestSilver,
    'willpowerPerStreakDay': willpowerPerStreakDay,
  };
}

/// Monnaie : pièces de bronze, d'argent et d'or (SPEC §26).
///
/// Le portefeuille est compté en bronze ; 100 bronze = 1 argent et
/// 100 argent = 1 or. Les exercices difficiles rapportent davantage.
class CoinsConfig {
  const CoinsConfig({
    required this.bronzePerSilver,
    required this.silverPerGold,
    required this.bronzePerXpByDifficulty,
  });

  final int bronzePerSilver;
  final int silverPerGold;

  /// Bronze gagné par point d'XP, selon la difficulté de l'exercice (1 à 3).
  final List<double> bronzePerXpByDifficulty;

  int get bronzePerGold => bronzePerSilver * silverPerGold;

  Map<String, Object> toJson() => {
    'bronzePerSilver': bronzePerSilver,
    'silverPerGold': silverPerGold,
    'bronzePerXpByDifficulty': bronzePerXpByDifficulty,
  };
}

/// Prix de la boutique, en pièces d'argent.
class ShopConfig {
  const ShopConfig({
    required this.commonPriceSilverBySlot,
    required this.rarityPriceSilver,
    required this.hairStylePriceSilver,
    required this.lockedHairStyles,
    required this.dyeCostBronze,
  });

  /// Objets communs : le prix dépend de l'emplacement (1 à 3 pièces).
  final Map<String, int> commonPriceSilverBySlot;

  /// Autres raretés : un prix par rareté (`rare`, `epic`, `legendary`,
  /// `mythic`).
  final Map<String, int> rarityPriceSilver;

  /// Coiffure à débloquer.
  final int hairStylePriceSilver;

  /// Coiffures vendues en boutique (numéros de 1 à 10).
  final List<int> lockedHairStyles;

  /// Teinture d'un objet, en pièces de bronze.
  final int dyeCostBronze;

  Map<String, Object> toJson() => {
    'commonPriceSilverBySlot': commonPriceSilverBySlot,
    'rarityPriceSilver': rarityPriceSilver,
    'hairStylePriceSilver': hairStylePriceSilver,
    'lockedHairStyles': lockedHairStyles,
    'dyeCostBronze': dyeCostBronze,
  };
}

class RestConfig {
  const RestConfig({
    required this.minRestDaysPerWeek,
    required this.maxRestDaysPerWeek,
    required this.sickModeMaxDays,
  });

  final int minRestDaysPerWeek;
  final int maxRestDaysPerWeek;
  final int sickModeMaxDays;

  Map<String, Object> toJson() => {
    'minRestDaysPerWeek': minRestDaysPerWeek,
    'maxRestDaysPerWeek': maxRestDaysPerWeek,
    'sickModeMaxDays': sickModeMaxDays,
  };
}

class PenaltyConfig {
  const PenaltyConfig({
    required this.xpMultiplier,
    required this.durationHours,
  });

  final double xpMultiplier;
  final int durationHours;

  Map<String, Object> toJson() => {
    'xpMultiplier': xpMultiplier,
    'durationHours': durationHours,
  };
}

class ClassesConfig {
  const ClassesConfig({
    required this.unlockRank,
    required this.changeCooldownDays,
    required this.specialistXpBonus,
    required this.necromancerXpBonus,
  });

  final RankId unlockRank;
  final int changeCooldownDays;
  final double specialistXpBonus;
  final double necromancerXpBonus;

  Map<String, Object> toJson() => {
    'unlockRank': unlockRank.name,
    'changeCooldownDays': changeCooldownDays,
    'specialistXpBonus': specialistXpBonus,
    'necromancerXpBonus': necromancerXpBonus,
  };
}

class CameraConfig {
  const CameraConfig({required this.validatedRepsXpBonus});

  final double validatedRepsXpBonus;

  Map<String, Object> toJson() => {
    'validatedRepsXpBonus': validatedRepsXpBonus,
  };
}

class ShadowsConfig {
  const ShadowsConfig({
    required this.unlockRank,
    required this.passiveStatBonus,
    required this.maxActive,
    required this.maxActiveNecromancer,
    required this.necromancerBonusMultiplier,
  });

  final RankId unlockRank;
  final double passiveStatBonus;
  final int maxActive;
  final int maxActiveNecromancer;
  final int necromancerBonusMultiplier;

  Map<String, Object> toJson() => {
    'unlockRank': unlockRank.name,
    'passiveStatBonus': passiveStatBonus,
    'maxActive': maxActive,
    'maxActiveNecromancer': maxActiveNecromancer,
    'necromancerBonusMultiplier': necromancerBonusMultiplier,
  };
}

class TrialsConfig {
  const TrialsConfig({required this.retryCooldownHours});

  final int retryCooldownHours;

  Map<String, Object> toJson() => {'retryCooldownHours': retryCooldownHours};
}

class QuestsConfig {
  const QuestsConfig({
    required this.dailyObjectivesMin,
    required this.dailyObjectivesMax,
  });

  final int dailyObjectivesMin;
  final int dailyObjectivesMax;

  Map<String, Object> toJson() => {
    'dailyObjectivesMin': dailyObjectivesMin,
    'dailyObjectivesMax': dailyObjectivesMax,
  };
}

class CharacterConfig {
  const CharacterConfig({
    required this.usernameMinLength,
    required this.usernameMaxLength,
    required this.undoHistorySize,
    required this.favoriteHairstylesMax,
    required this.heightMinCm,
    required this.heightMaxCm,
  });

  final int usernameMinLength;
  final int usernameMaxLength;
  final int undoHistorySize;
  final int favoriteHairstylesMax;
  final int heightMinCm;
  final int heightMaxCm;

  Map<String, Object> toJson() => {
    'usernameMinLength': usernameMinLength,
    'usernameMaxLength': usernameMaxLength,
    'undoHistorySize': undoHistorySize,
    'favoriteHairstylesMax': favoriteHairstylesMax,
    'heightMinCm': heightMinCm,
    'heightMaxCm': heightMaxCm,
  };
}

class VolumeConfig {
  const VolumeConfig({
    required this.strengthPrimaryPoints,
    required this.strengthSecondaryPoints,
    required this.cardioMinutesPerPoint,
    required this.cardioMaxPointsPerSession,
    required this.intervalPointsPerRound,
  });

  final double strengthPrimaryPoints;
  final double strengthSecondaryPoints;
  final int cardioMinutesPerPoint;
  final double cardioMaxPointsPerSession;
  final double intervalPointsPerRound;

  Map<String, Object> toJson() => {
    'strengthPrimaryPoints': strengthPrimaryPoints,
    'strengthSecondaryPoints': strengthSecondaryPoints,
    'cardioMinutesPerPoint': cardioMinutesPerPoint,
    'cardioMaxPointsPerSession': cardioMaxPointsPerSession,
    'intervalPointsPerRound': intervalPointsPerRound,
  };
}

class IntervalDefaultsConfig {
  const IntervalDefaultsConfig({
    required this.workSeconds,
    required this.restSeconds,
    required this.rounds,
    required this.cycles,
    required this.restBetweenCyclesSeconds,
  });

  final int workSeconds;
  final int restSeconds;
  final int rounds;
  final int cycles;
  final int restBetweenCyclesSeconds;

  Map<String, Object> toJson() => {
    'workSeconds': workSeconds,
    'restSeconds': restSeconds,
    'rounds': rounds,
    'cycles': cycles,
    'restBetweenCyclesSeconds': restBetweenCyclesSeconds,
  };
}

class PlanningConfig {
  const PlanningConfig({required this.reminderLeadMinutes});

  /// Délai entre le rappel et l'heure de la séance.
  final int reminderLeadMinutes;

  Map<String, Object> toJson() => {'reminderLeadMinutes': reminderLeadMinutes};
}

/// Calcul de l'XP d'une série (SPEC §5) : XP de base × volume normalisé ×
/// multiplicateur d'intensité (× bonus de série et de classe en phase 4).
class XpConfig {
  const XpConfig({
    required this.baseXpPerVolumeUnit,
    required this.repsPerVolumeUnit,
    required this.secondsPerVolumeUnit,
    required this.metersPerVolumeUnit,
  });

  /// XP d'une unité de volume normalisé à intensité neutre.
  final int baseXpPerVolumeUnit;

  /// Répétitions qui valent une unité de volume.
  final int repsPerVolumeUnit;

  /// Secondes d'effort (série chronométrée, maintien, round, cardio) qui
  /// valent une unité de volume.
  final int secondsPerVolumeUnit;

  /// Mètres parcourus qui valent une unité de volume.
  final int metersPerVolumeUnit;

  Map<String, Object> toJson() => {
    'baseXpPerVolumeUnit': baseXpPerVolumeUnit,
    'repsPerVolumeUnit': repsPerVolumeUnit,
    'secondsPerVolumeUnit': secondsPerVolumeUnit,
    'metersPerVolumeUnit': metersPerVolumeUnit,
  };
}

class HeatmapConfig {
  const HeatmapConfig({
    required this.weeklyThresholds,
    required this.dailyThresholds,
  });

  /// Bornes basses des niveaux 2, 3 et 4 (séries effectives par semaine).
  final List<double> weeklyThresholds;

  /// Bornes basses des niveaux 2, 3 et 4 en vue jour.
  final List<double> dailyThresholds;

  Map<String, Object> toJson() => {
    'weeklyThresholds': weeklyThresholds,
    'dailyThresholds': dailyThresholds,
  };
}

class BalanceConfig {
  const BalanceConfig({
    required this.imbalanceRatio,
    required this.minVolumeForAlert,
    required this.intervalSecondaryShare,
    required this.pushExercises,
    required this.pullExercises,
    required this.maxSuggestions,
  });

  /// Écart (rapport) au-delà duquel un déséquilibre est signalé.
  final double imbalanceRatio;

  /// Volume minimal (points) de la période avant de comparer : on ne
  /// signale pas de déséquilibre sur deux séries.
  final double minVolumeForAlert;

  /// Tabata/HIIT : part d'un round attribuée aux muscles secondaires.
  final double intervalSecondaryShare;

  /// Classement poussée / tirage des exercices (ANATOMY.md §6).
  final List<String> pushExercises;
  final List<String> pullExercises;

  /// Nombre maximal de suggestions affichées.
  final int maxSuggestions;

  Map<String, Object> toJson() => {
    'imbalanceRatio': imbalanceRatio,
    'minVolumeForAlert': minVolumeForAlert,
    'intervalSecondaryShare': intervalSecondaryShare,
    'pushExercises': pushExercises,
    'pullExercises': pullExercises,
    'maxSuggestions': maxSuggestions,
  };
}

class HealthConfig {
  const HealthConfig({required this.sleepBonusMinHours});

  final int sleepBonusMinHours;

  Map<String, Object> toJson() => {'sleepBonusMinHours': sleepBonusMinHours};
}

/// Configuration complète du jeu.
class GameConfig {
  const GameConfig({
    required this.version,
    required this.progression,
    required this.intensity,
    required this.dailyEffort,
    required this.ranks,
    required this.streaks,
    required this.rest,
    required this.penalty,
    required this.classes,
    required this.camera,
    required this.shadows,
    required this.trials,
    required this.quests,
    required this.character,
    required this.volume,
    required this.intervalDefaults,
    required this.heatmap,
    required this.balance,
    required this.health,
    required this.planning,
    required this.xp,
    required this.coins,
    required this.shop,
    required this.provisionalKeys,
  });

  final int version;
  final ProgressionConfig progression;
  final IntensityConfig intensity;
  final DailyEffortConfig dailyEffort;
  final List<RankThreshold> ranks;
  final StreaksConfig streaks;
  final RestConfig rest;
  final PenaltyConfig penalty;
  final ClassesConfig classes;
  final CameraConfig camera;
  final ShadowsConfig shadows;
  final TrialsConfig trials;
  final QuestsConfig quests;
  final CharacterConfig character;
  final VolumeConfig volume;
  final IntervalDefaultsConfig intervalDefaults;
  final HeatmapConfig heatmap;
  final BalanceConfig balance;
  final HealthConfig health;
  final PlanningConfig planning;
  final XpConfig xp;
  final CoinsConfig coins;
  final ShopConfig shop;

  /// Chemins (« section.clé ») des valeurs provisoires, cf. SPEC.md §20.
  final List<String> provisionalKeys;

  /// Export lisible de la configuration (tests de cohérence, débogage).
  Map<String, Object> toJson() => {
    'version': version,
    'progression': progression.toJson(),
    'intensity': intensity.toJson(),
    'dailyEffort': dailyEffort.toJson(),
    'ranks': [for (final rank in ranks) rank.toJson()],
    'streaks': streaks.toJson(),
    'rest': rest.toJson(),
    'penalty': penalty.toJson(),
    'classes': classes.toJson(),
    'camera': camera.toJson(),
    'shadows': shadows.toJson(),
    'trials': trials.toJson(),
    'quests': quests.toJson(),
    'character': character.toJson(),
    'volume': volume.toJson(),
    'intervalDefaults': intervalDefaults.toJson(),
    'heatmap': heatmap.toJson(),
    'balance': balance.toJson(),
    'health': health.toJson(),
    'planning': planning.toJson(),
    'xp': xp.toJson(),
    'coins': coins.toJson(),
    'shop': shop.toJson(),
    'provisionalKeys': provisionalKeys,
  };
}

/// Valeurs d'équilibrage en vigueur.
const gameConfig = GameConfig(
  version: 1,
  progression: ProgressionConfig(
    startLevel: 0,
    maxLevel: 100,
    xpCurveBase: 100,
    xpCurveExponent: 1.5,
    tutorialXp: 100,
    statPointsPerLevel: 3,
    silverPerLevelBase: 5,
    statXpPerPoint: 50,
  ),
  intensity: IntensityConfig(
    rpeMin: 1,
    rpeMax: 10,
    multiplierMin: 0.8,
    multiplierMax: 1.3,
    effectiveSetMinRpe: 6,
  ),
  dailyEffort: DailyEffortConfig(
    activeMinutesCap: 120,
    overCapXpMultiplier: 0.5,
  ),
  ranks: [
    RankThreshold(id: RankId.e, minLevel: 1),
    RankThreshold(id: RankId.d, minLevel: 10),
    RankThreshold(id: RankId.c, minLevel: 20),
    RankThreshold(id: RankId.b, minLevel: 35),
    RankThreshold(id: RankId.a, minLevel: 50),
    RankThreshold(id: RankId.s, minLevel: 70),
    RankThreshold(id: RankId.monarch, minLevel: 90),
  ],
  streaks: StreaksConfig(
    bonusPerDay: 0.05,
    maxBonus: 0.5,
    chestMilestonesDays: [7, 30, 100, 365],
    shieldEveryDays: 14,
    maxShields: 2,
    chestSilver: [10, 40, 150, 600],
    willpowerPerStreakDay: 1,
  ),
  rest: RestConfig(
    minRestDaysPerWeek: 1,
    maxRestDaysPerWeek: 3,
    sickModeMaxDays: 14,
  ),
  penalty: PenaltyConfig(xpMultiplier: 0.8, durationHours: 24),
  classes: ClassesConfig(
    unlockRank: RankId.c,
    changeCooldownDays: 30,
    specialistXpBonus: 0.15,
    necromancerXpBonus: 0.05,
  ),
  camera: CameraConfig(validatedRepsXpBonus: 0.1),
  shadows: ShadowsConfig(
    unlockRank: RankId.b,
    passiveStatBonus: 0.02,
    maxActive: 5,
    maxActiveNecromancer: 7,
    necromancerBonusMultiplier: 2,
  ),
  trials: TrialsConfig(retryCooldownHours: 48),
  quests: QuestsConfig(dailyObjectivesMin: 3, dailyObjectivesMax: 4),
  character: CharacterConfig(
    usernameMinLength: 3,
    usernameMaxLength: 16,
    undoHistorySize: 20,
    favoriteHairstylesMax: 5,
    heightMinCm: 150,
    heightMaxCm: 205,
  ),
  volume: VolumeConfig(
    strengthPrimaryPoints: 1,
    strengthSecondaryPoints: 0.5,
    cardioMinutesPerPoint: 10,
    cardioMaxPointsPerSession: 3,
    intervalPointsPerRound: 0.25,
  ),
  intervalDefaults: IntervalDefaultsConfig(
    workSeconds: 20,
    restSeconds: 10,
    rounds: 8,
    cycles: 1,
    restBetweenCyclesSeconds: 60,
  ),
  heatmap: HeatmapConfig(
    weeklyThresholds: [4, 8, 12],
    dailyThresholds: [2, 4, 6],
  ),
  balance: BalanceConfig(
    imbalanceRatio: 1.5,
    minVolumeForAlert: 4,
    intervalSecondaryShare: 0.5,
    pushExercises: [
      'push_up',
      'decline_push_up',
      'diamond_push_up',
      'dips',
      'overhead_press',
    ],
    pullExercises: ['pull_up_pronated', 'row', 'biceps_curl'],
    maxSuggestions: 3,
  ),
  health: HealthConfig(sleepBonusMinHours: 7),
  planning: PlanningConfig(reminderLeadMinutes: 30),
  xp: XpConfig(
    baseXpPerVolumeUnit: 10,
    repsPerVolumeUnit: 10,
    secondsPerVolumeUnit: 60,
    metersPerVolumeUnit: 1000,
  ),
  coins: CoinsConfig(
    bronzePerSilver: 100,
    silverPerGold: 100,
    bronzePerXpByDifficulty: [1, 1.5, 2.5],
  ),
  shop: ShopConfig(
    commonPriceSilverBySlot: {
      'head': 2,
      'shoulders': 2,
      'chest': 3,
      'hands': 1,
      'belt': 1,
      'legs': 2,
      'feet': 1,
      'back': 3,
      'weapon': 3,
    },
    rarityPriceSilver: {
      'rare': 10,
      'epic': 40,
      'legendary': 150,
      'mythic': 500,
    },
    hairStylePriceSilver: 10,
    lockedHairStyles: [6, 8, 10],
    dyeCostBronze: 50,
  ),
  provisionalKeys: [
    'shop.commonPriceSilverBySlot',
    'shop.rarityPriceSilver',
    'shop.hairStylePriceSilver',
    'shop.dyeCostBronze',
    'balance.minVolumeForAlert',
    'balance.intervalSecondaryShare',
    'balance.pushExercises',
    'balance.pullExercises',
    'progression.statXpPerPoint',
    'streaks.chestSilver',
    'progression.silverPerLevelBase',
    'coins.bronzePerXpByDifficulty',
    'streaks.willpowerPerStreakDay',
    'xp.baseXpPerVolumeUnit',
    'xp.repsPerVolumeUnit',
    'xp.secondsPerVolumeUnit',
    'xp.metersPerVolumeUnit',
    'intervalDefaults.restBetweenCyclesSeconds',
    'planning.reminderLeadMinutes',
    'progression.maxLevel',
    'streaks.shieldEveryDays',
    'classes.changeCooldownDays',
    'balance.imbalanceRatio',
  ],
);
