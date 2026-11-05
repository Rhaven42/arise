import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';

/// Volume d'une séance (ANATOMY.md §3).
class SessionVolume {
  const SessionVolume({
    required this.points,
    required this.flexibilitySeconds,
    required this.pushSets,
    required this.pullSets,
  });

  /// Points de renforcement par muscle (séries effectives équivalentes).
  final Map<MuscleId, double> points;

  /// Mobilité et étirements : indicateur de souplesse séparé, qui ne gonfle
  /// jamais le volume de renforcement.
  final int flexibilitySeconds;

  /// Séries effectives d'exercices de poussée et de tirage.
  final double pushSets;
  final double pullSets;
}

/// Convertit les efforts d'une séance en volume par muscle.
///
/// - Musculation : une série effective (intensité ≥ 6/10) vaut 1 point par
///   muscle principal et 0,5 par muscle secondaire.
/// - Cardio : 10 minutes valent 1 point par muscle principal, 3 au plus par
///   séance et par muscle.
/// - Tabata / HIIT / circuit : un round vaut 0,25 point par muscle principal
///   (et la moitié pour un secondaire, choix provisoire).
/// - Mobilité : alimente seulement l'indicateur de souplesse.
SessionVolume sessionVolume(
  CompletedSession session,
  Map<String, Exercise> exercisesById, {
  GameConfig config = gameConfig,
}) {
  final volume = config.volume;
  final points = <MuscleId, double>{};
  final cardioPoints = <MuscleId, double>{};
  var flexibility = 0;
  var push = 0.0;
  var pull = 0.0;

  void add(Map<MuscleId, double> target, MuscleId muscle, double value) =>
      target.update(muscle, (v) => v + value, ifAbsent: () => value);

  for (final set in session.sets) {
    if (set.skipped) continue;
    final exercise = exercisesById[set.exerciseId];
    if (exercise == null) continue;
    switch (session.format) {
      case ProgramFormat.strength:
        final rpe = set.rpe;
        if (rpe == null || rpe < config.intensity.effectiveSetMinRpe) continue;
        for (final m in exercise.primaryMuscles) {
          add(points, m, volume.strengthPrimaryPoints);
        }
        for (final m in exercise.secondaryMuscles) {
          add(points, m, volume.strengthSecondaryPoints);
        }
        if (config.balance.pushExercises.contains(exercise.id)) push++;
        if (config.balance.pullExercises.contains(exercise.id)) pull++;
      case ProgramFormat.interval:
        final round = volume.intervalPointsPerRound;
        for (final m in exercise.primaryMuscles) {
          add(points, m, round);
        }
        for (final m in exercise.secondaryMuscles) {
          add(points, m, round * config.balance.intervalSecondaryShare);
        }
      case ProgramFormat.cardio:
        final minutes = set.activeSeconds / 60;
        for (final m in exercise.primaryMuscles) {
          add(cardioPoints, m, minutes / volume.cardioMinutesPerPoint);
        }
      case ProgramFormat.mobility:
        flexibility += set.activeSeconds;
    }
  }

  for (final entry in cardioPoints.entries) {
    final capped = entry.value > volume.cardioMaxPointsPerSession
        ? volume.cardioMaxPointsPerSession
        : entry.value;
    add(points, entry.key, capped);
  }

  return SessionVolume(
    points: points,
    flexibilitySeconds: flexibility,
    pushSets: push,
    pullSets: pull,
  );
}
