import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/exercises/data/asset_exercise_catalog_repository.dart';
import 'package:arise/features/exercises/data/drift_custom_exercise_repository.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/exercise_filter.dart';
import 'package:arise/features/exercises/domain/exercise_repositories.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_providers.g.dart';

@Riverpod(keepAlive: true)
ExerciseCatalogRepository exerciseCatalogRepository(Ref ref) =>
    AssetExerciseCatalogRepository(rootBundle);

@Riverpod(keepAlive: true)
CustomExerciseRepository customExerciseRepository(Ref ref) =>
    DriftCustomExerciseRepository(
      ref.watch(appDatabaseProvider),
      ref.watch(clockProvider),
    );

/// Catalogue officiel complet (y compris les exercices à relire).
@Riverpod(keepAlive: true)
Future<List<Exercise>> exerciseCatalog(Ref ref) =>
    ref.watch(exerciseCatalogRepositoryProvider).loadCatalog();

@Riverpod(keepAlive: true)
Stream<List<Exercise>> customExercises(Ref ref) =>
    ref.watch(customExerciseRepositoryProvider).watchAll();

/// Exercices utilisables : catalogue validé et exercices personnalisés.
@Riverpod(keepAlive: true)
Future<List<Exercise>> availableExercises(Ref ref) async {
  final catalog = await ref.watch(exerciseCatalogProvider.future);
  final custom = await ref.watch(customExercisesProvider.future);
  return [
    for (final exercise in catalog)
      if (exercise.isPublishable) exercise,
    ...custom,
  ];
}

/// Exercices utilisables, indexés par identifiant.
@Riverpod(keepAlive: true)
Future<Map<String, Exercise>> exercisesById(Ref ref) async => {
  for (final exercise in await ref.watch(availableExercisesProvider.future))
    exercise.id: exercise,
};

/// Critères de recherche de la liste des exercices.
@riverpod
class ExerciseFilterController extends _$ExerciseFilterController {
  @override
  ExerciseFilter build() => const ExerciseFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setMuscle(MuscleId? muscle) => state = state.copyWith(muscle: muscle);

  void setStat(StatId? stat) => state = state.copyWith(stat: stat);

  void setOnlyAvailable({required bool value}) =>
      state = state.copyWith(onlyAvailable: value);
}
