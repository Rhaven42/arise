import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

/// Mesure principale d'un exercice.
enum ExerciseType { reps, duration, distance }

/// Règle de conversion du volume (ANATOMY.md §3).
enum VolumeRule { strength, cardio, interval, mobility }

/// Statut de relecture du référentiel (ANATOMY.md §5).
@JsonEnum(fieldRename: FieldRename.snake)
enum ReviewStatus { pendingReview, validated }

/// Exercice du catalogue ou créé par le joueur.
@freezed
abstract class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    required ExerciseType type,
    required VolumeRule volumeRule,

    /// Répartition des stats (somme = 1), par exemple 70 % / 30 %.
    required Map<StatId, double> stats,
    required List<MuscleId> primaryMuscles,
    @Default([]) List<MuscleId> secondaryMuscles,

    /// Muscles secondaires sollicités « faiblement » (sous-ensemble).
    @Default([]) List<MuscleId> weakMuscles,

    /// Équipement nécessaire : l'un des éléments suffit ; vide = aucun.
    @Default({}) Set<Equipment> equipmentAnyOf,
    @Default(1) int difficulty,
    @Default(ReviewStatus.validated) ReviewStatus reviewStatus,
    @Default('') String description,
    @Default([]) List<String> instructions,
    @Default([]) List<String> mistakes,

    /// Identifiant de l'animation (`assets/animations/motions.json`).
    String? motion,

    /// Vrai pour un exercice créé par le joueur (hors référentiel).
    @Default(false) bool isCustom,
  }) = _Exercise;

  const Exercise._();

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);

  /// Rôle de chaque muscle sollicité.
  Map<MuscleId, MuscleRole> get muscleRoles => {
    for (final muscle in secondaryMuscles) muscle: MuscleRole.secondary,
    for (final muscle in primaryMuscles) muscle: MuscleRole.primary,
  };

  /// Stat qui reçoit la plus grande part.
  StatId get mainStat =>
      stats.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  /// Vrai si le joueur possède l'équipement nécessaire.
  bool isAvailableWith(Set<Equipment> owned) =>
      equipmentAnyOf.isEmpty || equipmentAnyOf.any(owned.contains);

  /// Un exercice du référentiel n'est visible qu'une fois validé.
  bool get isPublishable => isCustom || reviewStatus == ReviewStatus.validated;
}
