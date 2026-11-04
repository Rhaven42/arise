import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/backup/presentation/backup_controller.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_backup_file_gateway.dart';
import '../../../helpers/test_app.dart';

void main() {
  test('exporte un fichier daté contenant le profil', () async {
    final files = FakeBackupFileGateway();
    final container = createTestContainer(files: files);
    await container.read(profileRepositoryProvider).saveProfile(sampleProfile);

    final shared = await container
        .read(backupControllerProvider.notifier)
        .exportBackup();

    expect(shared, isTrue);
    expect(files.shared.single.fileName, BackupCodec.fileName(testNow));
    expect(
      BackupCodec.decode(files.shared.single.content).profile,
      sampleProfile,
    );
  });

  test('signale une sélection annulée', () async {
    final container = createTestContainer(files: FakeBackupFileGateway());

    final result = await container
        .read(backupControllerProvider.notifier)
        .pickBackup();

    expect(result, isA<BackupPickCancelled>());
  });

  test('refuse un fichier invalide sans rien modifier', () async {
    final container = createTestContainer(
      files: FakeBackupFileGateway(fileToPick: '{"format": "autre"}'),
    );
    await container.read(profileRepositoryProvider).saveProfile(sampleProfile);

    final result = await container
        .read(backupControllerProvider.notifier)
        .pickBackup();

    expect(
      result,
      isA<BackupPickInvalid>().having(
        (r) => r.error,
        'error',
        BackupError.notArise,
      ),
    );
    expect(
      await container.read(profileRepositoryProvider).watchProfile().first,
      sampleProfile,
    );
  });

  test('restaure une sauvegarde valide', () async {
    final backup = BackupCodec.encode(
      BackupCodec.create(exportedAt: testNow, profile: sampleProfile),
    );
    final container = createTestContainer(
      files: FakeBackupFileGateway(fileToPick: backup),
    );
    final controller = container.read(backupControllerProvider.notifier);

    final result = await controller.pickBackup();
    expect(result, isA<BackupPickReady>());
    await controller.restore((result as BackupPickReady).data);

    expect(
      await container.read(profileRepositoryProvider).watchProfile().first,
      sampleProfile,
    );
  });
}
