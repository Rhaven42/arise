import 'dart:convert';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

final ProgressionState _progression = ProgressionState.initial(const CivilDate(2026, 11, 4))
    .copyWith(
      level: 4,
      crystals: 33,
      streakDays: 3,
      allocatedStats: {StatId.strength: 2},
      defeatedBosses: {RankId.e},
    );

void main() {
  test('le format v4 conserve la progression', () {
    final data = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      progression: _progression,
    );
    expect(data.version, 4);
    expect(BackupCodec.decode(BackupCodec.encode(data)), data);
  });

  test('une sauvegarde v3 reste lisible, sans progression', () {
    final v4 = BackupCodec.create(exportedAt: testNow, profile: sampleProfile);
    final json = jsonDecode(BackupCodec.encode(v4)) as Map<String, dynamic>
      ..['version'] = 3
      ..remove('progression');
    final decoded = BackupCodec.decode(jsonEncode(json));
    expect(decoded.progression, isNull);
  });

  test('la progression est exportée, restaurée puis effacée', () async {
    final repository = DriftBackupRepository(createTestDatabase());
    await repository.restore(
      BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
        progression: _progression,
      ),
    );
    expect((await repository.snapshot(testNow)).progression, _progression);

    await repository.eraseAll();
    expect((await repository.snapshot(testNow)).progression, isNull);
  });
}
