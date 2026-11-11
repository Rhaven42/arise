import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/achievements/domain/achievement_metrics.dart';
import 'package:arise/features/achievements/domain/achievement_rules.dart';
import 'package:arise/features/achievements/domain/achievements_state.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

final Map<String, Exercise> _exercises = {for (final e in testCatalog) e.id: e};

CompletedSession _session(
  DateTime start, {
  ProgramFormat format = ProgramFormat.strength,
  List<CompletedSet>? sets,
  int activeSeconds = 1200,
  bool completed = true,
  String? programId,
  bool pain = false,
}) => CompletedSession(
  id: 's-${start.toIso8601String()}-$programId',
  programName: 'test',
  programId: programId,
  format: format,
  startedAt: start.toUtc(),
  endedAt: start.add(Duration(seconds: activeSeconds)).toUtc(),
  sets:
      sets ??
      const [
        CompletedSet(exerciseId: 'squat', activeSeconds: 60, reps: 12, rpe: 8),
        CompletedSet(
          exerciseId: 'push_up',
          activeSeconds: 60,
          reps: 10,
          rpe: 7,
        ),
      ],
  activeSeconds: activeSeconds,
  xpEarned: 10,
  completed: completed,
  stoppedForPain: pain,
);

Map<AchievementMetric, int> _metrics(
  List<CompletedSession> sessions, {
  ProgressionState? progression,
  DateTime? now,
  Set<int> restDays = const {},
  TrialsState trials = const TrialsState(),
}) => computeAchievementMetrics(
  AchievementInputs(
    sessions: sessions,
    exercisesById: _exercises,
    progression:
        progression ?? ProgressionState.initial(const CivilDate(2026, 11, 1)),
    now: now ?? DateTime(2026, 11, 30, 12),
    restDays: restDays,
    trials: trials,
  ),
);

void main() {
  group('mesures', () {
    test('séances, répétitions, séries effectives et exercices', () {
      final metrics = _metrics([
        _session(DateTime(2026, 11, 2, 12)),
        _session(DateTime(2026, 11, 3, 12), completed: false),
      ]);
      expect(metrics[AchievementMetric.sessionsCompleted], 1);
      expect(metrics[AchievementMetric.totalReps], 44);
      expect(metrics[AchievementMetric.effectiveSets], 4);
      expect(metrics[AchievementMetric.distinctExercises], 2);
      expect(metrics[AchievementMetric.activeMinutes], 40);
    });

    test('aube, soir et jour de l’an en heure locale', () {
      final metrics = _metrics([
        _session(DateTime(2026, 11, 2, 6)),
        _session(DateTime(2026, 11, 2, 22)),
        _session(DateTime(2027, 1, 1, 10)),
      ], now: DateTime(2027, 1, 2));
      expect(metrics[AchievementMetric.dawnSessions], 1);
      expect(metrics[AchievementMetric.eveningSessions], 1);
      expect(metrics[AchievementMetric.newYearSessions], 1);
    });

    test('semaines de jambes consécutives', () {
      // Trois semaines de suite (lundi 2, 9, 16 novembre), puis une pause.
      final legs = [
        for (var i = 0; i < 5; i++)
          const CompletedSet(
            exerciseId: 'squat',
            activeSeconds: 60,
            reps: 12,
            rpe: 8,
          ),
      ];
      final metrics = _metrics([
        for (final day in [2, 9, 16, 30])
          _session(DateTime(2026, 11, day, 12), sets: legs),
      ]);
      expect(metrics[AchievementMetric.legWeeksInARow], 3);
    });

    test('jours de repos respectés et arrêts pour douleur', () {
      // Repos le dimanche (7) : 8, 15 et 22 novembre sans séance.
      final metrics = _metrics(
        [
          _session(DateTime(2026, 11, 2, 12)),
          _session(DateTime(2026, 11, 3, 12), pain: true, completed: false),
        ],
        restDays: {7},
        now: DateTime(2026, 11, 23, 12),
      );
      expect(metrics[AchievementMetric.restDaysRespected], 3);
      expect(metrics[AchievementMetric.painStops], 1);
    });

    test('mobilité : souplesse sans volume de renforcement', () {
      final metrics = _metrics([
        _session(
          DateTime(2026, 11, 2, 12),
          format: ProgramFormat.mobility,
          sets: const [CompletedSet(exerciseId: 'cat_cow', activeSeconds: 600)],
        ),
      ]);
      expect(metrics[AchievementMetric.flexibilityMinutes], 10);
      expect(metrics[AchievementMetric.musclesWorked], 0);
    });

    test('boss vaincus du premier coup', () {
      final progression = ProgressionState.initial(const CivilDate(2026, 11, 1))
          .copyWith(defeatedBosses: {RankId.e, RankId.d});
      final metrics = _metrics(
        const [],
        progression: progression,
        trials: const TrialsState(attempts: {RankId.e: 1, RankId.d: 3}),
      );
      expect(metrics[AchievementMetric.bossesDefeated], 2);
      expect(metrics[AchievementMetric.firstTryBosses], 1);
    });
  });

  group('évaluation', () {
    test('la première séance débloque « L’Éveillé » une seule fois', () {
      final now = DateTime.utc(2026, 11, 2, 12);
      final metrics = _metrics([_session(DateTime(2026, 11, 2, 12))]);
      final first = evaluateAchievements(
        const AchievementsState(),
        metrics,
        now: now,
      );
      expect(first.unlocked.map((d) => d.id), contains('first_session'));
      expect(first.state.unlocked['first_session'], now);
      expect(achievementTitles(first.state), contains('title_awakened'));

      final again = evaluateAchievements(first.state, metrics, now: now);
      expect(again.unlocked, isEmpty);
      expect(again.state, first.state);
    });

    test('l’avancement est plafonné au seuil', () {
      final definition = gameConfig.achievements.definitions.firstWhere(
        (d) => d.id == 'sessions_10',
      );
      expect(
        achievementProgress(definition, {
          AchievementMetric.sessionsCompleted: 4,
        }),
        4,
      );
      expect(
        achievementProgress(definition, {
          AchievementMetric.sessionsCompleted: 40,
        }),
        10,
      );
    });

    test('compteur des quêtes du jour', () {
      expect(recordDailyQuest(const AchievementsState()).dailyQuestsDone, 1);
    });
  });
}
