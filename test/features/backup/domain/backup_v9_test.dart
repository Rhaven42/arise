import 'dart:convert';

import 'package:arise/features/achievements/domain/achievements_state.dart';
import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/shadows/domain/shadows_state.dart';
import 'package:arise/features/titles/domain/titles_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

final AchievementsState _achievements = AchievementsState(
  unlocked: {'first_session': DateTime.utc(2026, 11, 2, 9)},
  dailyQuestsDone: 3,
);

const TitlesState _titles = TitlesState(
  equippedTitle: 'title_awakened',
  equippedAura: 'aura_dawn',
);

final ShadowsState _shadows = ShadowsState(
  shadows: [
    Shadow(
      origin: const ShadowOrigin(
        source: ShadowSource.boss,
        key: 'boss_b',
        name: 'basaltColossus',
        stat: StatId.strength,
      ),
      extractedAt: DateTime.utc(2026, 11, 3),
      index: 0,
    ),
  ],
  active: const ['boss_b'],
  pending: const [
    ShadowOrigin(
      source: ShadowSource.dungeon,
      key: 'dungeon_2026-11-09',
      name: 'echoForest',
      stat: StatId.agility,
    ),
  ],
);

void main() {
  test('le format v9 conserve hauts faits, titres et Ombres', () {
    final data = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      achievements: _achievements,
      titles: _titles,
      shadows: _shadows,
    );
    expect(data.version, BackupCodec.currentVersion);
    expect(BackupCodec.decode(BackupCodec.encode(data)), data);
  });

  test('une sauvegarde v8 reste lisible, sans hauts faits ni Ombres', () {
    final json =
        jsonDecode(
            BackupCodec.encode(
              BackupCodec.create(exportedAt: testNow, profile: sampleProfile),
            ),
          ) as Map<String, dynamic>
          ..['version'] = 8
          ..remove('achievements')
          ..remove('titles')
          ..remove('shadows');
    final data = BackupCodec.decode(jsonEncode(json));
    expect(data.achievements, isNull);
    expect(data.titles, isNull);
    expect(data.shadows, isNull);
  });

  test('hauts faits, titres et Ombres sont restaurés puis effacés', () async {
    final repository = DriftBackupRepository(createTestDatabase());
    await repository.restore(
      BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
        achievements: _achievements,
        titles: _titles,
        shadows: _shadows,
      ),
    );
    final snapshot = await repository.snapshot(testNow);
    expect(snapshot.achievements, _achievements);
    expect(snapshot.titles, _titles);
    expect(snapshot.shadows, _shadows);

    await repository.eraseAll();
    final erased = await repository.snapshot(testNow);
    expect(erased.achievements, isNull);
    expect(erased.titles, isNull);
    expect(erased.shadows, isNull);
  });
}
