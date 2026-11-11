import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_quest.freezed.dart';
part 'daily_quest.g.dart';

/// Mesure d'un objectif de quête.
enum QuestMetric {
  /// Répétitions (exercices à répétitions).
  reps,

  /// Secondes d'effort (gainage, cardio chronométré).
  seconds,
}

/// Objectif d'une quête : un exercice du catalogue et une quantité.
@freezed
abstract class QuestObjective with _$QuestObjective {
  const factory QuestObjective({
    required String exerciseId,
    required QuestMetric metric,
    required int target,
  }) = _QuestObjective;

  factory QuestObjective.fromJson(Map<String, dynamic> json) =>
      _$QuestObjectiveFromJson(json);
}

/// Quête quotidienne du Système (SPEC §9).
///
/// Elle est générée une fois par jour par `generateDailyQuest` ; sa
/// progression est recalculée à partir des séances du jour.
@freezed
abstract class DailyQuest with _$DailyQuest {
  const factory DailyQuest({
    @CivilDateConverter() required CivilDate day,
    @Default([]) List<QuestObjective> objectives,

    /// Vrai si le jour est un jour de repos (ou de maladie) : aucune quête,
    /// le Système invite à récupérer.
    @Default(false) bool restDay,

    /// Récompense déjà versée.
    @Default(false) bool claimed,

    /// Quête de pénalité accomplie ce jour-là.
    @Default(false) bool penaltyCleared,
  }) = _DailyQuest;

  const DailyQuest._();

  factory DailyQuest.fromJson(Map<String, dynamic> json) =>
      _$DailyQuestFromJson(json);

  bool get hasObjectives => objectives.isNotEmpty;
}
