import 'dart:convert';

import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/backup/data/drift_backup_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

const _custom = Exercise(
  id: 'custom-1',
  name: 'Gainage dynamique',
  type: ExerciseType.duration,
  volumeRule: VolumeRule.cardio,
  stats: {StatId.vitality: 1},
  primaryMuscles: [MuscleId.rectusAbdominis],
  isCustom: true,
);
const _program = Program(
  id: 'p1',
  name: 'Tabata express',
  format: ProgramFormat.interval,
  items: [ProgramItem(exerciseId: 'burpee')],
  interval: IntervalSettings(
    workSeconds: 20,
    restSeconds: 10,
    rounds: 8,
    cycles: 1,
    restBetweenCyclesSeconds: 60,
  ),
);
const _session = PlannedSession(
  id: 's1',
  programId: 'p1',
  weekday: DateTime.thursday,
  minuteOfDay: 1110,
);

void main() {
  test('le format v2 conserve exercices perso, programmes et planning', () {
    final data = BackupCodec.create(
      exportedAt: testNow,
      profile: sampleProfile,
      customExercises: const [_custom],
      programs: const [_program],
      plannedSessions: const [_session],
    );
    expect(data.version, BackupCodec.currentVersion);
    expect(BackupCodec.decode(BackupCodec.encode(data)), data);
  });

  test('une sauvegarde v1 (phase 1) reste lisible', () {
    final v1 = BackupCodec.create(exportedAt: testNow, profile: sampleProfile);
    final json = jsonDecode(BackupCodec.encode(v1)) as Map<String, dynamic>
      ..['version'] = 1
      ..remove('customExercises')
      ..remove('programs')
      ..remove('plannedSessions');

    final decoded = BackupCodec.decode(jsonEncode(json));
    expect(decoded.profile, sampleProfile);
    expect(decoded.programs, isEmpty);
    expect(decoded.plannedSessions, isEmpty);
    expect(decoded.customExercises, isEmpty);
  });

  test('la restauration remplace toutes les données locales', () async {
    final database = createTestDatabase();
    final repository = DriftBackupRepository(database);
    await database.saveProgramJson('old', '{}', updatedAt: testNow);

    await repository.restore(
      BackupCodec.create(
        exportedAt: testNow,
        profile: sampleProfile,
        customExercises: const [_custom],
        programs: const [_program],
        plannedSessions: const [_session],
      ),
    );

    final snapshot = await repository.snapshot(testNow);
    expect(snapshot.programs, [_program]);
    expect(snapshot.plannedSessions, [_session]);
    expect(snapshot.customExercises, [_custom]);
  });
}
