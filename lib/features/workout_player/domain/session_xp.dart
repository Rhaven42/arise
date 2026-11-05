import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';

/// XP d'une séance, avant les bonus de série et de classe (phase 4).
class SessionXp {
  const SessionXp({
    required this.total,
    required this.byStat,
    required this.activeSeconds,
    this.byDifficulty = const {},
    required this.secondsOverCap,
  });

  final int total;

  /// Part de l'XP attribuée à chaque stat (répartition des exercices).
  final Map<StatId, int> byStat;

  /// XP par difficulté d'exercice (1 à 3), pour les pièces gagnées.
  final Map<int, int> byDifficulty;
  final int activeSeconds;

  /// Secondes d'effort au-delà du plafond quotidien (XP divisée par deux).
  final int secondsOverCap;

  bool get exceededDailyCap => secondsOverCap > 0;
}

/// Multiplicateur d'intensité : linéaire de 0,8 (1/10) à 1,3 (10/10).
double intensityMultiplier(int rpe, {IntensityConfig? config}) {
  final c = config ?? gameConfig.intensity;
  final clamped = rpe.clamp(c.rpeMin, c.rpeMax);
  final ratio = (clamped - c.rpeMin) / (c.rpeMax - c.rpeMin);
  return c.multiplierMin + ratio * (c.multiplierMax - c.multiplierMin);
}

/// Volume normalisé d'un effort (valeurs provisoires, SPEC §20.2).
double normalizedVolume(CompletedSet set, {XpConfig? config}) {
  final c = config ?? gameConfig.xp;
  final reps = set.reps;
  if (reps != null) return reps / c.repsPerVolumeUnit;
  final meters = set.meters;
  if (meters != null) return meters / c.metersPerVolumeUnit;
  return set.activeSeconds / c.secondsPerVolumeUnit;
}

/// Calcule l'XP d'une séance.
///
/// [priorActiveSecondsToday] : effort déjà réalisé aujourd'hui avant cette
/// séance. La part d'effort au-delà du plafond de 120 min rapporte deux fois
/// moins d'XP, pour ne jamais encourager le surentraînement.
SessionXp computeSessionXp({
  required List<CompletedSet> sets,
  required Map<String, Exercise> exercisesById,
  required int priorActiveSecondsToday,
  GameConfig config = gameConfig,
}) {
  final capSeconds = config.dailyEffort.activeMinutesCap * 60;
  var cumulative = priorActiveSecondsToday;
  var overCap = 0;
  var total = 0.0;
  final byStat = <StatId, double>{};
  final byDifficulty = <int, double>{};

  for (final set in sets) {
    if (set.skipped) continue;
    final exercise = exercisesById[set.exerciseId];
    final seconds = set.activeSeconds;
    cumulative += seconds;

    // Part de l'effort au-delà du plafond (proportionnelle à la durée).
    final over = (cumulative - capSeconds).clamp(0, seconds);
    final overShare = seconds == 0 ? 0.0 : over / seconds;
    overCap += over;

    final base =
        config.xp.baseXpPerVolumeUnit *
        normalizedVolume(set, config: config.xp) *
        intensityMultiplier(
          set.rpe ?? _neutralRpe(config.intensity),
          config: config.intensity,
        );
    final capFactor =
        1 - overShare + overShare * config.dailyEffort.overCapXpMultiplier;
    final xp = base * capFactor;
    total += xp;
    byDifficulty.update(
      exercise?.difficulty ?? 1,
      (value) => value + xp,
      ifAbsent: () => xp,
    );

    final stats = exercise?.stats ?? const {};
    for (final entry in stats.entries) {
      byStat.update(
        entry.key,
        (value) => value + xp * entry.value,
        ifAbsent: () => xp * entry.value,
      );
    }
  }

  return SessionXp(
    total: total.round(),
    byStat: {
      for (final entry in byStat.entries) entry.key: entry.value.round(),
    },
    byDifficulty: {
      for (final entry in byDifficulty.entries) entry.key: entry.value.round(),
    },
    activeSeconds: cumulative - priorActiveSecondsToday,
    secondsOverCap: overCap,
  );
}

/// Intensité neutre (multiplicateur ≈ 1) quand aucune n'a été saisie.
int _neutralRpe(IntensityConfig c) => ((c.rpeMin + c.rpeMax) / 2).round();

/// Effort actif total des séances commencées le même jour (heure locale).
int activeSecondsOnDay(List<CompletedSession> sessions, DateTime day) {
  final local = day.toLocal();
  final start = DateTime(local.year, local.month, local.day);
  final end = DateTime(local.year, local.month, local.day + 1);
  var total = 0;
  for (final session in sessions) {
    final started = session.startedAt.toLocal();
    if (!started.isBefore(start) && started.isBefore(end)) {
      total += session.activeSeconds;
    }
  }
  return total;
}
