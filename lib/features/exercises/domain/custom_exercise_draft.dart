import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'custom_exercise_draft.freezed.dart';

/// Problème empêchant d'enregistrer un exercice personnalisé.
enum CustomExerciseIssue { nameTooShort, nameTooLong, noPrimaryMuscle }

/// Exercice personnalisé en cours d'édition.
@freezed
abstract class CustomExerciseDraft with _$CustomExerciseDraft {
  const factory CustomExerciseDraft({
    @Default('') String name,
    @Default(ExerciseType.reps) ExerciseType type,
    @Default(StatId.strength) StatId stat,
    @Default({}) Map<MuscleId, MuscleRole> muscles,
  }) = _CustomExerciseDraft;

  const CustomExerciseDraft._();

  /// Reprend un exercice personnalisé existant.
  factory CustomExerciseDraft.fromExercise(Exercise exercise) =>
      CustomExerciseDraft(
        name: exercise.name,
        type: exercise.type,
        stat: exercise.mainStat,
        muscles: exercise.muscleRoles,
      );

  static const nameMinLength = 3;
  static const nameMaxLength = 40;

  /// Rôle suivant au toucher : aucun → principal → secondaire → aucun.
  CustomExerciseDraft cycleMuscle(MuscleId muscle) {
    final next = {...muscles};
    switch (muscles[muscle]) {
      case null:
        next[muscle] = MuscleRole.primary;
      case MuscleRole.primary:
        next[muscle] = MuscleRole.secondary;
      case MuscleRole.secondary:
        next.remove(muscle);
    }
    return copyWith(muscles: next);
  }

  List<CustomExerciseIssue> get issues {
    final trimmed = name.trim();
    return [
      if (trimmed.length < nameMinLength) CustomExerciseIssue.nameTooShort,
      if (trimmed.length > nameMaxLength) CustomExerciseIssue.nameTooLong,
      if (!muscles.containsValue(MuscleRole.primary))
        CustomExerciseIssue.noPrimaryMuscle,
    ];
  }

  bool get isValid => issues.isEmpty;

  /// Construit l'exercice ; à n'appeler que si [isValid].
  Exercise toExercise({required String id}) {
    List<MuscleId> withRole(MuscleRole role) => [
      for (final muscle in MuscleId.values)
        if (muscles[muscle] == role) muscle,
    ];
    return Exercise(
      id: id,
      name: name.trim(),
      type: type,
      volumeRule: switch (type) {
        ExerciseType.reps => VolumeRule.strength,
        ExerciseType.duration || ExerciseType.distance => VolumeRule.cardio,
      },
      stats: {stat: 1},
      primaryMuscles: withRole(MuscleRole.primary),
      secondaryMuscles: withRole(MuscleRole.secondary),
      isCustom: true,
    );
  }
}
