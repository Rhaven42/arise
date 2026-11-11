import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/progression_state.dart';

/// Classes d'Arisia (SPEC §6), choisies à partir du rang C.
enum HeroClass { berserker, ranger, assassin, tank, necromancer }

/// Stat favorisée par la classe (`null` pour le Nécromancien, qui reçoit un
/// petit bonus partout).
StatId? classStat(HeroClass heroClass) => switch (heroClass) {
  HeroClass.berserker => StatId.strength,
  HeroClass.ranger => StatId.endurance,
  HeroClass.assassin => StatId.agility,
  HeroClass.tank => StatId.vitality,
  HeroClass.necromancer => null,
};

/// XP de classe ajoutée à l'XP de base d'une séance, avant les bonus de
/// série et le malus de pénalité : +15 % sur la part de l'XP qui va à la
/// stat de la classe, ou +5 % sur toute l'XP pour le Nécromancien.
Map<StatId, int> classBonusXpByStat(
  HeroClass? heroClass,
  Map<StatId, int> baseXpByStat, {
  ClassesConfig? config,
}) {
  if (heroClass == null) return const {};
  final c = config ?? gameConfig.classes;
  final stat = classStat(heroClass);
  return {
    for (final entry in baseXpByStat.entries)
      if (stat == null || entry.key == stat)
        entry.key:
            (entry.value *
                    (stat == null ? c.necromancerXpBonus : c.specialistXpBonus))
                .round(),
  };
}

/// Pourquoi une classe ne peut pas être choisie maintenant.
enum ClassChoiceIssue { rankTooLow, cooldown, sameClass }

/// Date à partir de laquelle la classe peut de nouveau changer.
DateTime? nextClassChangeAt(ProgressionState state, {GameConfig? config}) {
  final changed = state.classChangedAt;
  if (changed == null) return null;
  return changed.add(
    Duration(days: (config ?? gameConfig).classes.changeCooldownDays),
  );
}

/// Vérifie le choix d'une classe : rang C ou plus, et une fois par mois.
ClassChoiceIssue? classChoiceIssue(
  ProgressionState state,
  HeroClass heroClass, {
  required DateTime now,
  GameConfig config = gameConfig,
}) {
  if (state.rank.index < config.classes.unlockRank.index) {
    return ClassChoiceIssue.rankTooLow;
  }
  if (state.heroClass == heroClass) return ClassChoiceIssue.sameClass;
  final next = nextClassChangeAt(state, config: config);
  if (next != null && now.isBefore(next)) return ClassChoiceIssue.cooldown;
  return null;
}

/// Choisit ou change de classe. Renvoie `null` si le choix est refusé.
ProgressionState? chooseClass(
  ProgressionState state,
  HeroClass heroClass, {
  required DateTime now,
  GameConfig config = gameConfig,
}) {
  if (classChoiceIssue(state, heroClass, now: now, config: config) != null) {
    return null;
  }
  return state.copyWith(heroClass: heroClass, classChangedAt: now.toUtc());
}
