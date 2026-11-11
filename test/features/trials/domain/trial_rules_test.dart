import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/level_curve.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/trials/domain/trial_rules.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

final _now = DateTime.utc(2026, 11, 11, 18);

/// Joueur bloqué au niveau 9 (dernier niveau du rang E), barre pleine.
ProgressionState _lockedAtE({int strength = 20}) =>
    ProgressionState.initial(const CivilDate(2026, 11, 1)).copyWith(
      level: 9,
      xpInLevel: xpToNextLevel(9),
      allocatedStats: {StatId.strength: strength},
    );

CompletedSession _strengthRun({
  int pushUps = 20,
  int squats = 30,
  int activeSeconds = 400,
  bool completed = true,
  bool pain = false,
}) => CompletedSession(
  id: 'trial',
  programName: 'trial_e',
  programId: 'trial_e',
  format: ProgramFormat.strength,
  startedAt: _now,
  endedAt: _now.add(const Duration(minutes: 9)),
  sets: [
    CompletedSet(exerciseId: 'push_up', activeSeconds: 200, reps: pushUps),
    CompletedSet(exerciseId: 'squat', activeSeconds: 200, reps: squats),
  ],
  activeSeconds: activeSeconds,
  xpEarned: 50,
  completed: completed,
  stoppedForPain: pain,
);

void main() {
  group('trialFor', () {
    test('un boss par rang jusqu’à S, natures en rotation', () {
      final kinds = [for (final rank in bossRanks) trialFor(rank)!.kind];
      expect(kinds, [
        TrialKind.strength,
        TrialKind.endurance,
        TrialKind.agility,
        TrialKind.strength,
        TrialKind.endurance,
        TrialKind.agility,
      ]);
      expect(trialFor(RankId.monarch), isNull);
      expect(
        {for (final rank in bossRanks) trialFor(rank)!.boss}.length,
        bossRanks.length,
      );
    });

    test('les séances n’utilisent que des exercices du catalogue', () {
      final ids = {for (final e in testCatalog) e.id};
      for (final rank in bossRanks) {
        final trial = trialFor(rank)!;
        for (final item in trial.program.items) {
          expect(ids, contains(item.exerciseId), reason: rank.name);
        }
        expect(trialRankOfProgram(trial.program.id), rank);
      }
    });

    test('les récompenses sont des objets exclusifs distincts', () {
      final rewards = [for (final r in bossRanks) trialFor(r)!.rewardItem];
      expect(rewards.map((i) => i.id).toSet().length, rewards.length);
      for (final item in rewards) {
        expect(item.isExclusive, isTrue);
        expect(itemById(item.modelId), isNotNull);
        expect(equipmentCatalog.map((e) => e.id), isNot(contains(item.id)));
      }
    });

    test('la configuration couvre chaque rang à boss', () {
      final t = gameConfig.trials;
      for (final list in [
        t.statRequirementByRank,
        t.strengthPushUpsByRank,
        t.strengthSquatsByRank,
        t.enduranceMinutesByRank,
        t.agilityRoundsByRank,
      ]) {
        expect(list.length, bossRanks.length);
      }
    });
  });

  group('trialAccess', () {
    test('avant le dernier niveau du rang : pas encore', () {
      final access = trialAccess(
        _lockedAtE().copyWith(level: 5, xpInLevel: 0),
        const TrialsState(),
        now: _now,
      );
      expect(access, isA<TrialNotYet>());
      expect((access as TrialNotYet).unlockLevel, 9);
    });

    test('stat trop basse : refusé avec la valeur actuelle', () {
      final access = trialAccess(
        _lockedAtE(strength: 3),
        const TrialsState(),
        now: _now,
      );
      expect(access, isA<TrialStatTooLow>());
      expect((access as TrialStatTooLow).current, 3);
    });

    test('accessible, puis 48 h d’attente après une défaite', () {
      expect(
        trialAccess(_lockedAtE(), const TrialsState(), now: _now),
        isA<TrialAvailable>(),
      );
      final trials = TrialsState(
        lastDefeatAt: {RankId.e: _now.subtract(const Duration(hours: 47))},
      );
      expect(
        trialAccess(_lockedAtE(), trials, now: _now),
        isA<TrialCoolingDown>(),
      );
      expect(
        trialAccess(
          _lockedAtE(),
          trials,
          now: _now.add(const Duration(hours: 2)),
        ),
        isA<TrialAvailable>(),
      );
    });

    test('rang Monarque : plus de boss', () {
      expect(
        trialAccess(
          _lockedAtE().copyWith(level: 95),
          const TrialsState(),
          now: _now,
        ),
        isA<TrialNone>(),
      );
    });
  });

  group('resolveTrial', () {
    final trial = trialFor(RankId.e)!;

    test('victoire : boss vaincu, niveau et rang passés, titre gagné', () {
      final outcome = resolveTrial(
        trial: trial,
        session: _strengthRun(),
        progression: _lockedAtE(),
        trials: const TrialsState(),
        now: _now,
      );
      expect(outcome.won, isTrue);
      expect(outcome.progression.defeatedBosses, contains(RankId.e));
      expect(outcome.progression.level, 10);
      expect(outcome.progression.rank, RankId.d);
      expect(outcome.levelsGained, 1);
      expect(outcome.trials.titles, [trial.titleId]);
      expect(outcome.trials.attempts[RankId.e], 1);
    });

    test('défaite : rien n’est perdu, nouvel essai dans 48 h', () {
      final before = _lockedAtE();
      for (final session in [
        _strengthRun(pushUps: 19),
        _strengthRun(activeSeconds: 601),
        _strengthRun(completed: false),
        _strengthRun(pain: true),
      ]) {
        final outcome = resolveTrial(
          trial: trial,
          session: session,
          progression: before,
          trials: const TrialsState(),
          now: _now,
        );
        expect(outcome.won, isFalse);
        expect(outcome.progression, before);
        expect(
          outcome.retryAt,
          _now.add(Duration(hours: gameConfig.trials.retryCooldownHours)),
        );
        expect(outcome.trials.lastDefeatAt[RankId.e], _now);
      }
    });
  });
}
