import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/hero_class.dart';
import 'package:arise/features/quests/domain/quest_board.dart';
import 'package:arise/features/shadows/domain/shadows_state.dart';
import 'package:arise/features/trials/domain/trial_rules.dart';

/// Nombre d'Ombres actives possibles (plus pour le Nécromancien).
int maxActiveShadows(HeroClass? heroClass, {GameConfig config = gameConfig}) =>
    heroClass == HeroClass.necromancer
    ? config.shadows.maxActiveNecromancer
    : config.shadows.maxActive;

/// Bonus passif d'une Ombre active (doublé pour le Nécromancien).
double shadowBonus(HeroClass? heroClass, {GameConfig config = gameConfig}) =>
    config.shadows.passiveStatBonus *
    (heroClass == HeroClass.necromancer
        ? config.shadows.necromancerBonusMultiplier
        : 1);

bool _known(ShadowsState state, String key) =>
    state.shadows.any((s) => s.id == key) ||
    state.pending.any((p) => p.key == key);

/// Ombres offertes par les boss vaincus à partir du rang B (les victoires
/// d'avant la phase 9 comprises).
ShadowsState offerBossShadows(
  ShadowsState state,
  Set<RankId> defeatedBosses, {
  GameConfig config = gameConfig,
}) {
  final offers = <ShadowOrigin>[];
  for (final rank in bossRanks) {
    if (!defeatedBosses.contains(rank)) continue;
    if (rank.index < config.shadows.unlockRank.index) continue;
    final trial = trialFor(rank, config: config);
    final key = 'boss_${rank.name}';
    if (trial == null || _known(state, key)) continue;
    offers.add(
      ShadowOrigin(
        source: ShadowSource.boss,
        key: key,
        name: trial.boss.name,
        stat: trial.requiredStat,
      ),
    );
  }
  if (offers.isEmpty) return state;
  return state.copyWith(pending: [...state.pending, ...offers]);
}

/// Ombre offerte par un donjon terminé, si le joueur est au moins rang B.
ShadowsState offerDungeonShadow(
  ShadowsState state,
  DungeonRun run, {
  required RankId playerRank,
  GameConfig config = gameConfig,
}) {
  if (playerRank.index < config.shadows.unlockRank.index) return state;
  final key = 'dungeon_${run.weekStart}';
  if (_known(state, key)) return state;
  final stat = StatId.values.byName(
    config.shadows.dungeonThemeStats[run.theme.name] ?? StatId.strength.name,
  );
  return state.copyWith(
    pending: [
      ...state.pending,
      ShadowOrigin(
        source: ShadowSource.dungeon,
        key: key,
        name: run.theme.name,
        stat: stat,
      ),
    ],
  );
}

/// Extrait l'Ombre en attente [key] ; elle devient active s'il reste de la
/// place. Renvoie `null` si rien n'attend sous cette clé.
ShadowsState? extractShadow(
  ShadowsState state,
  String key, {
  required DateTime now,
  HeroClass? heroClass,
  GameConfig config = gameConfig,
}) {
  final origin = state.pending.where((p) => p.key == key).firstOrNull;
  if (origin == null) return null;
  final shadow = Shadow(
    origin: origin,
    extractedAt: now.toUtc(),
    index: state.shadows.length,
  );
  final room =
      state.active.length < maxActiveShadows(heroClass, config: config);
  return state.copyWith(
    shadows: [...state.shadows, shadow],
    pending: [
      for (final p in state.pending)
        if (p.key != key) p,
    ],
    active: room ? [...state.active, shadow.id] : state.active,
  );
}

/// Pourquoi une Ombre ne peut pas être activée.
enum ShadowIssue { unknown, full }

/// Active ou met au repos l'Ombre [id].
({ShadowsState state, ShadowIssue? issue}) toggleShadow(
  ShadowsState state,
  String id, {
  HeroClass? heroClass,
  GameConfig config = gameConfig,
}) {
  if (!state.shadows.any((s) => s.id == id)) {
    return (state: state, issue: ShadowIssue.unknown);
  }
  if (state.active.contains(id)) {
    return (
      state: state.copyWith(
        active: [
          for (final a in state.active)
            if (a != id) a,
        ],
      ),
      issue: null,
    );
  }
  if (activeShadows(state, heroClass: heroClass, config: config).length >=
      maxActiveShadows(heroClass, config: config)) {
    return (state: state, issue: ShadowIssue.full);
  }
  return (state: state.copyWith(active: [...state.active, id]), issue: null);
}

/// Ombres actives réellement en jeu : après un changement de classe, celles
/// au-delà de la limite restent au repos.
List<Shadow> activeShadows(
  ShadowsState state, {
  HeroClass? heroClass,
  GameConfig config = gameConfig,
}) {
  final byId = {for (final s in state.shadows) s.id: s};
  return [for (final id in state.active) ?byId[id]]
      .take(maxActiveShadows(heroClass, config: config))
      .toList();
}

/// Multiplicateur d'XP par stat dû aux Ombres actives : +2 % par Ombre sur
/// sa stat (+4 % pour le Nécromancien), cumulés par multiplication.
Map<StatId, double> shadowStatMultipliers(
  ShadowsState state, {
  HeroClass? heroClass,
  GameConfig config = gameConfig,
}) {
  final bonus = shadowBonus(heroClass, config: config);
  final result = <StatId, double>{};
  for (final shadow in activeShadows(
    state,
    heroClass: heroClass,
    config: config,
  )) {
    result.update(
      shadow.origin.stat,
      (m) => m * (1 + bonus),
      ifAbsent: () => 1 + bonus,
    );
  }
  return result;
}
