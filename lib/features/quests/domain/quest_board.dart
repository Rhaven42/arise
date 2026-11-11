import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_board.freezed.dart';
part 'quest_board.g.dart';

/// Mesure d'un objectif de la quête hebdomadaire.
enum WeeklyMetric {
  /// Séances complètes.
  sessions,

  /// Minutes d'effort actif (repos exclus).
  activeMinutes,

  /// Quêtes du jour accomplies.
  dailyQuests,
}

@freezed
abstract class WeeklyObjective with _$WeeklyObjective {
  const factory WeeklyObjective({
    required WeeklyMetric metric,
    required int target,
  }) = _WeeklyObjective;

  factory WeeklyObjective.fromJson(Map<String, dynamic> json) =>
      _$WeeklyObjectiveFromJson(json);
}

/// Quête hebdomadaire (du lundi au dimanche).
@freezed
abstract class WeeklyQuest with _$WeeklyQuest {
  const factory WeeklyQuest({
    @CivilDateConverter() required CivilDate weekStart,
    @Default([]) List<WeeklyObjective> objectives,

    /// Jours de la semaine où la quête du jour a été accomplie.
    @Default([]) List<String> dailyQuestDays,
    @Default(false) bool claimed,
  }) = _WeeklyQuest;

  factory WeeklyQuest.fromJson(Map<String, dynamic> json) =>
      _$WeeklyQuestFromJson(json);
}

/// Thème du donjon de la semaine.
enum DungeonTheme { stoneCrypt, echoForest, windTower }

/// Donjon hebdomadaire : trois salles à franchir dans l'ordre, une par jour
/// au plus ; butin cosmétique à la sortie.
@freezed
abstract class DungeonRun with _$DungeonRun {
  const factory DungeonRun({
    @CivilDateConverter() required CivilDate weekStart,
    required DungeonTheme theme,

    /// Butin déjà remis (objet ou pièces).
    @Default(false) bool looted,

    /// Objet obtenu, ou `null` (pièces à la place).
    String? lootItemId,
  }) = _DungeonRun;

  factory DungeonRun.fromJson(Map<String, dynamic> json) =>
      _$DungeonRunFromJson(json);
}

/// Quêtes au-delà du jour : semaine, donjon, événements déjà récompensés.
@freezed
abstract class QuestBoard with _$QuestBoard {
  const factory QuestBoard({
    WeeklyQuest? weekly,
    DungeonRun? dungeon,

    /// Événements récompensés, par édition (`<id>-<année>`).
    @Default([]) List<String> claimedEvents,
  }) = _QuestBoard;

  factory QuestBoard.fromJson(Map<String, dynamic> json) =>
      _$QuestBoardFromJson(json);
}
