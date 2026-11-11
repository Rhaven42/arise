import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/shadows/domain/shadows_repository.dart';
import 'package:arise/features/shadows/domain/shadows_state.dart';

/// État « shadows » stocké dans la base locale (JSON).
class DriftShadowsRepository implements ShadowsRepository {
  const DriftShadowsRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<ShadowsState> read() async =>
      decode(await _database.readShadowsJson());

  @override
  Stream<ShadowsState> watch() => _database.watchShadowsJson().map(decode);

  @override
  Future<void> save(ShadowsState state) => _database.saveShadowsJson(
    jsonEncode(state.toJson()),
    updatedAt: _clock(),
  );

  /// État décodé (état vide quand rien n'est encore enregistré).
  static ShadowsState decode(String? json) => json == null
      ? const ShadowsState()
      : ShadowsState.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
