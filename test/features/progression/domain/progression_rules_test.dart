import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/level_curve.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

// Lundi 2 novembre 2026, midi (heure locale du test).
final _monday = DateTime(2026, 11, 2, 12);
DateTime _day(int offset, [int hour = 12]) =>
    DateTime(_monday.year, _monday.month, _monday.day + offset, hour);
CivilDate _civil(int offset) => CivilDate.ofLocal(_day(offset));

const _noRest = <int>{};
const _sundayRest = {DateTime.sunday};

ProgressionState _fresh([int offset = 0]) =>
    ProgressionState.initial(_civil(offset));

SessionProgress _session(
  ProgressionState state,
  int offset, {
  int xp = 10,
  bool completed = true,
  Set<int> restDays = _noRest,
}) => applySession(
  state,
  baseXp: xp,
  baseXpByStat: {StatId.strength: xp},
  completed: completed,
  now: _day(offset),
  restDays: restDays,
);

void main() {
  group('addXp', () {
    test('passe les niveaux avec cristaux et points de stat', () {
      final gain = addXp(_fresh(), 100 + 100 + 50);
      expect(gain.state.level, 2);
      expect(gain.state.xpInLevel, 50);
      expect(gain.levelsGained, 2);
      expect(gain.crystalsGained, (5 + 1) + (5 + 2));
      expect(gain.statPointsGained, 6);
      expect(gain.state.freeStatPoints, 6);
      expect(gain.state.totalXp, 250);
    });

    test('bloque l’XP au niveau 9 tant que le boss du rang E est debout', () {
      var total = 0;
      for (var level = 0; level < 9; level++) {
        total += xpToNextLevel(level);
      }
      final need9 = xpToNextLevel(9);
      final gain = addXp(_fresh(), total + need9 + 500);
      expect(gain.state.level, 9);
      expect(gain.state.xpInLevel, need9);
      expect(gain.xpDiscarded, 500);
      expect(gain.state.isRankLocked, isTrue);

      // Le boss vaincu, la barre pleine fait passer au niveau 10.
      final unlocked = gain.state.copyWith(defeatedBosses: {RankId.e});
      expect(addXp(unlocked, 0).state.level, 10);
    });

    test('ne dépasse jamais le niveau maximum', () {
      final max = gameConfig.progression.maxLevel;
      final state = _fresh().copyWith(
        level: max,
        defeatedBosses: RankId.values.toSet(),
      );
      final gain = addXp(state, 10000);
      expect(gain.state.level, max);
      expect(gain.state.xpInLevel, 0);
      expect(gain.xpDiscarded, 10000);
    });
  });

  test('bonus de série : +5 % par jour, plafonné à +50 %', () {
    expect(streakMultiplier(0), 1);
    expect(streakMultiplier(3), closeTo(1.15, 1e-9));
    expect(streakMultiplier(10), closeTo(1.5, 1e-9));
    expect(streakMultiplier(40), closeTo(1.5, 1e-9));
  });

  group('applySession', () {
    test('une séance complète valide le jour et prolonge la série', () {
      final p = _session(_fresh(), 0);
      expect(p.dayValidated, isTrue);
      expect(p.state.streakDays, 1);
      expect(p.state.bestStreak, 1);
      expect(p.state.lastValidatedDay, _civil(0));
      expect(p.state.willpowerEarned, 1);
      expect(p.state.stat(StatId.willpower), 1);
    });

    test('une deuxième séance le même jour ne compte pas deux fois', () {
      final first = _session(_fresh(), 0).state;
      final second = _session(first, 0);
      expect(second.dayValidated, isFalse);
      expect(second.state.streakDays, 1);
    });

    test('une séance interrompue donne de l’XP sans valider le jour', () {
      final p = _session(_fresh(), 0, completed: false);
      expect(p.xpGained, 10);
      expect(p.dayValidated, isFalse);
      expect(p.state.streakDays, 0);
    });

    test('un jour de repos reste neutre, même avec une séance', () {
      // _day(6) est un dimanche.
      final p = _session(_fresh(), 6, restDays: _sundayRest);
      expect(p.dayValidated, isFalse);
      expect(p.xpGained, 10);
    });

    test('la série augmente l’XP des séances suivantes', () {
      var state = _fresh();
      for (var d = 0; d < 3; d++) {
        state = _session(state, d).state;
      }
      final p = _session(state, 3, xp: 100);
      expect(p.multiplier, closeTo(1.15, 1e-9));
      expect(p.xpGained, 115);
      expect(p.xpByStat[StatId.strength], 115);
    });

    test('l’XP par stat fait monter les stats automatiquement', () {
      final perPoint = gameConfig.progression.statXpPerPoint;
      final p = _session(_fresh(), 0, xp: perPoint * 2 + 1);
      expect(p.state.stat(StatId.strength), 2);
    });

    test('offre le coffre de cristaux au 7e jour de série', () {
      var state = _fresh();
      SessionProgress? last;
      for (var d = 0; d < 7; d++) {
        last = _session(state, d);
        state = last.state;
      }
      expect(state.streakDays, 7);
      expect(last!.chestCrystals, gameConfig.streaks.chestCrystals.first);
    });

    test('pendant la pénalité : XP réduite, puis malus levé', () {
      final state = _fresh().copyWith(
        penaltyUntil: _day(0, 20).toUtc(),
      );
      final p = _session(state, 0, xp: 100);
      expect(p.multiplier, closeTo(0.8, 1e-9));
      expect(p.xpGained, 80);
      expect(p.penaltyCleared, isTrue);
      expect(p.state.penaltyUntil, isNull);
    });
  });

  group('runDailyRollover', () {
    test('rien ne se passe le jour même', () {
      final result = runDailyRollover(
        _fresh(),
        now: _day(0, 23),
        restDays: _noRest,
      );
      expect(result.report.isEmpty, isTrue);
      expect(result.state, _fresh());
    });

    test('un jour manqué sans bouclier remet la série à zéro', () {
      var state = _session(_fresh(), 0).state;
      state = _session(state, 1).state;
      // Mercredi (jour 2) manqué, ouverture jeudi.
      final result = runDailyRollover(state, now: _day(3), restDays: _noRest);
      expect(result.report.missedDays, 1);
      expect(result.report.streakLost, 2);
      expect(result.state.streakDays, 0);
      expect(result.state.bestStreak, 2);
      expect(result.report.penaltyStarted, isTrue);
      expect(result.state.isPenaltyActive(_day(3)), isTrue);
      expect(result.state.isPenaltyActive(_day(4, 13)), isFalse);
      // Jamais de perte de niveau ni de cristaux.
      expect(result.state.level, state.level);
      expect(result.state.crystals, state.crystals);
    });

    test('un bouclier protège la série', () {
      var state = _session(_fresh(), 0).state.copyWith(shields: 1);
      final result = runDailyRollover(state, now: _day(2), restDays: _noRest);
      expect(result.report.shieldsUsed, 1);
      expect(result.state.shields, 0);
      expect(result.state.streakDays, 1);
      state = _session(result.state, 2).state;
      expect(state.streakDays, 2);
    });

    test('les jours de repos et de maladie sont neutres', () {
      // Séance samedi (jour 5), repos dimanche (6), ouverture lundi (7).
      var state = _session(_fresh(5), 5, restDays: _sundayRest).state;
      var result = runDailyRollover(
        state,
        now: _day(7),
        restDays: _sundayRest,
      );
      expect(result.report.missedDays, 0);
      expect(result.state.streakDays, 1);

      state = setSickMode(result.state, now: _day(7), days: 3);
      state = state.copyWith(lastRolloverDay: _civil(7));
      result = runDailyRollover(state, now: _day(10), restDays: _noRest);
      expect(result.report.missedDays, 0);
      expect(result.state.streakDays, 1);
    });

    test('plusieurs jours manqués : un seul malus', () {
      final state = _session(_fresh(), 0).state;
      final result = runDailyRollover(state, now: _day(5), restDays: _noRest);
      expect(result.report.missedDays, 4);
      expect(result.report.penaltyStarted, isTrue);
      expect(
        result.state.penaltyUntil,
        _day(5).toUtc().add(
          Duration(hours: gameConfig.penalty.durationHours),
        ),
      );
      expect(result.state.lastRolloverDay, _civil(4));
    });

    test('gagne un bouclier tous les 14 jours écoulés, 2 au maximum', () {
      final every = gameConfig.streaks.shieldEveryDays;
      // Tous les jours sont des jours de repos : seuls les boucliers comptent.
      final allRest = {for (var d = 1; d <= 7; d++) d};
      final result = runDailyRollover(
        _fresh(),
        now: _day(every * 3 + 1),
        restDays: allRest,
      );
      expect(result.report.shieldsEarned, gameConfig.streaks.maxShields);
      expect(result.state.shields, gameConfig.streaks.maxShields);
      expect(result.report.missedDays, 0);
    });

    test('est idempotente pour un même jour', () {
      final state = _session(_fresh(), 0).state;
      final first = runDailyRollover(state, now: _day(3), restDays: _noRest);
      final again = runDailyRollover(
        first.state,
        now: _day(3, 18),
        restDays: _noRest,
      );
      expect(again.report.isEmpty, isTrue);
      expect(again.state, first.state);
    });
  });

  test('placer un point de stat consomme un point libre', () {
    final state = _fresh().copyWith(freeStatPoints: 1);
    final next = allocateStatPoint(state, StatId.agility)!;
    expect(next.freeStatPoints, 0);
    expect(next.stat(StatId.agility), 1);
    expect(allocateStatPoint(next, StatId.agility), isNull);
  });

  test('le mode maladie dure 14 jours au plus et lève le malus', () {
    final state = _fresh().copyWith(penaltyUntil: _day(1).toUtc());
    final sick = setSickMode(state, now: _day(0), days: 30);
    expect(
      sick.sickUntil,
      _civil(gameConfig.rest.sickModeMaxDays - 1),
    );
    expect(sick.penaltyUntil, isNull);
    final ended = endSickMode(sick, now: _day(2));
    expect(ended.sickUntil, isNull);
    expect(ended.lastRolloverDay, _civil(2));
    // Le jour de reprise reste neutre : aucun jour manqué le lendemain.
    final next = runDailyRollover(ended, now: _day(3), restDays: _noRest);
    expect(next.report.missedDays, 0);
  });

  test('rejoue l’XP des séances déjà enregistrées', () {
    final state = replaySessionXp(_fresh(), [
      (xp: 60, xpByStat: {StatId.endurance: 60}),
      (xp: 60, xpByStat: {StatId.endurance: 60}),
    ]);
    expect(state.level, 1);
    expect(state.xpInLevel, 20);
    expect(state.statXp[StatId.endurance], 120);
    expect(state.streakDays, 0);
  });

  test('la progression se sérialise sans perte', () {
    final state = _session(_fresh(), 0).state.copyWith(
      allocatedStats: {StatId.agility: 2},
      defeatedBosses: {RankId.e},
      sickUntil: _civil(3),
      penaltyUntil: DateTime.utc(2026, 11, 3),
    );
    expect(ProgressionState.fromJson(state.toJson()), state);
  });
}
