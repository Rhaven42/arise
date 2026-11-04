import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/exercise_repositories.dart';

/// Exercices personnalisés stockés dans la base locale.
class DriftCustomExerciseRepository implements CustomExerciseRepository {
  const DriftCustomExerciseRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Stream<List<Exercise>> watchAll() => _database.watchCustomExerciseJson().map(
    (rows) => [for (final json in rows) decode(json)],
  );

  @override
  Future<void> save(Exercise exercise) => _database.saveCustomExerciseJson(
    exercise.id,
    jsonEncode(exercise.toJson()),
    updatedAt: _clock(),
  );

  @override
  Future<void> delete(String id) => _database.deleteCustomExercise(id);

  static Exercise decode(String json) =>
      Exercise.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
