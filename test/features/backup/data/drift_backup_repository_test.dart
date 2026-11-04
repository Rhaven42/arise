import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/profile/data/drift_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  test('la photographie contient le profil enregistré', () async {
    final database = createTestDatabase();
    await DriftProfileRepository(database).saveProfile(sampleProfile);

    final data = await DriftBackupRepository(database).snapshot(testNow);

    expect(data.format, BackupCodec.format);
    expect(data.version, BackupCodec.currentVersion);
    expect(data.exportedAt, testNow);
    expect(data.profile, sampleProfile);
  });

  test('la restauration remplace toutes les données locales', () async {
    final database = createTestDatabase();
    final repository = DriftBackupRepository(database);
    await DriftProfileRepository(
      database,
    ).saveProfile(sampleProfile.copyWith(healthConsent: true));
    await database.saveDraft(key: 'x', json: '{}', updatedAt: testNow);

    await repository.restore(
      BackupCodec.create(exportedAt: testNow, profile: sampleProfile),
    );

    expect((await repository.snapshot(testNow)).profile, sampleProfile);
    expect(await database.readDraft('x'), isNull);
  });

  test('l’effacement supprime le profil et les brouillons', () async {
    final database = createTestDatabase();
    final repository = DriftBackupRepository(database);
    await DriftProfileRepository(database).saveProfile(sampleProfile);
    await database.saveDraft(key: 'x', json: '{}', updatedAt: testNow);

    await repository.eraseAll();

    expect((await repository.snapshot(testNow)).profile, isNull);
    expect(await database.readDraft('x'), isNull);
  });
}
