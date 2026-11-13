import 'dart:convert';

import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/health/domain/health_log.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

const HealthLog _health = HealthLog(
  days: [
    HealthDay(
      day: CivilDate(2026, 11, 3),
      steps: 8400,
      activityMinutes: 25,
      sleepMinutes: 450,
      glasses: 6,
      credited: {StatId.endurance: 28, StatId.vitality: 15},
    ),
  ],
);

void main() {
  test('le format v10 conserve l historique santé', () {
    final data = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      health: _health,
    );
    expect(data.version, 10);
    expect(BackupCodec.decode(BackupCodec.encode(data)), data);
  });

  test('une sauvegarde v9 reste lisible, sans santé', () {
    final json =
        jsonDecode(
            BackupCodec.encode(
              BackupCodec.create(
                exportedAt: testNow,
                profile: sampleProfile,
                health: _health,
              ),
            ),
          ) as Map<String, dynamic>
          ..['version'] = 9
          ..remove('health');
    expect(BackupCodec.decode(jsonEncode(json)).health, isNull);
  });

  test('la santé est restaurée puis effacée', () async {
    final repository = DriftBackupRepository(createTestDatabase());
    await repository.restore(
      BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
        health: _health,
      ),
    );
    expect((await repository.snapshot(testNow)).health, _health);

    await repository.eraseAll();
    expect((await repository.snapshot(testNow)).health, isNull);
  });
}
