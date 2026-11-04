import 'dart:convert';

import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/exercise_repositories.dart';
import 'package:flutter/services.dart';

/// Catalogue embarqué dans `assets/catalog/exercises.json`.
class AssetExerciseCatalogRepository implements ExerciseCatalogRepository {
  AssetExerciseCatalogRepository(this._bundle);

  static const assetPath = 'assets/catalog/exercises.json';

  final AssetBundle _bundle;
  Future<List<Exercise>>? _cache;

  @override
  Future<List<Exercise>> loadCatalog() =>
      _cache ??= _bundle.loadString(assetPath).then(decodeCatalog);

  @override
  Future<Exercise?> findById(String id) async {
    for (final exercise in await loadCatalog()) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  /// Décode le fichier du catalogue.
  static List<Exercise> decodeCatalog(String content) {
    final json = jsonDecode(content) as Map<String, dynamic>;
    return [
      for (final item in json['exercises'] as List<dynamic>)
        Exercise.fromJson(item as Map<String, dynamic>),
    ];
  }
}
