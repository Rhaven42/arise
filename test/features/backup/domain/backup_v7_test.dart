import 'dart:convert';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

const DailyQuest _quest = DailyQuest(
  day: CivilDate(2026, 11, 11),
  objectives: [
    QuestObjective(exerciseId: 'squat', metric: QuestMetric.reps, target: 30),
    QuestObjective(
      exerciseId: 'walking',
      metric: QuestMetric.seconds,
      target: 600,
    ),
  ],
  claimed: true,
);

final TrialsState _trials = TrialsState(
  lastDefeatAt: {RankId.d: DateTime.utc(2026, 11, 10, 18)},
  attempts: const {RankId.e: 1, RankId.d: 1},
  titles: const ['title_rockGuardian'],
);

void main() {
  test('le format v7 conserve la quête du jour et les épreuves', () {
    final data = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      quest: _quest,
      trials: _trials,
    );
    expect(data.version, 7);
    expect(BackupCodec.decode(BackupCodec.encode(data)), data);
  });

  test('une sauvegarde v6 reste lisible, sans quête ni épreuve', () {
    final json =
        jsonDecode(
            BackupCodec.encode(
              BackupCodec.create(exportedAt: testNow, profile: sampleProfile),
            ),
          ) as Map<String, dynamic>
          ..['version'] = 6
          ..remove('quest')
          ..remove('trials');
    final data = BackupCodec.decode(jsonEncode(json));
    expect(data.quest, isNull);
    expect(data.trials, isNull);
  });

  test('quête et épreuves sont restaurées puis effacées', () async {
    final repository = DriftBackupRepository(createTestDatabase());
    await repository.restore(
      BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
        quest: _quest,
        trials: _trials,
      ),
    );
    final snapshot = await repository.snapshot(testNow);
    expect(snapshot.quest, _quest);
    expect(snapshot.trials, _trials);

    await repository.eraseAll();
    final erased = await repository.snapshot(testNow);
    expect(erased.quest, isNull);
    expect(erased.trials, isNull);
  });
}
