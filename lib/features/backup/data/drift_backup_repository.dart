import 'dart:convert';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/features/achievements/data/drift_achievements_repository.dart';
import 'package:arise/features/backup/domain/backup_codec.dart';
import 'package:arise/features/backup/domain/backup_data.dart';
import 'package:arise/features/backup/domain/backup_repository.dart';
import 'package:arise/features/character_creation/data/drift_character_repository.dart';
import 'package:arise/features/exercises/data/drift_custom_exercise_repository.dart';
import 'package:arise/features/health/data/drift_health_repository.dart';
import 'package:arise/features/inventory/data/drift_inventory_repository.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/planning/data/drift_planning_repositories.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/progression/data/drift_progression_repository.dart';
import 'package:arise/features/quests/data/drift_quest_repository.dart';
import 'package:arise/features/shadows/data/drift_shadows_repository.dart';
import 'package:arise/features/titles/data/drift_titles_repository.dart';
import 'package:arise/features/trials/data/drift_trials_repository.dart';
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
      character: switch (await _database.readCharacterJson()) {
        final json? => DriftCharacterRepository.decode(json),
        null => null,
      },
      inventory: switch (await _database.readInventoryJson()) {
        final json? => DriftInventoryRepository.decode(json),
        null => null,
      },
      quest: switch (await _database.readQuestJson()) {
        final json? => DriftQuestRepository.decode(json),
        null => null,
      },
      trials: switch (await _database.readTrialsJson()) {
        final json? => DriftTrialsRepository.decode(json),
        null => null,
      },
      questBoard: switch (await _database.readQuestBoardJson()) {
        final json? => DriftQuestRepository.decodeBoard(json),
        null => null,
      },
      achievements: switch (await _database.readAchievementsJson()) {
        final json? => DriftAchievementsRepository.decode(json),
        null => null,
      },
      titles: switch (await _database.readTitlesJson()) {
        final json? => DriftTitlesRepository.decode(json),
        null => null,
      },
      shadows: switch (await _database.readShadowsJson()) {
        final json? => DriftShadowsRepository.decode(json),
        null => null,
      },
      health: switch (await _database.readHealthJson()) {
        final json? => DriftHealthRepository.decode(json),
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
      final character = data.character;
      if (character != null) {
        await _database.saveCharacterJson(
          jsonEncode(character.toJson()),
          updatedAt: now,
        );
      }
      final inventory = data.inventory;
      if (inventory != null) {
        await _database.saveInventoryJson(
          jsonEncode(sanitizeInventory(inventory).toJson()),
          updatedAt: now,
        );
      }
      final quest = data.quest;
      if (quest != null) {
        await _database.saveQuestJson(
          jsonEncode(quest.toJson()),
          updatedAt: now,
        );
      }
      final board = data.questBoard;
      if (board != null) {
        await _database.saveQuestBoardJson(
          jsonEncode(board.toJson()),
          updatedAt: now,
        );
      }
      final trials = data.trials;
      if (trials != null) {
        await _database.saveTrialsJson(
          jsonEncode(trials.toJson()),
          updatedAt: now,
        );
      }
      // Phase 9 : absents des sauvegardes plus anciennes (les hauts faits
      // sont alors recalculés à partir de l'historique).
      if (data.achievements case final achievements?) {
        await _database.saveAchievementsJson(
          jsonEncode(achievements.toJson()),
          updatedAt: now,
        );
      }
      if (data.titles case final titles?) {
        await _database.saveTitlesJson(
          jsonEncode(titles.toJson()),
          updatedAt: now,
        );
      }
      if (data.shadows case final shadows?) {
        await _database.saveShadowsJson(
          jsonEncode(shadows.toJson()),
          updatedAt: now,
        );
      }
      if (data.health case final health?) {
        await _database.saveHealthJson(
          jsonEncode(health.toJson()),
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
