import 'package:arise/features/exercises/domain/exercise.dart';

/// Catalogue officiel (lecture seule).
abstract interface class ExerciseCatalogRepository {
  Future<List<Exercise>> loadCatalog();

  Future<Exercise?> findById(String id);
}

/// Exercices créés par le joueur, stockés sur l'appareil.
abstract interface class CustomExerciseRepository {
  Stream<List<Exercise>> watchAll();

  Future<void> save(Exercise exercise);

  Future<void> delete(String id);
}
