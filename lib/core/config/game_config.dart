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
    required this.dungeonThemeStats,
  });

  final RankId unlockRank;

  /// Stat renforcée par une Ombre de donjon, selon le thème (noms de
  /// `DungeonTheme` → noms de `StatId`).
  final Map<String, String> dungeonThemeStats;
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
    'dungeonThemeStats': dungeonThemeStats,
  };
}

class TrialsConfig {
  const TrialsConfig({
    required this.retryCooldownHours,
    required this.statRequirementByRank,
    required this.strengthPushUpsByRank,
    required this.strengthSquatsByRank,
    required this.strengthTimeLimitSeconds,
    required this.enduranceMinutesByRank,
    required this.agilityRoundsByRank,
  });

  final int retryCooldownHours;

  /// Valeur minimale de la stat de l'épreuve pour l'affronter, par rang
  /// (E, D, C, B, A, S : le boss du rang E ouvre le rang D).
  final List<int> statRequirementByRank;

  /// Épreuve de force : pompes et squats à réaliser, par rang.
  final List<int> strengthPushUpsByRank;
  final List<int> strengthSquatsByRank;

  /// Épreuve de force : effort actif maximal (repos exclus).
  final int strengthTimeLimitSeconds;

  /// Épreuve d'endurance : minutes de marche ou de course, par rang.
  final List<int> enduranceMinutesByRank;

  /// Épreuve d'agilité : rounds du circuit (20 s / 10 s), par rang.
  final List<int> agilityRoundsByRank;

  Map<String, Object> toJson() => {
    'retryCooldownHours': retryCooldownHours,
    'statRequirementByRank': statRequirementByRank,
    'strengthPushUpsByRank': strengthPushUpsByRank,
    'strengthSquatsByRank': strengthSquatsByRank,
    'strengthTimeLimitSeconds': strengthTimeLimitSeconds,
    'enduranceMinutesByRank': enduranceMinutesByRank,
    'agilityRoundsByRank': agilityRoundsByRank,
  };
}

class QuestsConfig {
  const QuestsConfig({
    required this.dailyObjectivesMin,
    required this.dailyObjectivesMax,
    required this.repsTargetByFitnessLevel,
    required this.holdSecondsTargetByFitnessLevel,
    required this.cardioMinutesTargetByFitnessLevel,
    required this.growthPerPlayerLevel,
    required this.maxTargetMultiplier,
    required this.difficultyTargetFactor,
    required this.repsRounding,
    required this.maxRepsPerSet,
    required this.maxHoldSecondsPerSet,
    required this.rewardXpBase,
    required this.rewardXpPerLevel,
    required this.rewardWillpower,
    required this.penaltyTargetShare,
    required this.weeklySessionsMin,
    required this.weeklySessionsMax,
    required this.weeklyActiveMinutesByFitnessLevel,
    required this.weeklyDailyQuests,
    required this.weeklyRewardXpBase,
    required this.weeklyRewardXpPerLevel,
    required this.weeklyRewardSilver,
    required this.dungeonRepsByFitnessLevel,
    required this.dungeonSetsPerExercise,
    required this.dungeonRoundsByFitnessLevel,
    required this.dungeonRewardXp,
    required this.dungeonFallbackSilver,
    required this.eventRewardXp,
    required this.eventRewardSilver,
  });

  final int dailyObjectivesMin;
  final int dailyObjectivesMax;

  /// Objectifs de base selon le niveau du questionnaire (débutant,
  /// intermédiaire, avancé).
  final List<int> repsTargetByFitnessLevel;
  final List<int> holdSecondsTargetByFitnessLevel;
  final List<int> cardioMinutesTargetByFitnessLevel;

  /// Hausse des objectifs par niveau du joueur, plafonnée.
  final double growthPerPlayerLevel;
  final double maxTargetMultiplier;

  /// Réduction des objectifs selon la difficulté de l'exercice (1 à 3).
  final List<double> difficultyTargetFactor;

  /// Les répétitions sont arrondies à ce multiple.
  final int repsRounding;

  /// Découpage en séries de la séance proposée pour la quête.
  final int maxRepsPerSet;
  final int maxHoldSecondsPerSet;

  /// Récompense de la quête quotidienne : XP (base + par niveau), payée
  /// aussi en bronze (1 pour 1), et Volonté.
  final int rewardXpBase;
  final int rewardXpPerLevel;
  final int rewardWillpower;

  /// Part des objectifs du jour demandée par la quête de pénalité.
  final double penaltyTargetShare;

  /// Quête hebdomadaire : séances complètes (selon les jours
  /// d'entraînement, bornées), minutes d'effort actif selon le niveau du
  /// questionnaire, quêtes du jour accomplies ; récompense.
  final int weeklySessionsMin;
  final int weeklySessionsMax;
  final List<int> weeklyActiveMinutesByFitnessLevel;
  final int weeklyDailyQuests;
  final int weeklyRewardXpBase;
  final int weeklyRewardXpPerLevel;
  final int weeklyRewardSilver;

  /// Donjon hebdomadaire : trois salles, une par jour au plus.
  final List<int> dungeonRepsByFitnessLevel;
  final int dungeonSetsPerExercise;
  final List<int> dungeonRoundsByFitnessLevel;
  final int dungeonRewardXp;

  /// Butin quand tous les objets possibles sont déjà possédés.
  final int dungeonFallbackSilver;

  /// Quêtes d'événement (calendrier d'Arisia).
  final int eventRewardXp;
  final int eventRewardSilver;

  Map<String, Object> toJson() => {
    'dailyObjectivesMin': dailyObjectivesMin,
    'dailyObjectivesMax': dailyObjectivesMax,
    'repsTargetByFitnessLevel': repsTargetByFitnessLevel,
    'holdSecondsTargetByFitnessLevel': holdSecondsTargetByFitnessLevel,
    'cardioMinutesTargetByFitnessLevel': cardioMinutesTargetByFitnessLevel,
    'growthPerPlayerLevel': growthPerPlayerLevel,
    'maxTargetMultiplier': maxTargetMultiplier,
    'difficultyTargetFactor': difficultyTargetFactor,
    'repsRounding': repsRounding,
    'maxRepsPerSet': maxRepsPerSet,
    'maxHoldSecondsPerSet': maxHoldSecondsPerSet,
    'rewardXpBase': rewardXpBase,
    'rewardXpPerLevel': rewardXpPerLevel,
    'rewardWillpower': rewardWillpower,
    'penaltyTargetShare': penaltyTargetShare,
    'weeklySessionsMin': weeklySessionsMin,
    'weeklySessionsMax': weeklySessionsMax,
    'weeklyActiveMinutesByFitnessLevel': weeklyActiveMinutesByFitnessLevel,
    'weeklyDailyQuests': weeklyDailyQuests,
    'weeklyRewardXpBase': weeklyRewardXpBase,
    'weeklyRewardXpPerLevel': weeklyRewardXpPerLevel,
    'weeklyRewardSilver': weeklyRewardSilver,
    'dungeonRepsByFitnessLevel': dungeonRepsByFitnessLevel,
    'dungeonSetsPerExercise': dungeonSetsPerExercise,
    'dungeonRoundsByFitnessLevel': dungeonRoundsByFitnessLevel,
    'dungeonRewardXp': dungeonRewardXp,
    'dungeonFallbackSilver': dungeonFallbackSilver,
    'eventRewardXp': eventRewardXp,
    'eventRewardSilver': eventRewardSilver,
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

/// Comptes locaux (plusieurs joueurs sur un même téléphone).
class AccountConfig {
  const AccountConfig({
    required this.nameMaxLength,
    required this.pinLength,
    required this.maxAccounts,
  });

  /// Longueur maximale du pseudo.
  final int nameMaxLength;

  /// Nombre de chiffres du code PIN facultatif.
  final int pinLength;

  /// Nombre maximal de comptes sur le téléphone.
  final int maxAccounts;

  Map<String, Object> toJson() => {
    'nameMaxLength': nameMaxLength,
    'pinLength': pinLength,
    'maxAccounts': maxAccounts,
  };
}

/// Santé (SPEC §13) : conversion plafonnée des données du téléphone en XP
/// d'Endurance et de Vitalité, et hydratation saisie à la main.
class HealthConfig {
  const HealthConfig({
    required this.sleepBonusMinHours,
    required this.stepsPerBlock,
    required this.xpPerStepBlock,
    required this.stepsCap,
    required this.activityMinutesPerXp,
    required this.activityMinutesCap,
    required this.sleepBonusXp,
    required this.hydrationGoalGlasses,
    required this.hydrationBonusXp,
    required this.glassMl,
    required this.maxGlasses,
    required this.historyDays,
  });

  /// Nuit qui donne le bonus de Vitalité (jamais de pénalité en dessous).
  final int sleepBonusMinHours;

  /// Pas : [xpPerStepBlock] XP d'Endurance par tranche de [stepsPerBlock],
  /// au plus [stepsCap] pas comptés par jour.
  final int stepsPerBlock;
  final int xpPerStepBlock;
  final int stepsCap;

  /// Marche, course ou vélo enregistrés hors de l'application : 1 XP
  /// d'Endurance par [activityMinutesPerXp] minutes, au plus
  /// [activityMinutesCap] minutes par jour.
  final int activityMinutesPerXp;
  final int activityMinutesCap;

  final int sleepBonusXp;

  /// Hydratation : objectif en verres, bonus de Vitalité quand il est atteint.
  final int hydrationGoalGlasses;
  final int hydrationBonusXp;
  final int glassMl;
  final int maxGlasses;

  /// Jours gardés dans l'historique santé.
  final int historyDays;

  Map<String, Object> toJson() => {
    'sleepBonusMinHours': sleepBonusMinHours,
    'stepsPerBlock': stepsPerBlock,
    'xpPerStepBlock': xpPerStepBlock,
    'stepsCap': stepsCap,
    'activityMinutesPerXp': activityMinutesPerXp,
    'activityMinutesCap': activityMinutesCap,
    'sleepBonusXp': sleepBonusXp,
    'hydrationGoalGlasses': hydrationGoalGlasses,
    'hydrationBonusXp': hydrationBonusXp,
    'glassMl': glassMl,
    'maxGlasses': maxGlasses,
    'historyDays': historyDays,
  };
}

/// Configuration complète du jeu.
/// Catégorie d'un haut fait (SPEC §14.2).
enum AchievementCategory {
  regularity,
  volume,
  stats,
  bosses,
  exploration,
  balance,
  secret,
}

/// Mesure suivie par un haut fait (calculée par
/// `features/achievements/domain`).
enum AchievementMetric {
  sessionsCompleted,
  bestStreak,
  dailyQuests,
  activeMinutes,
  totalReps,
  effectiveSets,
  longSessions,
  level,
  strength,
  endurance,
  agility,
  vitality,
  willpower,
  lowestStat,
  bossesDefeated,
  firstTryBosses,
  shadows,
  distinctExercises,
  customExercises,
  programs,
  formatsTried,
  dungeonsCleared,
  itemsOwned,
  eventsCompleted,
  legWeeksInARow,
  balancedPushPullWeeks,
  balancedFrontBackWeeks,
  musclesWorked,
  flexibilityMinutes,
  dawnSessions,
  eveningSessions,
  newYearSessions,
  restDaysRespected,
  painStops,
}

/// Haut fait : atteint quand [metric] vaut au moins [threshold].
class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.category,
    required this.metric,
    required this.threshold,
    this.titleId,
  });

  final String id;
  final AchievementCategory category;
  final AchievementMetric metric;
  final int threshold;

  /// Titre offert (identifiant stable), le cas échéant.
  final String? titleId;

  /// Les hauts faits secrets restent masqués jusqu'à leur obtention.
  bool get secret => category == AchievementCategory.secret;

  Map<String, Object> toJson() => {
    'id': id,
    'category': category.name,
    'metric': metric.name,
    'threshold': threshold,
    'titleId': ?titleId,
  };
}

/// Aura cosmétique débloquée par un titre.
class AuraDefinition {
  const AuraDefinition({
    required this.id,
    required this.titleId,
    required this.color,
  });

  final String id;
  final String titleId;

  /// Couleur ARGB de la lueur.
  final int color;

  Map<String, Object> toJson() => {
    'id': id,
    'titleId': titleId,
    'color': color,
  };
}

class AchievementsConfig {
  const AchievementsConfig({
    required this.definitions,
    required this.auras,
    required this.longSessionMinutes,
    required this.legMuscles,
    required this.legWeekMinPoints,
    required this.balancedWeekMinPoints,
    required this.dawnBeforeMinutes,
    required this.eveningFromMinutes,
  });

  final List<AchievementDefinition> definitions;
  final List<AuraDefinition> auras;

  /// Durée d'effort actif d'une « longue séance » (sous le plafond
  /// quotidien : aucun haut fait ne pousse au surentraînement).
  final int longSessionMinutes;

  /// Muscles des jambes (identifiants de ANATOMY.md §1).
  final List<String> legMuscles;

  /// Volume minimal des jambes pour qu'une semaine compte.
  final double legWeekMinPoints;

  /// Volume minimal de chaque côté (poussée / tirage, face / dos) pour
  /// qu'une semaine équilibrée compte.
  final double balancedWeekMinPoints;

  /// Séance « de l'aube » : commencée avant cette heure (minutes depuis
  /// minuit, heure locale).
  final int dawnBeforeMinutes;

  /// Séance « du soir » : commencée à partir de cette heure.
  final int eveningFromMinutes;

  Map<String, Object> toJson() => {
    'definitions': [for (final d in definitions) d.toJson()],
    'auras': [for (final a in auras) a.toJson()],
    'longSessionMinutes': longSessionMinutes,
    'legMuscles': legMuscles,
    'legWeekMinPoints': legWeekMinPoints,
    'balancedWeekMinPoints': balancedWeekMinPoints,
    'dawnBeforeMinutes': dawnBeforeMinutes,
    'eveningFromMinutes': eveningFromMinutes,
  };
}

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
    required this.achievements,
    required this.trials,
    required this.quests,
    required this.character,
    required this.volume,
    required this.intervalDefaults,
    required this.heatmap,
    required this.balance,
    required this.health,
    required this.account,
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
  final AchievementsConfig achievements;
  final TrialsConfig trials;
  final QuestsConfig quests;
  final CharacterConfig character;
  final VolumeConfig volume;
  final IntervalDefaultsConfig intervalDefaults;
  final HeatmapConfig heatmap;
  final BalanceConfig balance;
  final HealthConfig health;
  final AccountConfig account;
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
    'achievements': achievements.toJson(),
    'trials': trials.toJson(),
    'quests': quests.toJson(),
    'character': character.toJson(),
    'volume': volume.toJson(),
    'intervalDefaults': intervalDefaults.toJson(),
    'heatmap': heatmap.toJson(),
    'balance': balance.toJson(),
    'health': health.toJson(),
    'account': account.toJson(),
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
    dungeonThemeStats: {
      'stoneCrypt': 'strength',
      'echoForest': 'agility',
      'windTower': 'endurance',
    },
  ),
  achievements: AchievementsConfig(
    definitions: [
      AchievementDefinition(
        id: 'first_session',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.sessionsCompleted,
        threshold: 1,
        titleId: 'title_awakened',
      ),
      AchievementDefinition(
        id: 'sessions_10',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.sessionsCompleted,
        threshold: 10,
      ),
      AchievementDefinition(
        id: 'sessions_50',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.sessionsCompleted,
        threshold: 50,
      ),
      AchievementDefinition(
        id: 'sessions_100',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.sessionsCompleted,
        threshold: 100,
      ),
      AchievementDefinition(
        id: 'sessions_250',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.sessionsCompleted,
        threshold: 250,
        titleId: 'title_veteran',
      ),
      AchievementDefinition(
        id: 'streak_7',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.bestStreak,
        threshold: 7,
      ),
      AchievementDefinition(
        id: 'streak_30',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.bestStreak,
        threshold: 30,
      ),
      AchievementDefinition(
        id: 'streak_100',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.bestStreak,
        threshold: 100,
        titleId: 'title_unshakable',
      ),
      AchievementDefinition(
        id: 'daily_quests_10',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.dailyQuests,
        threshold: 10,
      ),
      AchievementDefinition(
        id: 'daily_quests_50',
        category: AchievementCategory.regularity,
        metric: AchievementMetric.dailyQuests,
        threshold: 50,
      ),
      AchievementDefinition(
        id: 'minutes_60',
        category: AchievementCategory.volume,
        metric: AchievementMetric.activeMinutes,
        threshold: 60,
      ),
      AchievementDefinition(
        id: 'minutes_600',
        category: AchievementCategory.volume,
        metric: AchievementMetric.activeMinutes,
        threshold: 600,
      ),
      AchievementDefinition(
        id: 'minutes_3000',
        category: AchievementCategory.volume,
        metric: AchievementMetric.activeMinutes,
        threshold: 3000,
      ),
      AchievementDefinition(
        id: 'minutes_10000',
        category: AchievementCategory.volume,
        metric: AchievementMetric.activeMinutes,
        threshold: 10000,
        titleId: 'title_tireless',
      ),
      AchievementDefinition(
        id: 'reps_1000',
        category: AchievementCategory.volume,
        metric: AchievementMetric.totalReps,
        threshold: 1000,
      ),
      AchievementDefinition(
        id: 'reps_10000',
        category: AchievementCategory.volume,
        metric: AchievementMetric.totalReps,
        threshold: 10000,
      ),
      AchievementDefinition(
        id: 'reps_50000',
        category: AchievementCategory.volume,
        metric: AchievementMetric.totalReps,
        threshold: 50000,
      ),
      AchievementDefinition(
        id: 'sets_500',
        category: AchievementCategory.volume,
        metric: AchievementMetric.effectiveSets,
        threshold: 500,
      ),
      AchievementDefinition(
        id: 'long_session',
        category: AchievementCategory.volume,
        metric: AchievementMetric.longSessions,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'level_5',
        category: AchievementCategory.stats,
        metric: AchievementMetric.level,
        threshold: 5,
      ),
      AchievementDefinition(
        id: 'level_10',
        category: AchievementCategory.stats,
        metric: AchievementMetric.level,
        threshold: 10,
      ),
      AchievementDefinition(
        id: 'level_25',
        category: AchievementCategory.stats,
        metric: AchievementMetric.level,
        threshold: 25,
      ),
      AchievementDefinition(
        id: 'level_50',
        category: AchievementCategory.stats,
        metric: AchievementMetric.level,
        threshold: 50,
        titleId: 'title_legend',
      ),
      AchievementDefinition(
        id: 'level_100',
        category: AchievementCategory.stats,
        metric: AchievementMetric.level,
        threshold: 100,
      ),
      AchievementDefinition(
        id: 'strength_20',
        category: AchievementCategory.stats,
        metric: AchievementMetric.strength,
        threshold: 20,
        titleId: 'title_rock_breaker',
      ),
      AchievementDefinition(
        id: 'endurance_20',
        category: AchievementCategory.stats,
        metric: AchievementMetric.endurance,
        threshold: 20,
      ),
      AchievementDefinition(
        id: 'agility_20',
        category: AchievementCategory.stats,
        metric: AchievementMetric.agility,
        threshold: 20,
      ),
      AchievementDefinition(
        id: 'vitality_20',
        category: AchievementCategory.stats,
        metric: AchievementMetric.vitality,
        threshold: 20,
      ),
      AchievementDefinition(
        id: 'willpower_20',
        category: AchievementCategory.stats,
        metric: AchievementMetric.willpower,
        threshold: 20,
      ),
      AchievementDefinition(
        id: 'all_stats_10',
        category: AchievementCategory.stats,
        metric: AchievementMetric.lowestStat,
        threshold: 10,
        titleId: 'title_balanced',
      ),
      AchievementDefinition(
        id: 'boss_1',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.bossesDefeated,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'boss_2',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.bossesDefeated,
        threshold: 2,
      ),
      AchievementDefinition(
        id: 'boss_3',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.bossesDefeated,
        threshold: 3,
      ),
      AchievementDefinition(
        id: 'boss_4',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.bossesDefeated,
        threshold: 4,
      ),
      AchievementDefinition(
        id: 'boss_5',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.bossesDefeated,
        threshold: 5,
      ),
      AchievementDefinition(
        id: 'boss_6',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.bossesDefeated,
        threshold: 6,
      ),
      AchievementDefinition(
        id: 'first_try_boss',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.firstTryBosses,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'shadow_1',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.shadows,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'shadow_5',
        category: AchievementCategory.bosses,
        metric: AchievementMetric.shadows,
        threshold: 5,
      ),
      AchievementDefinition(
        id: 'exercises_10',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.distinctExercises,
        threshold: 10,
      ),
      AchievementDefinition(
        id: 'exercises_25',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.distinctExercises,
        threshold: 25,
      ),
      AchievementDefinition(
        id: 'exercises_50',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.distinctExercises,
        threshold: 50,
        titleId: 'title_explorer',
      ),
      AchievementDefinition(
        id: 'custom_exercise',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.customExercises,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'first_program',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.programs,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'all_formats',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.formatsTried,
        threshold: 4,
      ),
      AchievementDefinition(
        id: 'dungeon_1',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.dungeonsCleared,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'dungeon_5',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.dungeonsCleared,
        threshold: 5,
      ),
      AchievementDefinition(
        id: 'first_item',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.itemsOwned,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'first_event',
        category: AchievementCategory.exploration,
        metric: AchievementMetric.eventsCompleted,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'legs_4_weeks',
        category: AchievementCategory.balance,
        metric: AchievementMetric.legWeeksInARow,
        threshold: 4,
      ),
      AchievementDefinition(
        id: 'legs_12_weeks',
        category: AchievementCategory.balance,
        metric: AchievementMetric.legWeeksInARow,
        threshold: 12,
        titleId: 'title_never_skips_legs',
      ),
      AchievementDefinition(
        id: 'push_pull_4_weeks',
        category: AchievementCategory.balance,
        metric: AchievementMetric.balancedPushPullWeeks,
        threshold: 4,
      ),
      AchievementDefinition(
        id: 'front_back_4_weeks',
        category: AchievementCategory.balance,
        metric: AchievementMetric.balancedFrontBackWeeks,
        threshold: 4,
      ),
      AchievementDefinition(
        id: 'muscles_15',
        category: AchievementCategory.balance,
        metric: AchievementMetric.musclesWorked,
        threshold: 15,
      ),
      AchievementDefinition(
        id: 'muscles_all',
        category: AchievementCategory.balance,
        metric: AchievementMetric.musclesWorked,
        threshold: 33,
        titleId: 'title_body_cartographer',
      ),
      AchievementDefinition(
        id: 'flexibility_60',
        category: AchievementCategory.balance,
        metric: AchievementMetric.flexibilityMinutes,
        threshold: 60,
      ),
      AchievementDefinition(
        id: 'flexibility_300',
        category: AchievementCategory.balance,
        metric: AchievementMetric.flexibilityMinutes,
        threshold: 300,
        titleId: 'title_willow',
      ),
      AchievementDefinition(
        id: 'dawn_10',
        category: AchievementCategory.secret,
        metric: AchievementMetric.dawnSessions,
        threshold: 10,
        titleId: 'title_dawn_monarch',
      ),
      AchievementDefinition(
        id: 'evening_10',
        category: AchievementCategory.secret,
        metric: AchievementMetric.eveningSessions,
        threshold: 10,
      ),
      AchievementDefinition(
        id: 'new_year',
        category: AchievementCategory.secret,
        metric: AchievementMetric.newYearSessions,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'rest_sage',
        category: AchievementCategory.secret,
        metric: AchievementMetric.restDaysRespected,
        threshold: 20,
        titleId: 'title_rest_sage',
      ),
      AchievementDefinition(
        id: 'listen_body',
        category: AchievementCategory.secret,
        metric: AchievementMetric.painStops,
        threshold: 1,
      ),
      AchievementDefinition(
        id: 'shadow_army',
        category: AchievementCategory.secret,
        metric: AchievementMetric.shadows,
        threshold: 7,
        titleId: 'title_shadow_master',
      ),
    ],
    auras: [
      AuraDefinition(
        id: 'aura_dawn',
        titleId: 'title_dawn_monarch',
        color: 0xFFF2C14E,
      ),
      AuraDefinition(
        id: 'aura_ember',
        titleId: 'title_unshakable',
        color: 0xFFE8743B,
      ),
      AuraDefinition(
        id: 'aura_frost',
        titleId: 'title_body_cartographer',
        color: 0xFF7FD3F2,
      ),
      AuraDefinition(
        id: 'aura_verdant',
        titleId: 'title_willow',
        color: 0xFF7CCB6E,
      ),
      AuraDefinition(
        id: 'aura_shadow',
        titleId: 'title_shadow_master',
        color: 0xFF8B5CF6,
      ),
      AuraDefinition(
        id: 'aura_storm',
        titleId: 'title_stormLord',
        color: 0xFF5B8CFF,
      ),
    ],
    longSessionMinutes: 45,
    legMuscles: [
      'quadriceps',
      'hamstrings',
      'gluteus_maximus',
      'gluteus_medius',
      'adductors',
      'abductors',
      'gastrocnemius',
      'soleus',
      'tibialis_anterior',
      'hip_flexors',
    ],
    legWeekMinPoints: 4,
    balancedWeekMinPoints: 4,
    dawnBeforeMinutes: 390,
    eveningFromMinutes: 1290,
  ),
  trials: TrialsConfig(
    retryCooldownHours: 48,
    statRequirementByRank: [10, 20, 30, 45, 60, 80],
    strengthPushUpsByRank: [20, 30, 40, 50, 60, 75],
    strengthSquatsByRank: [30, 45, 60, 75, 90, 110],
    strengthTimeLimitSeconds: 600,
    enduranceMinutesByRank: [20, 15, 20, 25, 30, 40],
    agilityRoundsByRank: [8, 10, 12, 14, 16, 20],
  ),
  quests: QuestsConfig(
    dailyObjectivesMin: 3,
    dailyObjectivesMax: 4,
    repsTargetByFitnessLevel: [20, 30, 40],
    holdSecondsTargetByFitnessLevel: [45, 60, 90],
    cardioMinutesTargetByFitnessLevel: [10, 15, 20],
    growthPerPlayerLevel: 0.02,
    maxTargetMultiplier: 2,
    difficultyTargetFactor: [1, 0.75, 0.5],
    repsRounding: 5,
    maxRepsPerSet: 15,
    maxHoldSecondsPerSet: 60,
    rewardXpBase: 30,
    rewardXpPerLevel: 2,
    rewardWillpower: 1,
    penaltyTargetShare: 0.5,
    weeklySessionsMin: 2,
    weeklySessionsMax: 5,
    weeklyActiveMinutesByFitnessLevel: [60, 90, 120],
    weeklyDailyQuests: 3,
    weeklyRewardXpBase: 100,
    weeklyRewardXpPerLevel: 5,
    weeklyRewardSilver: 10,
    dungeonRepsByFitnessLevel: [10, 12, 15],
    dungeonSetsPerExercise: 3,
    dungeonRoundsByFitnessLevel: [6, 8, 10],
    dungeonRewardXp: 150,
    dungeonFallbackSilver: 30,
    eventRewardXp: 200,
    eventRewardSilver: 25,
  ),
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
  health: HealthConfig(
    sleepBonusMinHours: 7,
    stepsPerBlock: 1000,
    xpPerStepBlock: 2,
    stepsCap: 12000,
    activityMinutesPerXp: 2,
    activityMinutesCap: 60,
    sleepBonusXp: 15,
    hydrationGoalGlasses: 8,
    hydrationBonusXp: 10,
    glassMl: 250,
    maxGlasses: 20,
    historyDays: 30,
  ),
  account: AccountConfig(nameMaxLength: 20, pinLength: 4, maxAccounts: 6),
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
    'trials.statRequirementByRank',
    'trials.strengthPushUpsByRank',
    'trials.strengthSquatsByRank',
    'trials.strengthTimeLimitSeconds',
    'trials.enduranceMinutesByRank',
    'trials.agilityRoundsByRank',
    'quests.repsTargetByFitnessLevel',
    'quests.holdSecondsTargetByFitnessLevel',
    'quests.cardioMinutesTargetByFitnessLevel',
    'quests.growthPerPlayerLevel',
    'quests.maxTargetMultiplier',
    'quests.difficultyTargetFactor',
    'quests.rewardXpBase',
    'quests.rewardXpPerLevel',
    'quests.rewardWillpower',
    'quests.penaltyTargetShare',
    'quests.weeklyActiveMinutesByFitnessLevel',
    'quests.weeklyDailyQuests',
    'quests.weeklyRewardXpBase',
    'quests.weeklyRewardSilver',
    'quests.dungeonRepsByFitnessLevel',
    'quests.dungeonRoundsByFitnessLevel',
    'quests.dungeonRewardXp',
    'quests.eventRewardXp',
    'quests.eventRewardSilver',
  ],
);
