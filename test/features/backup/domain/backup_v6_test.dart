import 'dart:convert';

import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

const Inventory _bag = Inventory(
  owned: ['leather_chest', 'cape_dawn'],
  hairStyles: [8],
  equipped: {EquipmentSlot.back: 'cape_dawn'},
  dyes: {'cape_dawn': 0xFF27406E},
);

void main() {
  test('le format v6 conserve l’inventaire', () {
    final data = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      inventory: _bag,
    );
    expect(data.version, 6);
    expect(BackupCodec.decode(BackupCodec.encode(data)), data);
  });

  test('une sauvegarde v5 reste lisible, sans inventaire', () {
    final json =
        jsonDecode(
              BackupCodec.encode(
                BackupCodec.create(exportedAt: testNow, profile: sampleProfile),
              ),
            )
            as Map<String, dynamic>
          ..['version'] = 5
          ..remove('inventory');
    expect(BackupCodec.decode(jsonEncode(json)).inventory, isNull);
  });

  test('l’inventaire est restauré nettoyé puis effacé', () async {
    final repository = DriftBackupRepository(createTestDatabase());
    await repository.restore(
      BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
        inventory: _bag.copyWith(owned: [..._bag.owned, 'objet_inconnu']),
      ),
    );
    expect((await repository.snapshot(testNow)).inventory, _bag);

    await repository.eraseAll();
    expect((await repository.snapshot(testNow)).inventory, isNull);
  });
}
