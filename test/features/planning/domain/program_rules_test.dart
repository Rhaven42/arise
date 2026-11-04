import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/domain/program_rules.dart';
import 'package:flutter_test/flutter_test.dart';

const _squat = Exercise(
  id: 'squat',
  name: 'Squat',
  type: ExerciseType.reps,
  volumeRule: VolumeRule.strength,
  stats: {StatId.strength: 1},
  primaryMuscles: [MuscleId.quadriceps],
);

const _plank = Exercise(
  id: 'plank',
  name: 'Planche',
  type: ExerciseType.duration,
  volumeRule: VolumeRule.strength,
  stats: {StatId.vitality: 1},
  primaryMuscles: [MuscleId.rectusAbdominis],
);

Program _program(ProgramFormat format, List<ProgramItem> items) =>
    newProgram(id: 'p', format: format).copyWith(name: 'Séance', items: items);

void main() {
  group('paramètres par défaut', () {
    test('musculation : 3 séries, répétitions ou durée selon l’exercice', () {
      final reps = ProgramItem.defaultsFor(_squat, ProgramFormat.strength);
      expect((reps.sets, reps.reps, reps.durationSeconds), (3, 10, null));
      final hold = ProgramItem.defaultsFor(_plank, ProgramFormat.strength);
      expect((hold.reps, hold.durationSeconds), (null, 30));
    });

    test('Tabata : 20 s de travail, 10 s de repos, 8 rounds', () {
      final program = newProgram(id: 'p', format: ProgramFormat.interval);
      final defaults = gameConfig.intervalDefaults;
      expect(program.interval?.workSeconds, defaults.workSeconds);
      expect(program.interval?.restSeconds, defaults.restSeconds);
      expect(program.interval?.rounds, defaults.rounds);
      expect(
        (defaults.workSeconds, defaults.restSeconds, defaults.rounds),
        (20, 10, 8),
      );
    });
  });

  group('validateProgram', () {
    test('un programme complet est valide', () {
      final program = _program(ProgramFormat.strength, [
        ProgramItem.defaultsFor(_squat, ProgramFormat.strength),
      ]);
      expect(validateProgram(program), isEmpty);
    });

    test('exige un nom et au moins un exercice', () {
      final program = newProgram(id: 'p', format: ProgramFormat.cardio);
      expect(validateProgram(program), {
        ProgramIssue.nameTooShort,
        ProgramIssue.noExercise,
      });
    });

    test('refuse les valeurs hors limites', () {
      final program = _program(ProgramFormat.strength, [
        const ProgramItem(
          exerciseId: 'squat',
          sets: 0,
          reps: 10,
          restSeconds: 60,
        ),
        const ProgramItem(
          exerciseId: 'squat',
          sets: 3,
          reps: 10,
          restSeconds: -1,
        ),
        const ProgramItem(exerciseId: 'squat', sets: 3, restSeconds: 60),
      ]);
      expect(validateProgram(program), {
        ProgramIssue.invalidSets,
        ProgramIssue.invalidRest,
        ProgramIssue.invalidReps,
      });
    });

    test('cardio : une durée ou une distance, pas les deux', () {
      final program = _program(ProgramFormat.cardio, [
        const ProgramItem(
          exerciseId: 'run',
          durationSeconds: 600,
          distanceMeters: 2000,
        ),
      ]);
      expect(validateProgram(program), {ProgramIssue.invalidDuration});
    });

    test('intervalles : réglages obligatoires et bornés', () {
      final program = _program(ProgramFormat.interval, [
        const ProgramItem(exerciseId: 'squat'),
      ]);
      expect(validateProgram(program), isEmpty);
      expect(
        validateProgram(
          program.copyWith(interval: program.interval!.copyWith(rounds: 0)),
        ),
        {ProgramIssue.invalidInterval},
      );
    });
  });

  test('changer de format remet les paramètres par défaut', () {
    final program = _program(ProgramFormat.strength, [
      ProgramItem.defaultsFor(_squat, ProgramFormat.strength),
    ]);
    final mobility = changeFormat(program, ProgramFormat.mobility, {
      'squat': _squat,
    });
    expect(
      mobility.items.single,
      const ProgramItem(exerciseId: 'squat', holdSeconds: 30),
    );
    expect(mobility.interval, isNull);
    final interval = changeFormat(program, ProgramFormat.interval, {
      'squat': _squat,
    });
    expect(interval.interval, IntervalSettings.defaults());
  });

  group('estimateDuration', () {
    test('Tabata par défaut : 8 × (20 s + 10 s) = 4 minutes', () {
      final program = _program(ProgramFormat.interval, [
        const ProgramItem(exerciseId: 'squat'),
      ]);
      expect(estimateDuration(program), const Duration(minutes: 4));
    });

    test('musculation : séries, répétitions et repos', () {
      final program = _program(ProgramFormat.strength, [
        const ProgramItem(
          exerciseId: 'squat',
          sets: 3,
          reps: 10,
          restSeconds: 60,
        ),
      ]);
      // 3 × 10 rép. × 3 s + 2 repos de 60 s.
      expect(estimateDuration(program), const Duration(seconds: 210));
    });

    test('cardio à la distance : durée inconnue', () {
      final program = _program(ProgramFormat.cardio, [
        const ProgramItem(exerciseId: 'run', distanceMeters: 5000),
      ]);
      expect(estimateDuration(program), isNull);
    });
  });

  test('sérialisation JSON aller-retour', () {
    final program = _program(ProgramFormat.interval, [
      const ProgramItem(exerciseId: 'squat'),
    ]);
    expect(Program.fromJson(program.toJson()), program);
  });
}
