import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/session_summary.dart';
import 'package:arise/features/workout_player/domain/workout_plan.dart';
import 'package:arise/features/workout_player/domain/workout_run.dart';
import 'package:flutter_test/flutter_test.dart';

const _pushUp = Exercise(
  id: 'push_up',
  name: 'Pompes',
  type: ExerciseType.reps,
  volumeRule: VolumeRule.strength,
  stats: {StatId.strength: 1},
  primaryMuscles: [MuscleId.pectoralisMidLower, MuscleId.tricepsBrachii],
  secondaryMuscles: [MuscleId.rectusAbdominis],
);
const _plank = Exercise(
  id: 'plank',
  name: 'Planche',
  type: ExerciseType.duration,
  volumeRule: VolumeRule.strength,
  stats: {StatId.vitality: 1},
  primaryMuscles: [MuscleId.rectusAbdominis],
  secondaryMuscles: [MuscleId.obliques],
);
const _exercises = {'push_up': _pushUp, 'plank': _plank};
const _program = Program(
  id: 'p1',
  name: 'Haut du corps',
  format: ProgramFormat.strength,
  items: [
    ProgramItem(exerciseId: 'push_up', sets: 1, reps: 10, restSeconds: 0),
    ProgramItem(exerciseId: 'plank', sets: 1, durationSeconds: 30),
  ],
);

void main() {
  final t0 = DateTime.utc(2026, 11, 5, 18);

  test('résume une séance complète avec son XP et ses efforts', () {
    var run = WorkoutRun.start(buildWorkoutSteps(_program), t0);
    run = run
        .completeWork(t0.add(const Duration(seconds: 40)), reps: 12)
        .submitIntensity(t0.add(const Duration(seconds: 45)), 7)
        .tick(t0.add(const Duration(seconds: 75)))
        .submitIntensity(t0.add(const Duration(seconds: 80)), 8);

    final session = summarizeRun(
      id: 's1',
      program: _program,
      run: run,
      exercisesById: _exercises,
      priorActiveSecondsToday: 0,
      now: t0.add(const Duration(seconds: 80)),
    );

    expect(session.completed, isTrue);
    expect(session.programId, 'p1');
    expect(session.sets.first.reps, 12);
    expect(session.sets.last.activeSeconds, 30);
    expect(session.activeSeconds, 70);
    expect(session.xpEarned, greaterThan(0));
    expect(session.stoppedForPain, isFalse);
  });

  test('un muscle principal dans un exercice reste principal', () {
    var run = WorkoutRun.start(buildWorkoutSteps(_program), t0);
    run = run
        .completeWork(t0)
        .submitIntensity(t0, 6)
        .tick(t0.add(const Duration(seconds: 30)))
        .submitIntensity(t0, 6);
    final session = summarizeRun(
      id: 's',
      program: _program,
      run: run,
      exercisesById: _exercises,
      priorActiveSecondsToday: 0,
      now: t0,
    );
    final roles = workedMuscles(session, _exercises);
    expect(roles[MuscleId.rectusAbdominis], MuscleRole.primary);
    expect(roles[MuscleId.obliques], MuscleRole.secondary);
    expect(roles[MuscleId.tricepsBrachii], MuscleRole.primary);
  });

  test('l’arrêt pour douleur est signalé et la séance incomplète', () {
    final run = WorkoutRun.start(
      buildWorkoutSteps(_program),
      t0,
    ).stop(t0, StopReason.painOrDiscomfort);
    final session = summarizeRun(
      id: 's',
      program: _program,
      run: run,
      exercisesById: _exercises,
      priorActiveSecondsToday: 0,
      now: t0,
    );
    expect(session.stoppedForPain, isTrue);
    expect(session.completed, isFalse);
    expect(session.xpEarned, 0);
    expect(workedMuscles(session, _exercises), isEmpty);
  });
}
