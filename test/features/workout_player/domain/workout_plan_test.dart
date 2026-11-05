import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/workout_plan.dart';
import 'package:arise/features/workout_player/domain/workout_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un programme vide ne produit aucune étape', () {
    const program = Program(
      id: 'p',
      name: 'Vide',
      format: ProgramFormat.cardio,
    );
    expect(buildWorkoutSteps(program), isEmpty);
  });

  group('musculation', () {
    const program = Program(
      id: 'p',
      name: 'Haut du corps',
      format: ProgramFormat.strength,
      items: [
        ProgramItem(exerciseId: 'push_up', sets: 2, reps: 15, restSeconds: 60),
        ProgramItem(
          exerciseId: 'plank',
          sets: 1,
          durationSeconds: 45,
          restSeconds: 30,
          loadKg: 5,
        ),
      ],
    );

    test('alterne séries et repos, sans repos après la dernière série', () {
      final steps = buildWorkoutSteps(program);
      expect(
        [for (final s in steps) s.kind],
        [
          StepKind.work,
          StepKind.rest,
          StepKind.work,
          StepKind.rest,
          StepKind.work,
        ],
      );
      expect(steps.first.targetReps, 15);
      expect(steps.first.setNumber, 1);
      expect(steps.first.setCount, 2);
      expect(steps.first.asksIntensity, isTrue);
      expect(steps[1].targetSeconds, 60);
    });

    test('annonce le prochain exercice pendant le repos', () {
      final steps = buildWorkoutSteps(program);
      expect(steps[1].exerciseId, 'push_up');
      expect(steps[3].exerciseId, 'plank');
    });

    test('une série chronométrée devient un compte à rebours', () {
      final last = buildWorkoutSteps(program).last;
      expect(last.targetSeconds, 45);
      expect(last.targetReps, isNull);
      expect(last.loadKg, 5);
      expect(last.isTimed, isTrue);
    });

    test('un repos nul ne crée pas d’étape de repos', () {
      const noRest = Program(
        id: 'p',
        name: 'Sans repos',
        format: ProgramFormat.strength,
        items: [ProgramItem(exerciseId: 'squat', sets: 3, reps: 10)],
      );
      expect(buildWorkoutSteps(noRest), hasLength(3));
    });
  });

  group('Tabata, HIIT et circuit', () {
    const program = Program(
      id: 'p',
      name: 'Tabata',
      format: ProgramFormat.interval,
      items: [
        ProgramItem(exerciseId: 'burpee'),
        ProgramItem(exerciseId: 'jumping_jack'),
      ],
      interval: IntervalSettings(
        workSeconds: 20,
        restSeconds: 10,
        rounds: 3,
        cycles: 2,
        restBetweenCyclesSeconds: 60,
      ),
    );

    test('enchaîne les rounds et les cycles', () {
      final steps = buildWorkoutSteps(program);
      final work = steps.where((s) => s.isWork).toList();
      expect(work, hasLength(6));
      expect(
        [for (final s in work) s.exerciseId],
        [
          'burpee',
          'jumping_jack',
          'burpee',
          'burpee',
          'jumping_jack',
          'burpee',
        ],
      );
      expect(work.every((s) => s.targetSeconds == 20), isTrue);
      expect(work.any((s) => s.asksIntensity), isFalse);
    });

    test('place le repos entre les cycles, rien après le dernier round', () {
      final steps = buildWorkoutSteps(program);
      final rests = [
        for (final s in steps)
          if (!s.isWork) s.targetSeconds,
      ];
      expect(rests, [10, 10, 60, 10, 10]);
      expect(steps.last.isWork, isTrue);
      // Le repos entre les cycles annonce le premier exercice du cycle.
      expect(
        steps.firstWhere((s) => s.targetSeconds == 60).exerciseId,
        'burpee',
      );
    });

    test('utilise les valeurs par défaut si les temps manquent', () {
      const defaults = Program(
        id: 'p',
        name: 'Défaut',
        format: ProgramFormat.interval,
        items: [ProgramItem(exerciseId: 'burpee')],
      );
      final work = buildWorkoutSteps(defaults).where((s) => s.isWork);
      expect(work, hasLength(IntervalSettings.defaults().rounds));
    });
  });

  test('le cardio suit la durée ou la distance', () {
    const program = Program(
      id: 'p',
      name: 'Cardio',
      format: ProgramFormat.cardio,
      items: [
        ProgramItem(exerciseId: 'walking', durationSeconds: 1200),
        ProgramItem(exerciseId: 'running', distanceMeters: 3000),
      ],
    );
    final steps = buildWorkoutSteps(program);
    expect(steps.first.targetSeconds, 1200);
    expect(steps.last.targetMeters, 3000);
    expect(steps.last.isTimed, isFalse);
  });

  test('la mobilité chronomètre chaque maintien', () {
    const program = Program(
      id: 'p',
      name: 'Mobilité',
      format: ProgramFormat.mobility,
      items: [ProgramItem(exerciseId: 'stretch', holdSeconds: 30)],
    );
    expect(buildWorkoutSteps(program).single.targetSeconds, 30);
  });
}
