import 'dart:convert';

import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

final _session = CompletedSession(
  id: 'c1',
  programId: 'p1',
  programName: 'Haut du corps',
  format: ProgramFormat.strength,
  startedAt: DateTime.utc(2026, 11, 5, 18),
  endedAt: DateTime.utc(2026, 11, 5, 18, 30),
  sets: const [
    CompletedSet(exerciseId: 'push_up', activeSeconds: 40, reps: 12, rpe: 7),
  ],
  activeSeconds: 40,
  xpEarned: 13,
  completed: true,
);

void main() {
  test('le format v3 conserve les séances réalisées', () {
    final data = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      completedSessions: [_session],
    );
    expect(data.version, 3);
    expect(BackupCodec.decode(BackupCodec.encode(data)), data);
  });

  test('une sauvegarde v2 (phase 2) reste lisible, sans séances', () {
    final v3 = BackupCodec.create(exportedAt: testNow, profile: sampleProfile);
    final json = jsonDecode(BackupCodec.encode(v3)) as Map<String, dynamic>
      ..['version'] = 2
      ..remove('completedSessions');

    final decoded = BackupCodec.decode(jsonEncode(json));
    expect(decoded.profile, sampleProfile);
    expect(decoded.completedSessions, isEmpty);
  });

  test('les séances sont exportées puis restaurées', () async {
    final database = createTestDatabase();
    final repository = DriftBackupRepository(database);
    await repository.restore(
      BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
        completedSessions: [_session],
      ),
    );

    final snapshot = await repository.snapshot(testNow);
    expect(snapshot.completedSessions, [_session]);

    await repository.eraseAll();
    expect((await repository.snapshot(testNow)).completedSessions, isEmpty);
  });
}
