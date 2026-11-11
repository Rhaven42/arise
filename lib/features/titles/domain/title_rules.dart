import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/achievements/domain/achievement_rules.dart';
import 'package:arise/features/achievements/domain/achievements_state.dart';
import 'package:arise/features/titles/domain/titles_state.dart';
import 'package:arise/features/trials/domain/trials_state.dart';

/// Titres obtenus : ceux des boss (dans l'ordre des victoires), puis ceux
/// des hauts faits.
List<String> earnedTitles({
  required TrialsState trials,
  required AchievementsState achievements,
  GameConfig config = gameConfig,
}) => {
  ...trials.titles,
  ...achievementTitles(achievements, config: config),
}.toList();

/// Auras débloquées par les titres obtenus.
List<AuraDefinition> earnedAuras(
  List<String> titles, {
  GameConfig config = gameConfig,
}) => [
  for (final aura in config.achievements.auras)
    if (titles.contains(aura.titleId)) aura,
];

/// Aura d'identifiant [id], ou `null`.
AuraDefinition? auraById(String? id, {GameConfig config = gameConfig}) {
  for (final aura in config.achievements.auras) {
    if (aura.id == id) return aura;
  }
  return null;
}

/// Équipe un titre obtenu (ou retire le titre avec `null`). Renvoie `null`
/// si le titre n'a pas été obtenu.
TitlesState? equipTitle(
  TitlesState state,
  String? titleId, {
  required List<String> earned,
}) {
  if (titleId != null && !earned.contains(titleId)) return null;
  return TitlesState(equippedTitle: titleId, equippedAura: state.equippedAura);
}

/// Équipe une aura débloquée (ou la retire avec `null`).
TitlesState? equipAura(
  TitlesState state,
  String? auraId, {
  required List<String> earned,
  GameConfig config = gameConfig,
}) {
  if (auraId != null &&
      !earnedAuras(earned, config: config).any((a) => a.id == auraId)) {
    return null;
  }
  return TitlesState(equippedTitle: state.equippedTitle, equippedAura: auraId);
}

/// Titre et aura réellement portés : un choix qui n'est plus obtenu (après
/// une restauration, par exemple) est ignoré.
TitlesState wornTitles(
  TitlesState state, {
  required List<String> earned,
  GameConfig config = gameConfig,
}) => TitlesState(
  equippedTitle: earned.contains(state.equippedTitle)
      ? state.equippedTitle
      : null,
  equippedAura:
      earnedAuras(earned, config: config).any((a) => a.id == state.equippedAura)
      ? state.equippedAura
      : null,
);
