import 'dart:math';

import 'package:arise/core/config/game_config.dart';

/// XP nécessaire pour passer du niveau [level] au suivant (SPEC §5).
///
/// Le premier palier (0 → 1) est celui de l'Éveil ; ensuite
/// `round(100 × n^1,5)`.
int xpToNextLevel(int level, {ProgressionConfig? config}) {
  final c = config ?? gameConfig.progression;
  if (level <= c.startLevel) return c.tutorialXp;
  return (c.xpCurveBase * pow(level, c.xpCurveExponent)).round();
}

/// Rang correspondant à un niveau (le niveau 0 appartient au rang E).
RankId rankOf(int level, {GameConfig config = gameConfig}) {
  var rank = config.ranks.first.id;
  for (final threshold in config.ranks) {
    if (level >= threshold.minLevel) rank = threshold.id;
  }
  return rank;
}

/// Dernier niveau d'un rang (9 pour E, 19 pour D…), `null` pour le dernier.
int? lastLevelOfRank(RankId rank, {GameConfig config = gameConfig}) {
  final index = config.ranks.indexWhere((t) => t.id == rank);
  if (index < 0 || index == config.ranks.length - 1) return null;
  return config.ranks[index + 1].minLevel - 1;
}

/// Vrai si l'XP est bloquée à [level] : dernier niveau d'un rang dont le
/// boss n'a pas encore été vaincu.
bool rankLockedAt(
  int level,
  Set<RankId> defeatedBosses, {
  GameConfig config = gameConfig,
}) {
  final rank = rankOf(level, config: config);
  return lastLevelOfRank(rank, config: config) == level &&
      !defeatedBosses.contains(rank);
}
