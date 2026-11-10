import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_repository.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';

/// Inventaire stocké dans la base locale.
class DriftInventoryRepository implements InventoryRepository {
  const DriftInventoryRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<Inventory> read() async =>
      decodeOrEmpty(await _database.readInventoryJson());

  @override
  Stream<Inventory> watch() =>
      _database.watchInventoryJson().map(decodeOrEmpty);

  @override
  Future<void> save(Inventory inventory) => _database.saveInventoryJson(
    jsonEncode(sanitizeInventory(inventory).toJson()),
    updatedAt: _clock(),
  );

  static Inventory decode(String json) => sanitizeInventory(
    Inventory.fromJson(jsonDecode(json) as Map<String, dynamic>),
  );

  static Inventory decodeOrEmpty(String? json) =>
      json == null ? const Inventory() : decode(json);
}
