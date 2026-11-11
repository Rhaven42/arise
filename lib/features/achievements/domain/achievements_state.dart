import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievements_state.freezed.dart';
part 'achievements_state.g.dart';

/// Hauts faits obtenus par le joueur.
@freezed
abstract class AchievementsState with _$AchievementsState {
  const factory AchievementsState({
    /// Date d'obtention (UTC) par identifiant de haut fait.
    @Default({}) Map<String, DateTime> unlocked,

    /// Quêtes du jour accomplies depuis la phase 9 (l'historique des quêtes
    /// n'est pas conservé ailleurs).
    @Default(0) int dailyQuestsDone,
  }) = _AchievementsState;

  factory AchievementsState.fromJson(Map<String, dynamic> json) =>
      _$AchievementsStateFromJson(json);
}
