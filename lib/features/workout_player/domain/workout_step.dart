import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_step.freezed.dart';

/// Nature d'une étape de séance.
enum StepKind { work, rest }

/// Étape du lecteur de séance : un effort ou un repos.
///
/// Une étape avec [targetSeconds] se déroule avec un compte à rebours ; les
/// autres efforts (répétitions, distance) se terminent quand le joueur le
/// confirme.
@freezed
abstract class WorkoutStep with _$WorkoutStep {
  const factory WorkoutStep({
    required StepKind kind,

    /// Exercice de l'effort, ou exercice suivant pendant un repos.
    String? exerciseId,
    int? targetReps,
    int? targetSeconds,
    int? targetMeters,
    double? loadKg,

    /// Musculation : numéro de la série et nombre total de séries.
    int? setNumber,
    int? setCount,

    /// Tabata, HIIT ou circuit : round et cycle en cours.
    int? round,
    int? roundCount,
    int? cycle,
    int? cycleCount,

    /// Vrai si l'intensité ressentie est demandée à la fin de l'effort.
    @Default(false) bool asksIntensity,
  }) = _WorkoutStep;

  const WorkoutStep._();

  bool get isWork => kind == StepKind.work;

  bool get isTimed => targetSeconds != null;
}
