import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/quests/domain/quest_board.dart';
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

  @override
  Future<QuestBoard> readBoard() async {
    final json = await _database.readQuestBoardJson();
    return json == null ? const QuestBoard() : decodeBoard(json);
  }

  @override
  Future<Inventory> readInventory() async {
    final json = await _database.readInventoryJson();
    return json == null
        ? const Inventory()
        : sanitizeInventory(
            Inventory.fromJson(jsonDecode(json) as Map<String, dynamic>),
          );
  }

  @override
  Future<void> saveOutcome({
    DailyQuest? quest,
    QuestBoard? board,
    ProgressionState? progression,
    Inventory? inventory,
  }) => _database.saveGameState(
    updatedAt: _clock(),
    quest: quest == null ? null : jsonEncode(quest.toJson()),
    questBoard: board == null ? null : jsonEncode(board.toJson()),
    progression: progression == null ? null : jsonEncode(progression.toJson()),
    inventory: inventory == null
        ? null
        : jsonEncode(sanitizeInventory(inventory).toJson()),
  );

  static QuestBoard decodeBoard(String json) =>
      QuestBoard.fromJson(jsonDecode(json) as Map<String, dynamic>);

  static DailyQuest decode(String json) =>
      DailyQuest.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
