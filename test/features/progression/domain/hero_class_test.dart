import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/hero_class.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 11, 11, 12);

/// Joueur au rang C (niveau 20, boss E et D vaincus).
ProgressionState _rankC() =>
    ProgressionState.initial(const CivilDate(2026, 11, 1))
        .copyWith(level: 20, defeatedBosses: {RankId.e, RankId.d});

SessionProgress _session(ProgressionState state) => applySession(
  state,
  baseXp: 100,
  baseXpByStat: const {StatId.strength: 60, StatId.endurance: 40},
  completed: false,
  now: _now,
  restDays: const {},
);

void main() {
  group('choix de la classe', () {
    test('refusé avant le rang C', () {
      final state = _rankC().copyWith(level: 19);
      expect(
        classChoiceIssue(state, HeroClass.berserker, now: _now),
        ClassChoiceIssue.rankTooLow,
      );
      expect(chooseClass(state, HeroClass.berserker, now: _now), isNull);
    });

    test('au rang C, puis un changement par mois', () {
      final chosen = chooseClass(_rankC(), HeroClass.ranger, now: _now)!;
      expect(chosen.heroClass, HeroClass.ranger);
      expect(chosen.classChangedAt, _now);

      final soon = _now.add(const Duration(days: 29));
      expect(
        classChoiceIssue(chosen, HeroClass.tank, now: soon),
        ClassChoiceIssue.cooldown,
      );
      expect(
        classChoiceIssue(chosen, HeroClass.ranger, now: soon),
        ClassChoiceIssue.sameClass,
      );
      final later = _now.add(
        Duration(days: gameConfig.classes.changeCooldownDays),
      );
      expect(
        chooseClass(chosen, HeroClass.tank, now: later)?.heroClass,
        HeroClass.tank,
      );
    });
  });

  group('bonus d’XP de classe', () {
    test('sans classe : aucun bonus', () {
      final p = _session(_rankC());
      expect(p.classXp, 0);
      expect(p.xpGained, 100);
    });

    test('spécialiste : +15 % sur la part de sa stat seulement', () {
      final p = _session(_rankC().copyWith(heroClass: HeroClass.berserker));
      expect(p.classXp, 9); // 15 % de 60 (Force)
      expect(p.xpGained, 109);
      expect(p.xpByStat[StatId.strength], 69);
      expect(p.xpByStat[StatId.endurance], 40);
    });

    test('Nécromancien : +5 % partout', () {
      final p = _session(_rankC().copyWith(heroClass: HeroClass.necromancer));
      expect(p.classXp, 5); // 3 + 2
      expect(p.xpGained, 105);
    });

    test('le bonus se cumule par multiplication avec la série', () {
      final p = _session(
        _rankC().copyWith(heroClass: HeroClass.berserker, streakDays: 10),
      );
      // (100 + 9) × 1,5
      expect(p.xpGained, 164);
    });
  });
}
