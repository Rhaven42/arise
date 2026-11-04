import 'dart:convert';

import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  group('BackupCodec', () {
    test('un export se relit à l’identique', () {
      final data = BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
      );

      expect(BackupCodec.decode(BackupCodec.encode(data)), data);
    });

    test('accepte une sauvegarde sans profil', () {
      final data = BackupCodec.create(exportedAt: testNow, profile: null);
      expect(BackupCodec.decode(BackupCodec.encode(data)).profile, isNull);
    });

    void expectRejected(String content, BackupError error) {
      expect(
        () => BackupCodec.decode(content),
        throwsA(
          isA<InvalidBackupException>().having((e) => e.error, 'error', error),
        ),
      );
    }

    test('refuse un fichier qui n’est pas du JSON', () {
      expectRejected('pas du json', BackupError.unreadable);
    });

    test('refuse un JSON étranger', () {
      expectRejected('[1, 2]', BackupError.notArise);
      expectRejected('{"format": "autre"}', BackupError.notArise);
    });

    test('refuse une version plus récente', () {
      expectRejected(
        jsonEncode({
          'format': BackupCodec.format,
          'version': BackupCodec.currentVersion + 1,
          'exportedAt': testNow.toIso8601String(),
        }),
        BackupError.tooRecent,
      );
    });

    test('refuse un contenu endommagé', () {
      expectRejected(
        jsonEncode({'format': BackupCodec.format, 'version': 'un'}),
        BackupError.corrupted,
      );
      expectRejected(
        jsonEncode({
          'format': BackupCodec.format,
          'version': 1,
          'exportedAt': testNow.toIso8601String(),
          'profile': {'goal': 'voler'},
        }),
        BackupError.corrupted,
      );
    });

    test('propose un nom de fichier daté', () {
      expect(
        BackupCodec.fileName(DateTime(2026, 3, 7)),
        'arise-sauvegarde-2026-03-07.json',
      );
    });
  });
}
