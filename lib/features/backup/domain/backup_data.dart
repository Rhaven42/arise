import 'package:arise/features/character_creation/domain/character_sheet.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/quests/domain/quest_board.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_data.freezed.dart';
part 'backup_data.g.dart';

/// Contenu d'un fichier de sauvegarde ARISE.
@freezed
abstract class BackupData with _$BackupData {
  const factory BackupData({
    required String format,
    required int version,
    required DateTime exportedAt,
    PlayerProfile? profile,

    /// Ajouts du format v2 (phase 2) ; absents des fichiers v1.
    @Default([]) List<Exercise> customExercises,
    @Default([]) List<Program> programs,
    @Default([]) List<PlannedSession> plannedSessions,

    /// Ajout du format v3 (phase 3) ; absent des fichiers v1 et v2.
    @Default([]) List<CompletedSession> completedSessions,

    /// Ajout du format v4 (phase 4) ; absent avant : recalculée à partir
    /// des séances.
    ProgressionState? progression,

    /// Ajout du format v5 (phase 6) : fiche du personnage.
    CharacterSheet? character,

    /// Ajout du format v6 (phase 7) : objets, coiffures débloquées, tenue.
    Inventory? inventory,

    /// Ajouts du format v7 (phase 8A) : quête du jour et épreuves de rang.
    DailyQuest? quest,
    TrialsState? trials,

    /// Ajout du format v8 (phase 8B) : semaine, donjon, événements.
    QuestBoard? questBoard,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}
