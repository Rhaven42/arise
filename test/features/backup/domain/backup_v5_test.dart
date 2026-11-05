import 'dart:convert';

import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

final CharacterSheet _hero = defaultSheet(
  sex: CharacterSex.male,
  race: CharacterRace.elf,
).copyWith(name: 'Thalion', hairStyle: 3, corpulence: 0.25);

void main() {
  test('le format v5 conserve le personnage', () {
    final data = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      character: _hero,
    );
    expect(data.version, 5);
    expect(BackupCodec.decode(BackupCodec.encode(data)), data);
  });

  test('une sauvegarde v4 reste lisible : cristaux convertis en bronze', () {
    final v5 = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      progression: ProgressionState.initial(const CivilDate(2026, 11, 4)),
    );
    final json = jsonDecode(BackupCodec.encode(v5)) as Map<String, dynamic>;
    json['version'] = 4;
    (json['progression'] as Map<String, dynamic>)
      ..remove('coins')
      ..['crystals'] = 120;
    final decoded = BackupCodec.decode(jsonEncode(json));
    expect(decoded.character, isNull);
    expect(decoded.progression?.coins, 120);
  });

  test('le personnage est exporté, restauré puis effacé', () async {
    final repository = DriftBackupRepository(createTestDatabase());
    await repository.restore(
      BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
        character: _hero,
      ),
    );
    expect((await repository.snapshot(testNow)).character, _hero);

    await repository.eraseAll();
    expect((await repository.snapshot(testNow)).character, isNull);
  });
}
