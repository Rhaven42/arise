import 'package:arise/features/character_creation/domain/character_sheet.dart';

/// Personnage enregistré et brouillon du créateur.
abstract interface class CharacterRepository {
  Future<CharacterSheet?> read();

  Stream<CharacterSheet?> watch();

  Future<void> save(CharacterSheet sheet);

  Future<CharacterSheet?> readDraft();

  Future<void> saveDraft(CharacterSheet sheet);

  Future<void> clearDraft();
}
