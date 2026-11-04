import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/l10n/generated/app_localizations.dart';

/// Libellés traduits des notions liées aux exercices.
extension ExerciseLabels on AppLocalizations {
  String muscle(MuscleId muscle) => muscleName(muscle.name);

  String stat(StatId stat) => statName(stat.name);

  String exerciseTypeLabel(ExerciseType type) => exerciseType(type.name);

  /// Difficulté (1 à 3), avec les libellés de niveau du questionnaire.
  String exerciseDifficulty(int difficulty) =>
      levelLabel(FitnessLevel.values[(difficulty - 1).clamp(0, 2)].name);

  /// Résumé de la répartition des stats, par exemple « Endurance 70 % ».
  String statSplit(Exercise exercise) {
    final entries = exercise.stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => statShare(stat(e.key), (e.value * 100).round()))
        .join(' · ');
  }

  /// Équipement nécessaire, ou « Sans matériel ».
  String equipmentSummary(Exercise exercise) {
    if (exercise.equipmentAnyOf.isEmpty) return exerciseNoEquipment;
    return exercise.equipmentAnyOf
        .map((item) => equipmentLabel(item.name))
        .join(exerciseEquipmentSeparator);
  }

  /// Description accessible des muscles sollicités.
  String musclesSemantics(Exercise exercise, BodyView view) {
    String names(Iterable<MuscleId> muscles) =>
        muscles.where((m) => m.view == view).map(muscle).join(', ');
    final primary = names(exercise.primaryMuscles);
    final secondary = names(exercise.secondaryMuscles);
    return bodyMapSemantics(
      view.name,
      primary.isEmpty ? noneLabel : primary,
      secondary.isEmpty ? noneLabel : secondary,
    );
  }
}
