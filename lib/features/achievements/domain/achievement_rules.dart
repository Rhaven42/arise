import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/achievements/domain/achievements_state.dart';

/// Résultat d'une évaluation : état mis à jour et hauts faits obtenus.
class AchievementsUpdate {
  const AchievementsUpdate({required this.state, required this.unlocked});

  final AchievementsState state;

  /// Hauts faits obtenus lors de cette évaluation, dans l'ordre du
  /// catalogue.
  final List<AchievementDefinition> unlocked;
}

/// Débloque les hauts faits dont la mesure atteint le seuil. Un haut fait
/// obtenu le reste toujours.
AchievementsUpdate evaluateAchievements(
  AchievementsState state,
  Map<AchievementMetric, int> metrics, {
  required DateTime now,
  GameConfig config = gameConfig,
}) {
  final unlocked = <AchievementDefinition>[];
  for (final definition in config.achievements.definitions) {
    if (state.unlocked.containsKey(definition.id)) continue;
    if ((metrics[definition.metric] ?? 0) >= definition.threshold) {
      unlocked.add(definition);
    }
  }
  if (unlocked.isEmpty) {
    return AchievementsUpdate(state: state, unlocked: const []);
  }
  final at = now.toUtc();
  return AchievementsUpdate(
    state: state.copyWith(
      unlocked: {...state.unlocked, for (final d in unlocked) d.id: at},
    ),
    unlocked: unlocked,
  );
}

/// Avancement d'un haut fait, entre 0 et son seuil.
int achievementProgress(
  AchievementDefinition definition,
  Map<AchievementMetric, int> metrics,
) {
  final value = metrics[definition.metric] ?? 0;
  return value > definition.threshold ? definition.threshold : value;
}

/// Titres offerts par les hauts faits obtenus, dans l'ordre du catalogue.
List<String> achievementTitles(
  AchievementsState state, {
  GameConfig config = gameConfig,
}) => [
  for (final d in config.achievements.definitions)
    if (d.titleId != null && state.unlocked.containsKey(d.id)) d.titleId!,
];

/// Quête du jour accomplie : le compteur des hauts faits avance.
AchievementsState recordDailyQuest(AchievementsState state) =>
    state.copyWith(dailyQuestsDone: state.dailyQuestsDone + 1);
