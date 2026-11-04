import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_filter.freezed.dart';

/// Critères de recherche dans le catalogue.
@freezed
abstract class ExerciseFilter with _$ExerciseFilter {
  const factory ExerciseFilter({
    @Default('') String query,
    MuscleId? muscle,
    StatId? stat,

    /// Limiter aux exercices faisables avec l'équipement du joueur.
    @Default(false) bool onlyAvailable,
  }) = _ExerciseFilter;

  const ExerciseFilter._();

  bool get isEmpty =>
      query.trim().isEmpty && muscle == null && stat == null && !onlyAvailable;
}

/// Normalise un texte pour la recherche (minuscules, sans accents).
String normalizeForSearch(String text) {
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'œ': 'oe',
    'æ': 'ae',
  };
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString().trim();
}

/// Applique [filter] et trie par nom ; seuls les exercices publiables sont
/// conservés.
List<Exercise> filterExercises(
  Iterable<Exercise> exercises,
  ExerciseFilter filter, {
  required Set<Equipment> ownedEquipment,
}) {
  final query = normalizeForSearch(filter.query);
  final muscle = filter.muscle;
  final stat = filter.stat;
  final result =
      exercises.where((exercise) {
        if (!exercise.isPublishable) return false;
        if (query.isNotEmpty &&
            !normalizeForSearch(exercise.name).contains(query)) {
          return false;
        }
        if (muscle != null && !exercise.muscleRoles.containsKey(muscle)) {
          return false;
        }
        if (stat != null && !exercise.stats.containsKey(stat)) return false;
        if (filter.onlyAvailable && !exercise.isAvailableWith(ownedEquipment)) {
          return false;
        }
        return true;
      }).toList()..sort(
        (a, b) =>
            normalizeForSearch(a.name).compareTo(normalizeForSearch(b.name)),
      );
  return result;
}
