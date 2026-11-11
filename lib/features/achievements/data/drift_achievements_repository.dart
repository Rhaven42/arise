import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/achievements/domain/achievements_repository.dart';
import 'package:arise/features/achievements/domain/achievements_state.dart';

/// État « achievements » stocké dans la base locale (JSON).
class DriftAchievementsRepository implements AchievementsRepository {
  const DriftAchievementsRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<AchievementsState> read() async =>
      decode(await _database.readAchievementsJson());

  @override
  Stream<AchievementsState> watch() =>
      _database.watchAchievementsJson().map(decode);

  @override
  Future<void> save(AchievementsState state) => _database.saveAchievementsJson(
    jsonEncode(state.toJson()),
    updatedAt: _clock(),
  );

  /// État décodé (état vide quand rien n'est encore enregistré).
  static AchievementsState decode(String? json) => json == null
      ? const AchievementsState()
      : AchievementsState.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
