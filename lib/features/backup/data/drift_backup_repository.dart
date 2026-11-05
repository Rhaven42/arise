import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/backup/domain/backup_data.dart';
import 'package:arise/features/backup/domain/backup_repository.dart';
import 'package:arise/features/exercises/data/drift_custom_exercise_repository.dart';
import 'package:arise/features/planning/data/drift_planning_repositories.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/progression/data/drift_progression_repository.dart';
import 'package:arise/features/workout_player/data/drift_completed_session_repository.dart';

/// Sauvegarde et restauration à partir de la base locale.
class DriftBackupRepository implements BackupRepository {
  const DriftBackupRepository(this._database);

  final AppDatabase _database;

  @override
  Future<BackupData> snapshot(DateTime now) async {
    final json = await _database.readProfileJson();
    final profile = json == null
        ? null
        : PlayerProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
    return BackupCodec.create(
      exportedAt: now,
      profile: profile,
      customExercises: [
        for (final json in await _database.readCustomExerciseJson())
          DriftCustomExerciseRepository.decode(json),
      ],
      programs: [
        for (final json in await _database.readProgramJson())
          DriftProgramRepository.decodeProgram(json),
      ],
      plannedSessions: [
        for (final json in await _database.readPlannedSessionJson())
          DriftPlanningRepository.decodeSession(json),
      ],
      completedSessions: [
        for (final json in await _database.readCompletedSessionJson())
          DriftCompletedSessionRepository.decode(json),
      ],
      progression: switch (await _database.readProgressionJson()) {
        final json? => DriftProgressionRepository.decode(json),
        null => null,
      },
    );
  }

  @override
  Future<void> restore(BackupData data) {
    return _database.transaction(() async {
      await _database.eraseAll();
      final profile = data.profile;
      final now = DateTime.now();
      if (profile != null) {
        await _database.saveProfileJson(
          jsonEncode(profile.toJson()),
          updatedAt: now,
        );
      }
      for (final exercise in data.customExercises) {
        await _database.saveCustomExerciseJson(
          exercise.id,
          jsonEncode(exercise.toJson()),
          updatedAt: now,
        );
      }
      for (final program in data.programs) {
        await _database.saveProgramJson(
          program.id,
          jsonEncode(program.toJson()),
          updatedAt: now,
        );
      }
      for (final session in data.plannedSessions) {
        await _database.savePlannedSessionJson(
          session.id,
          programId: session.programId,
          json: jsonEncode(session.toJson()),
          updatedAt: now,
        );
      }
      final progression = data.progression;
      if (progression != null) {
        await _database.saveProgressionJson(
          jsonEncode(progression.toJson()),
          updatedAt: now,
        );
      }
      for (final session in data.completedSessions) {
        await _database.saveCompletedSessionJson(
          session.id,
          startedAt: session.startedAt,
          json: jsonEncode(session.toJson()),
        );
      }
    });
  }

  @override
  Future<void> eraseAll() => _database.eraseAll();
}
