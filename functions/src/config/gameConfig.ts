/**
 * Constantes d'équilibrage d'ARISE, côté serveur.
 *
 * Ce fichier est le miroir exact de `lib/core/config/game_config.dart`.
 * Les deux sont comparés à `shared/game_config.snapshot.json` par un test de
 * parité : toute modification doit être faite dans les trois fichiers.
 *
 * Les clés listées dans `provisionalKeys` sont des valeurs provisoires
 * (SPEC.md §20) qui pourront être ajustées après validation.
 */

/** Identifiant stable d'un rang. */
export type RankId = 'e' | 'd' | 'c' | 'b' | 'a' | 's' | 'monarch';

/** Seuil d'entrée d'un rang. */
export interface RankThreshold {
  readonly id: RankId;
  readonly minLevel: number;
}

export const gameConfig = {
  version: 1,
  progression: {
    startLevel: 0,
    maxLevel: 100,
    xpCurveBase: 100,
    xpCurveExponent: 1.5,
    tutorialXp: 100,
    statPointsPerLevel: 3,
    crystalsPerLevelBase: 5,
  },
  intensity: {
    rpeMin: 1,
    rpeMax: 10,
    multiplierMin: 0.8,
    multiplierMax: 1.3,
    effectiveSetMinRpe: 6,
  },
  dailyEffort: {
    activeMinutesCap: 120,
    overCapXpMultiplier: 0.5,
  },
  ranks: [
    { id: 'e', minLevel: 1 },
    { id: 'd', minLevel: 10 },
    { id: 'c', minLevel: 20 },
    { id: 'b', minLevel: 35 },
    { id: 'a', minLevel: 50 },
    { id: 's', minLevel: 70 },
    { id: 'monarch', minLevel: 90 },
  ] as readonly RankThreshold[],
  streaks: {
    bonusPerDay: 0.05,
    maxBonus: 0.5,
    chestMilestonesDays: [7, 30, 100, 365] as readonly number[],
    shieldEveryDays: 14,
    maxShields: 2,
  },
  rest: {
    minRestDaysPerWeek: 1,
    maxRestDaysPerWeek: 3,
    sickModeMaxDays: 14,
  },
  penalty: {
    xpMultiplier: 0.8,
    durationHours: 24,
  },
  classes: {
    unlockRank: 'c' as RankId,
    changeCooldownDays: 30,
    specialistXpBonus: 0.15,
    necromancerXpBonus: 0.05,
  },
  camera: {
    validatedRepsXpBonus: 0.1,
  },
  shadows: {
    unlockRank: 'b' as RankId,
    passiveStatBonus: 0.02,
    maxActive: 5,
    maxActiveNecromancer: 7,
    necromancerBonusMultiplier: 2,
  },
  trials: {
    retryCooldownHours: 48,
  },
  quests: {
    dailyObjectivesMin: 3,
    dailyObjectivesMax: 4,
  },
  character: {
    usernameMinLength: 3,
    usernameMaxLength: 16,
    undoHistorySize: 20,
    favoriteHairstylesMax: 5,
    heightMinCm: 150,
    heightMaxCm: 205,
  },
  volume: {
    strengthPrimaryPoints: 1,
    strengthSecondaryPoints: 0.5,
    cardioMinutesPerPoint: 10,
    cardioMaxPointsPerSession: 3,
    intervalPointsPerRound: 0.25,
  },
  intervalDefaults: {
    workSeconds: 20,
    restSeconds: 10,
    rounds: 8,
  },
  heatmap: {
    weeklyThresholds: [4, 8, 12] as readonly number[],
    dailyThresholds: [2, 4, 6] as readonly number[],
  },
  balance: {
    imbalanceRatio: 1.5,
  },
  health: {
    sleepBonusMinHours: 7,
  },
  provisionalKeys: [
    'progression.maxLevel',
    'streaks.shieldEveryDays',
    'classes.changeCooldownDays',
    'balance.imbalanceRatio',
  ] as readonly string[],
} as const;

export type GameConfig = typeof gameConfig;
