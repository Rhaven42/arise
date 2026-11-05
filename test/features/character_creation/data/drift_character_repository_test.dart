import 'package:arise/features/character_creation/data/drift_character_repository.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('enregistre le personnage et son brouillon', () async {
    final database = createTestDatabase();
    final repository = DriftCharacterRepository(database, () => testNow);
    expect(await repository.read(), isNull);
    expect(await repository.readDraft(), isNull);

    final draft = defaultSheet(race: CharacterRace.orc).copyWith(name: 'Gor');
    await repository.saveDraft(draft);
    expect(await repository.readDraft(), draft);

    await repository.save(draft.copyWith(name: 'Gorak'));
    await repository.clearDraft();
    expect(await repository.readDraft(), isNull);
    expect((await repository.read())?.name, 'Gorak');
    expect((await repository.watch().first)?.race, CharacterRace.orc);

    await database.eraseAll();
    expect(await repository.read(), isNull);
  });

  test('un brouillon illisible est ignoré', () async {
    final database = createTestDatabase();
    await database.saveDraft(
      key: DriftCharacterRepository.draftKey,
      json: '{"race":"dragon"}',
      updatedAt: testNow,
    );
    final repository = DriftCharacterRepository(database, () => testNow);
    expect(await repository.readDraft(), isNull);
  });
}
