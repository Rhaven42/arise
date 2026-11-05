import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/workout_step.dart';

/// Déroule un programme en une suite d'étapes (efforts et repos).
///
/// - Musculation : chaque série, suivie du repos prévu (sauf après la
///   dernière série de la séance) ; l'intensité est demandée à chaque série.
/// - Tabata, HIIT, circuit : rounds de travail et de repos, les exercices
///   s'enchaînant à tour de rôle, avec un repos entre les cycles.
/// - Cardio : un effort par exercice (durée ou distance).
/// - Mobilité : un maintien chronométré par exercice.
List<WorkoutStep> buildWorkoutSteps(Program program) {
  if (program.items.isEmpty) return const [];
  return switch (program.format) {
    ProgramFormat.strength => _strengthSteps(program.items),
    ProgramFormat.interval => _intervalSteps(
      program.items,
      program.interval ?? IntervalSettings.defaults(),
    ),
    ProgramFormat.cardio => [
      for (final item in program.items)
        WorkoutStep(
          kind: StepKind.work,
          exerciseId: item.exerciseId,
          targetSeconds: item.distanceMeters == null
              ? item.durationSeconds
              : null,
          targetMeters: item.distanceMeters,
        ),
    ],
    ProgramFormat.mobility => [
      for (final item in program.items)
        WorkoutStep(
          kind: StepKind.work,
          exerciseId: item.exerciseId,
          targetSeconds: item.holdSeconds,
        ),
    ],
  };
}

List<WorkoutStep> _strengthSteps(List<ProgramItem> items) {
  final steps = <WorkoutStep>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final setCount = item.sets ?? 1;
    for (var set = 1; set <= setCount; set++) {
      steps.add(
        WorkoutStep(
          kind: StepKind.work,
          exerciseId: item.exerciseId,
          targetReps: item.reps,
          targetSeconds: item.reps == null ? item.durationSeconds : null,
          loadKg: item.loadKg,
          setNumber: set,
          setCount: setCount,
          asksIntensity: true,
        ),
      );
      final isLastOfSession = i == items.length - 1 && set == setCount;
      final rest = item.restSeconds ?? 0;
      if (!isLastOfSession && rest > 0) {
        final nextExercise = set < setCount
            ? item.exerciseId
            : items[i + 1].exerciseId;
        steps.add(
          WorkoutStep(
            kind: StepKind.rest,
            exerciseId: nextExercise,
            targetSeconds: rest,
          ),
        );
      }
    }
  }
  return steps;
}

List<WorkoutStep> _intervalSteps(
  List<ProgramItem> items,
  IntervalSettings settings,
) {
  final steps = <WorkoutStep>[];
  for (var cycle = 1; cycle <= settings.cycles; cycle++) {
    for (var round = 1; round <= settings.rounds; round++) {
      final exerciseId = items[(round - 1) % items.length].exerciseId;
      steps.add(
        WorkoutStep(
          kind: StepKind.work,
          exerciseId: exerciseId,
          targetSeconds: settings.workSeconds,
          round: round,
          roundCount: settings.rounds,
          cycle: cycle,
          cycleCount: settings.cycles,
        ),
      );
      final isLastRound = round == settings.rounds;
      final isLastCycle = cycle == settings.cycles;
      final rest = isLastRound
          ? (isLastCycle ? 0 : settings.restBetweenCyclesSeconds)
          : settings.restSeconds;
      if (rest > 0) {
        steps.add(
          WorkoutStep(
            kind: StepKind.rest,
            exerciseId:
                items[isLastRound ? 0 : round % items.length].exerciseId,
            targetSeconds: rest,
            cycle: cycle,
            cycleCount: settings.cycles,
          ),
        );
      }
    }
  }
  return steps;
}
