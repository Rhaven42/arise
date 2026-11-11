import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/trials/domain/trials_repository.dart';
import 'package:arise/features/trials/domain/trials_state.dart';

/// Historique des épreuves stocké dans la base locale.
class DriftTrialsRepository implements TrialsRepository {
  const DriftTrialsRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<TrialsState?> read() async {
    final json = await _database.readTrialsJson();
    return json == null ? null : decode(json);
  }

  @override
  Stream<TrialsState?> watch() => _database.watchTrialsJson().map(
    (json) => json == null ? null : decode(json),
  );

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
    required TrialsState trials,
    required ProgressionState progression,
    Inventory? inventory,
  }) => _database.saveGameState(
    updatedAt: _clock(),
    trials: jsonEncode(trials.toJson()),
    progression: jsonEncode(progression.toJson()),
    inventory: inventory == null
        ? null
        : jsonEncode(sanitizeInventory(inventory).toJson()),
  );

  static TrialsState decode(String json) =>
      TrialsState.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
