import 'dart:math';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/domain/hero_class.dart';
import 'package:arise/features/progression/domain/level_curve.dart';
import 'package:arise/features/progression/domain/progression_state.dart';

/// Résultat d'un gain d'XP.
class XpGain {
  const XpGain({
    required this.state,
    required this.levelsGained,
    required this.levelCoins,
    required this.statPointsGained,
    required this.xpDiscarded,
  });

  final ProgressionState state;
  final int levelsGained;

  /// Pièces d'argent des niveaux gagnés.
  final Coins levelCoins;
  final int statPointsGained;

  /// XP perdue parce que le rang est bloqué ou le niveau maximum atteint.
  final int xpDiscarded;
}

/// Ajoute de l'XP : passages de niveau, pièces et points de stat, avec
/// blocage au dernier niveau d'un rang tant que son boss n'est pas vaincu.
XpGain addXp(ProgressionState state, int xp, {GameConfig config = gameConfig}) {
  var level = state.level;
  var inLevel = state.xpInLevel + xp;
  var levels = 0;
  var silver = 0;
  var points = 0;
  var discarded = 0;

  while (true) {
    if (level >= config.progression.maxLevel) {
      discarded += inLevel;
      inLevel = 0;
      break;
    }
    final need = xpToNextLevel(level, config: config.progression);
    if (inLevel < need) break;
    if (rankLockedAt(level, state.defeatedBosses)) {
      // La barre reste pleine : le passage se fera après la victoire.
      discarded += inLevel - need;
      inLevel = need;
      break;
    }
    inLevel -= need;
    level++;
    levels++;
    silver += config.progression.silverPerLevelBase + level;
    points += config.progression.statPointsPerLevel;
  }

  final earned = Coins.of(silver: silver, config: config.coins);
  return XpGain(
    state: state.copyWith(
      level: level,
      xpInLevel: inLevel,
      totalXp: state.totalXp + xp - discarded,
      coins: state.coins + earned.bronzeTotal,
      freeStatPoints: state.freeStatPoints + points,
    ),
    levelsGained: levels,
    levelCoins: earned,
    statPointsGained: points,
    xpDiscarded: discarded,
  );
}

/// Multiplicateur de série : +5 % par jour, plafonné à +50 %.
double streakMultiplier(int streakDays, {StreaksConfig? config}) {
  final c = config ?? gameConfig.streaks;
  return 1 + min(streakDays * c.bonusPerDay, c.maxBonus);
}

/// Bilan d'une séance pour la progression.
class SessionProgress {
  const SessionProgress({
    required this.state,
    required this.xpGained,
    required this.xpByStat,
    required this.multiplier,
    required this.levelsGained,
    required this.sessionCoins,
    required this.levelCoins,
    required this.statPointsGained,
    required this.dayValidated,
    required this.chestCoins,
    required this.rankLocked,
    this.classXp = 0,
    this.shadowXp = 0,
  });

  final ProgressionState state;
  final int xpGained;
  final Map<StatId, int> xpByStat;

  /// Bonus de série × malus de pénalité appliqués à l'XP de base.
  final double multiplier;

  /// XP de base ajoutée par la classe (avant le multiplicateur).
  final int classXp;

  /// XP ajoutée par les Ombres actives (après le multiplicateur).
  final int shadowXp;
  final int levelsGained;

  /// Pièces gagnées par les efforts de la séance.
  final Coins sessionCoins;

  /// Pièces d'argent des niveaux gagnés.
  final Coins levelCoins;
  final int statPointsGained;

  /// Vrai si la séance valide le jour (série prolongée).
  final bool dayValidated;

  /// Pièces du coffre de série obtenu (zéro sans coffre).
  final Coins chestCoins;

  /// Total des pièces gagnées.
  Coins get coinsGained => sessionCoins + levelCoins + chestCoins;

  /// Vrai si l'XP est bloquée en attendant le boss du rang.
  final bool rankLocked;
}

/// Applique une séance terminée (ou interrompue) à la progression.
///
/// - L'XP de base est multipliée par le bonus de série (série acquise avant
///   ce jour) et par le malus de la Zone de Pénalité s'il est actif.
/// - Une séance complète valide le jour, sauf un jour de repos déclaré ou en
///   mode maladie (jours neutres) ; la Volonté progresse avec la série.
/// - Le malus de la Zone de Pénalité est levé par la quête de pénalité
///   (`features/quests`), plus par une simple séance (SPEC §30).
SessionProgress applySession(
  ProgressionState state, {
  required int baseXp,
  required Map<StatId, int> baseXpByStat,
  required bool completed,
  required DateTime now,
  required Set<int> restDays,
  Map<int, int> baseXpByDifficulty = const {},
  Map<StatId, double> statMultipliers = const {},
  GameConfig config = gameConfig,
}) {
  final day = CivilDate.ofLocal(now);
  final penalty = state.isPenaltyActive(now);
  final multiplier =
      streakMultiplier(state.streakDays, config: config.streaks) *
      (penalty ? config.penalty.xpMultiplier : 1);
  // Bonus de classe (SPEC §6) ajouté à l'XP de base, puis multiplié.
  final classBonus = classBonusXpByStat(
    state.heroClass,
    baseXpByStat,
    config: config.classes,
  );
  final classXp = classBonus.values.fold<int>(0, (sum, v) => sum + v);
  // Ombres actives (SPEC §14.3) : multiplicateur sur la part de chaque stat,
  // cumulé avec les autres bonus par multiplication.
  var shadowXp = 0;
  final xpByStat = <StatId, int>{};
  for (final entry in baseXpByStat.entries) {
    final plain = (entry.value + (classBonus[entry.key] ?? 0)) * multiplier;
    final boosted = (plain * (statMultipliers[entry.key] ?? 1)).round();
    shadowXp += boosted - plain.round();
    xpByStat[entry.key] = boosted;
  }
  final xp = ((baseXp + classXp) * multiplier).round() + shadowXp;

  // Pièces des efforts ; une séance sans détail par difficulté (anciennes
  // sauvegardes) compte comme des exercices faciles.
  final effortCoins = sessionCoins(
    baseXpByDifficulty.isEmpty ? {1: baseXp} : baseXpByDifficulty,
    multiplier: multiplier,
    config: config.coins,
  );

  var next = state.copyWith(
    coins: state.coins + effortCoins.bronzeTotal,
    statXp: {
      for (final stat in StatId.values)
        if ((state.statXp[stat] ?? 0) + (xpByStat[stat] ?? 0) > 0)
          stat: (state.statXp[stat] ?? 0) + (xpByStat[stat] ?? 0),
    },
  );
  final gain = addXp(next, xp, config: config);
  next = gain.state;

  final validation = completed
      ? validateDay(next, day: day, restDays: restDays, config: config)
      : null;
  if (validation != null) next = validation.state;

  return SessionProgress(
    state: next,
    xpGained: xp,
    xpByStat: xpByStat,
    multiplier: multiplier,
    levelsGained: gain.levelsGained,
    sessionCoins: effortCoins,
    levelCoins: gain.levelCoins,
    statPointsGained: gain.statPointsGained,
    dayValidated: validation != null,
    chestCoins: validation?.chest ?? Coins.zero,
    rankLocked: next.isRankLocked && next.xpInLevel >= next.xpForNextLevel,
    classXp: classXp,
    shadowXp: shadowXp,
  );
}

/// Résultat de la validation d'un jour.
typedef DayValidation = ({ProgressionState state, Coins chest});

/// Valide [day] (séance complète ou quête quotidienne terminée) : la série
/// s'allonge, la Volonté progresse et un coffre est offert aux paliers.
///
/// Renvoie `null` si le jour est neutre (repos déclaré, maladie) ou déjà
/// validé.
DayValidation? validateDay(
  ProgressionState state, {
  required CivilDate day,
  required Set<int> restDays,
  GameConfig config = gameConfig,
}) {
  final neutral = restDays.contains(day.weekday) || state.isSickOn(day);
  if (neutral || state.lastValidatedDay == day) return null;
  final streak = state.streakDays + 1;
  final milestone = config.streaks.chestMilestonesDays.indexOf(streak);
  final chest = milestone < 0
      ? Coins.zero
      : Coins.of(
          silver: config.streaks.chestSilver[milestone],
          config: config.coins,
        );
  return (
    state: state.copyWith(
      streakDays: streak,
      bestStreak: streak > state.bestStreak ? streak : state.bestStreak,
      lastValidatedDay: day,
      willpowerEarned:
          state.willpowerEarned + config.streaks.willpowerPerStreakDay,
      coins: state.coins + chest.bronzeTotal,
    ),
    chest: chest,
  );
}

/// Bilan de la bascule quotidienne.
class RolloverReport {
  const RolloverReport({
    this.missedDays = 0,
    this.shieldsUsed = 0,
    this.shieldsEarned = 0,
    this.streakLost = 0,
    this.penaltyStarted = false,
  });

  final int missedDays;
  final int shieldsUsed;
  final int shieldsEarned;

  /// Longueur de la série perdue (0 si elle a été conservée).
  final int streakLost;
  final bool penaltyStarted;

  bool get isEmpty => missedDays == 0 && shieldsEarned == 0 && !penaltyStarted;
}

/// Résultat de la bascule quotidienne.
typedef Rollover = ({ProgressionState state, RolloverReport report});

/// Évalue chaque jour écoulé depuis la dernière ouverture (jours manqués
/// compris), jusqu'à hier inclus.
///
/// - Jour validé, jour de repos déclaré ou jour de maladie : neutre.
/// - Autre jour : jour manqué. Un bouclier protège la série ; sinon elle
///   repart à zéro. Le malus de −20 % démarre pour 24 h, une seule fois même
///   après plusieurs jours manqués. Jamais de perte de niveau ni de cristaux.
/// - Chaque jour écoulé rapproche d'un nouveau bouclier (stock limité).
Rollover runDailyRollover(
  ProgressionState state, {
  required DateTime now,
  required Set<int> restDays,
  GameConfig config = gameConfig,
}) {
  final today = CivilDate.ofLocal(now);
  var next = state;
  var missed = 0;
  var shieldsUsed = 0;
  var shieldsEarned = 0;
  var streakLost = 0;

  var day = state.lastRolloverDay.next;
  while (day.isBefore(today)) {
    // Progression vers un nouveau bouclier.
    var progress = next.shieldProgressDays + 1;
    var shields = next.shields;
    if (progress >= config.streaks.shieldEveryDays) {
      progress = 0;
      if (shields < config.streaks.maxShields) {
        shields++;
        shieldsEarned++;
      }
    }
    next = next.copyWith(shieldProgressDays: progress, shields: shields);

    final neutral =
        next.lastValidatedDay == day ||
        restDays.contains(day.weekday) ||
        next.isSickOn(day);
    if (!neutral) {
      missed++;
      if (next.shields > 0) {
        next = next.copyWith(shields: next.shields - 1);
        shieldsUsed++;
      } else if (next.streakDays > 0) {
        streakLost += next.streakDays;
        next = next.copyWith(streakDays: 0);
      }
    }
    day = day.next;
  }

  final penaltyStarted = missed > 0;
  if (penaltyStarted) {
    next = next.copyWith(
      penaltyUntil: now.toUtc().add(
        Duration(hours: config.penalty.durationHours),
      ),
    );
  }
  if (today.previous.isAfter(next.lastRolloverDay)) {
    next = next.copyWith(lastRolloverDay: today.previous);
  }
  return (
    state: next,
    report: RolloverReport(
      missedDays: missed,
      shieldsUsed: shieldsUsed,
      shieldsEarned: shieldsEarned,
      streakLost: streakLost,
      penaltyStarted: penaltyStarted,
    ),
  );
}

/// Place un point de stat libre. Renvoie `null` s'il n'en reste aucun.
ProgressionState? allocateStatPoint(ProgressionState state, StatId stat) {
  if (state.freeStatPoints <= 0) return null;
  return state.copyWith(
    freeStatPoints: state.freeStatPoints - 1,
    allocatedStats: {
      ...state.allocatedStats,
      stat: (state.allocatedStats[stat] ?? 0) + 1,
    },
  );
}

/// Active le mode maladie ou blessure pour [days] jours à partir
/// d'aujourd'hui (1 à 14) : ces jours sont neutres, sans pénalité.
ProgressionState setSickMode(
  ProgressionState state, {
  required DateTime now,
  required int days,
  GameConfig config = gameConfig,
}) {
  final length = days.clamp(1, config.rest.sickModeMaxDays);
  return state.copyWith(
    sickUntil: CivilDate.ofLocal(now).addDays(length - 1),
    // Le malus en cours est levé : on ne pénalise pas un joueur malade.
    penaltyUntil: null,
  );
}

/// Termine le mode maladie. Le jour en cours reste neutre : il est marqué
/// comme déjà évalué par la bascule quotidienne.
ProgressionState endSickMode(ProgressionState state, {required DateTime now}) {
  final today = CivilDate.ofLocal(now);
  return state.copyWith(
    sickUntil: null,
    lastRolloverDay: today.isAfter(state.lastRolloverDay)
        ? today
        : state.lastRolloverDay,
  );
}

/// Progression reconstituée à partir des séances déjà enregistrées (joueurs
/// venus d'une version sans progression) : seule l'XP est rejouée.
ProgressionState replaySessionXp(
  ProgressionState state,
  Iterable<({int xp, Map<StatId, int> xpByStat})> sessions,
) {
  var next = state;
  for (final session in sessions) {
    next = next.copyWith(
      statXp: {
        for (final stat in StatId.values)
          if ((next.statXp[stat] ?? 0) + (session.xpByStat[stat] ?? 0) > 0)
            stat: (next.statXp[stat] ?? 0) + (session.xpByStat[stat] ?? 0),
      },
    );
    next = addXp(next, session.xp).state;
  }
  return next;
}

/// Ajoute de l'XP à des stats (santé, hors séance). La Volonté ne se gagne
/// jamais ainsi : elle vient seulement de la régularité.
ProgressionState grantStatXp(ProgressionState state, Map<StatId, int> xp) {
  final gains = {
    for (final e in xp.entries)
      if (e.key != StatId.willpower && e.value > 0) e.key: e.value,
  };
  if (gains.isEmpty) return state;
  return state.copyWith(
    statXp: {
      ...state.statXp,
      for (final e in gains.entries)
        e.key: (state.statXp[e.key] ?? 0) + e.value,
    },
  );
}
