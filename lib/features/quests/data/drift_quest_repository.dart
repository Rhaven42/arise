import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/quests/domain/quest_repository.dart';

/// Quête quotidienne stockée dans la base locale.
class DriftQuestRepository implements QuestRepository {
  const DriftQuestRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<DailyQuest?> read() async {
    final json = await _database.readQuestJson();
    return json == null ? null : decode(json);
  }

  @override
  Future<void> save(DailyQuest quest) =>
      _database.saveQuestJson(jsonEncode(quest.toJson()), updatedAt: _clock());

  @override
  Future<void> saveWithProgression(
    DailyQuest quest,
    ProgressionState progression,
  ) => _database.saveGameState(
    updatedAt: _clock(),
    quest: jsonEncode(quest.toJson()),
    progression: jsonEncode(progression.toJson()),
  );

  static DailyQuest decode(String json) =>
      DailyQuest.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
