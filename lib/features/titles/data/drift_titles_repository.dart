import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/titles/domain/titles_repository.dart';
import 'package:arise/features/titles/domain/titles_state.dart';

/// État « titles » stocké dans la base locale (JSON).
class DriftTitlesRepository implements TitlesRepository {
  const DriftTitlesRepository(this._database, this._clock);

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<TitlesState> read() async => decode(await _database.readTitlesJson());

  @override
  Stream<TitlesState> watch() => _database.watchTitlesJson().map(decode);

  @override
  Future<void> save(TitlesState state) =>
      _database.saveTitlesJson(jsonEncode(state.toJson()), updatedAt: _clock());

  /// État décodé (état vide quand rien n'est encore enregistré).
  static TitlesState decode(String? json) => json == null
      ? const TitlesState()
      : TitlesState.fromJson(jsonDecode(json) as Map<String, dynamic>);
}
