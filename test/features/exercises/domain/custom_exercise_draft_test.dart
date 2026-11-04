import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/custom_exercise_draft.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toucher un muscle passe de principal à secondaire puis le retire', () {
    var draft = const CustomExerciseDraft();
    draft = draft.cycleMuscle(MuscleId.quadriceps);
    expect(draft.muscles[MuscleId.quadriceps], MuscleRole.primary);
    draft = draft.cycleMuscle(MuscleId.quadriceps);
    expect(draft.muscles[MuscleId.quadriceps], MuscleRole.secondary);
    draft = draft.cycleMuscle(MuscleId.quadriceps);
    expect(draft.muscles, isEmpty);
  });

  test('signale un nom trop court ou l’absence de muscle principal', () {
    expect(const CustomExerciseDraft(name: 'Ab').issues, [
      CustomExerciseIssue.nameTooShort,
      CustomExerciseIssue.noPrimaryMuscle,
    ]);
    expect(
      CustomExerciseDraft(name: 'x' * 41).issues,
      contains(CustomExerciseIssue.nameTooLong),
    );
  });

  test('construit un exercice personnalisé valide', () {
    final draft = const CustomExerciseDraft(
      name: '  Gainage dynamique ',
      type: ExerciseType.duration,
      stat: StatId.vitality,
    )
        .cycleMuscle(MuscleId.rectusAbdominis)
        .cycleMuscle(MuscleId.obliques)
        .cycleMuscle(MuscleId.obliques);

    expect(draft.isValid, isTrue);
    final exercise = draft.toExercise(id: 'custom-1');
    expect(exercise.name, 'Gainage dynamique');
    expect(exercise.isCustom, isTrue);
    expect(exercise.primaryMuscles, [MuscleId.rectusAbdominis]);
    expect(exercise.secondaryMuscles, [MuscleId.obliques]);
    expect(exercise.stats, {StatId.vitality: 1});
    expect(exercise.volumeRule, VolumeRule.cardio);

    final back = CustomExerciseDraft.fromExercise(exercise);
    expect(back.muscles, draft.muscles);
    expect(back.stat, StatId.vitality);
  });
}
