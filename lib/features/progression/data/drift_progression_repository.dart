import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/progression/domain/progression_repository.dart';
import 'package:arise/features/progression/domain/progression_state.dart';

/// Progression stockée dans la base locale.
class DriftProgressionRepository implements ProgressionRepository {
  const DriftProgressionRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<ProgressionState?> read() async {
    final json = await _database.readProgressionJson();
    return json == null ? null : decode(json);
  }

  @override
  Stream<ProgressionState?> watch() => _database.watchProgressionJson().map(
    (json) => json == null ? null : decode(json),
  );

  @override
  Future<void> save(ProgressionState state) => _database.saveProgressionJson(
    jsonEncode(state.toJson()),
    updatedAt: _clock(),
  );

  static ProgressionState decode(String json) =>
      ProgressionState.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
