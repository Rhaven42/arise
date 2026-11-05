import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/character_creation/domain/character_repository.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Personnage et brouillon stockés dans la base locale.
class DriftCharacterRepository implements CharacterRepository {
  const DriftCharacterRepository(this._database, this._clock);

  /// Clé du brouillon du créateur dans la table des brouillons.
  static const draftKey = 'character';

  final AppDatabase _database;
  final DateTime Function() _clock;

  @override
  Future<CharacterSheet?> read() async {
    final json = await _database.readCharacterJson();
    return json == null ? null : decode(json);
  }

  @override
  Stream<CharacterSheet?> watch() => _database.watchCharacterJson().map(
    (json) => json == null ? null : decode(json),
  );

  @override
  Future<void> save(CharacterSheet sheet) => _database.saveCharacterJson(
    jsonEncode(sheet.toJson()),
    updatedAt: _clock(),
  );

  @override
  Future<CharacterSheet?> readDraft() async {
    final json = await _database.readDraft(draftKey);
    if (json == null) return null;
    try {
      return decode(json);
    } on Object {
      // Brouillon illisible (ancienne version) : on repart de zéro.
      return null;
    }
  }

  @override
  Future<void> saveDraft(CharacterSheet sheet) => _database.saveDraft(
    key: draftKey,
    json: jsonEncode(sheet.toJson()),
    updatedAt: _clock(),
  );

  @override
  Future<void> clearDraft() => _database.deleteDraft(draftKey);

  static CharacterSheet decode(String json) => sanitizeSheet(
    CharacterSheet.fromJson(jsonDecode(json) as Map<String, dynamic>),
  );
}
