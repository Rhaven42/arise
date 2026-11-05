import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/domain/session_xp.dart';
import 'package:arise/features/workout_player/domain/workout_run.dart';

/// Convertit une séance terminée en séance enregistrée, avec son XP.
CompletedSession summarizeRun({
  required String id,
  required Program program,
  required WorkoutRun run,
  required Map<String, Exercise> exercisesById,
  required int priorActiveSecondsToday,
  required DateTime now,
}) {
  final sets = [
    for (final result in run.results)
      CompletedSet(
        exerciseId: run.steps[result.stepIndex].exerciseId ?? '',
        activeSeconds: result.activeSeconds,
        reps: result.reps,
        meters: result.meters,
        loadKg: run.steps[result.stepIndex].loadKg,
        rpe: result.rpe,
        skipped: result.skipped,
      ),
  ];
  final xp = computeSessionXp(
    sets: sets,
    exercisesById: exercisesById,
    priorActiveSecondsToday: priorActiveSecondsToday,
  );
  return CompletedSession(
    id: id,
    programId: program.id,
    programName: program.name,
    format: program.format,
    startedAt: run.startedAt.toUtc(),
    endedAt: (run.endedAt ?? now).toUtc(),
    sets: sets,
    activeSeconds: xp.activeSeconds,
    xpEarned: xp.total,
    completed: run.isComplete,
    plannedEfforts: run.workStepCount,
    xpByStat: xp.byStat,
    stoppedForPain: run.stopReason == StopReason.painOrDiscomfort,
    exceededDailyCap: xp.exceededDailyCap,
  );
}

/// Muscles sollicités par les efforts réalisés : un muscle principal dans
/// au moins un exercice est affiché comme principal.
Map<MuscleId, MuscleRole> workedMuscles(
  CompletedSession session,
  Map<String, Exercise> exercisesById,
) {
  final roles = <MuscleId, MuscleRole>{};
  for (final set in session.sets) {
    if (set.skipped) continue;
    final exercise = exercisesById[set.exerciseId];
    if (exercise == null) continue;
    for (final entry in exercise.muscleRoles.entries) {
      if (roles[entry.key] != MuscleRole.primary) {
        roles[entry.key] = entry.value;
      }
    }
  }
  return roles;
}
