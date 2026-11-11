import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/quests/domain/quest_rules.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

// Jeudi 5 novembre 2026 : jour d'entraînement du profil de test
// (repos le mercredi et le dimanche).
const _thursday = CivilDate(2026, 11, 5);
const _wednesday = CivilDate(2026, 11, 4);

DateTime _at(CivilDate day, [int hour = 12]) =>
    DateTime(day.year, day.month, day.day, hour);

DailyQuest _generate({
  CivilDate day = _thursday,
  PlayerProfile? profile,
  int level = 1,
  bool sick = false,
}) => generateDailyQuest(
  day: day,
  profile: profile ?? sampleProfile,
  playerLevel: level,
  sick: sick,
  catalog: testCatalog,
);

CompletedSession _session(
  CivilDate day,
  List<CompletedSet> sets, {
  bool completed = true,
}) => CompletedSession(
  id: 's-$day-${sets.length}',
  programName: 'test',
  format: ProgramFormat.strength,
  startedAt: _at(day).toUtc(),
  endedAt: _at(day, 13).toUtc(),
  sets: sets,
  activeSeconds: 600,
  xpEarned: 10,
  completed: completed,
);

const _squats = QuestObjective(
  exerciseId: 'squat',
  metric: QuestMetric.reps,
  target: 30,
);
const _walk = QuestObjective(
  exerciseId: 'walking',
  metric: QuestMetric.seconds,
  target: 600,
);

void main() {
  group('generateDailyQuest', () {
    test('donne 3 ou 4 objectifs du catalogue validé et accessible', () {
      final byId = {for (final e in testCatalog) e.id: e};
      for (var d = 0; d < 30; d++) {
        final day = _thursday.addDays(d);
        if (sampleProfile.restDays.contains(day.weekday)) continue;
        final quest = _generate(day: day);
        expect(
          quest.objectives.length,
          inInclusiveRange(
            gameConfig.quests.dailyObjectivesMin,
            gameConfig.quests.dailyObjectivesMax,
          ),
          reason: '$day',
        );
        for (final objective in quest.objectives) {
          final exercise = byId[objective.exerciseId]!;
          expect(exercise.reviewStatus, ReviewStatus.validated);
          expect(exercise.isAvailableWith(sampleProfile.equipment), isTrue);
          expect(objective.target, greaterThan(0));
        }
        // Jamais deux fois le même exercice.
        expect(
          quest.objectives.map((o) => o.exerciseId).toSet().length,
          quest.objectives.length,
        );
      }
    });

    test('est stable : même jour, même quête', () {
      expect(_generate(), _generate());
    });

    test('jour de repos et maladie : aucune quête, repos respecté', () {
      final rest = _generate(day: _wednesday);
      expect(rest.restDay, isTrue);
      expect(rest.objectives, isEmpty);
      expect(_generate(sick: true).objectives, isEmpty);
    });

    test('les objectifs grandissent avec le niveau, avec un plafond', () {
      int total(DailyQuest quest) =>
          quest.objectives.fold(0, (sum, o) => sum + o.target);
      final low = total(_generate());
      final high = total(_generate(level: 30));
      final capped = total(_generate(level: 500));
      expect(high, greaterThan(low));
      expect(capped, lessThanOrEqualTo(total(_generate(level: 1000))));
      expect(questTargetMultiplier(500), gameConfig.quests.maxTargetMultiplier);
    });
  });

  group('questProgress', () {
    test('compte les répétitions et secondes du jour, sans les sauts', () {
      final sessions = [
        _session(_thursday, const [
          CompletedSet(exerciseId: 'squat', activeSeconds: 40, reps: 12),
          CompletedSet(exerciseId: 'squat', activeSeconds: 40, reps: 10),
          CompletedSet(
            exerciseId: 'squat',
            activeSeconds: 40,
            reps: 15,
            skipped: true,
          ),
          CompletedSet(exerciseId: 'walking', activeSeconds: 900),
        ]),
        // Autre jour : ignoré.
        _session(_wednesday, const [
          CompletedSet(exerciseId: 'squat', activeSeconds: 40, reps: 50),
        ]),
      ];
      expect(questProgress(const [_squats, _walk], _thursday, sessions), [
        22,
        600,
      ]);
    });
  });

  group('evaluateQuests', () {
    const quest = DailyQuest(day: _thursday, objectives: [_squats]);
    final fresh = ProgressionState.initial(_wednesday).copyWith(level: 2);

    test('quête terminée : récompense versée une fois, jour validé', () {
      final sessions = [
        _session(_thursday, const [
          CompletedSet(exerciseId: 'squat', activeSeconds: 60, reps: 30),
        ], completed: false),
      ];
      final outcome = evaluateQuests(
        quest: quest,
        state: fresh,
        sessions: sessions,
        now: _at(_thursday, 14),
        restDays: sampleProfile.restDays,
      );
      final reward = dailyQuestReward(2);
      expect(outcome.reward?.xp, reward.xp);
      expect(outcome.quest.claimed, isTrue);
      expect(outcome.dayValidated, isTrue);
      expect(outcome.state.streakDays, 1);
      expect(
        outcome.state.willpowerEarned,
        reward.willpower + gameConfig.streaks.willpowerPerStreakDay,
      );
      expect(outcome.state.coins, reward.coins.bronzeTotal);

      final again = evaluateQuests(
        quest: outcome.quest,
        state: outcome.state,
        sessions: sessions,
        now: _at(_thursday, 15),
        restDays: sampleProfile.restDays,
      );
      expect(again.isEmpty, isTrue);
      expect(again.state, outcome.state);
    });

    test('quête inachevée : aucune récompense', () {
      final outcome = evaluateQuests(
        quest: quest,
        state: fresh,
        sessions: [
          _session(_thursday, const [
            CompletedSet(exerciseId: 'squat', activeSeconds: 60, reps: 10),
          ]),
        ],
        now: _at(_thursday, 14),
        restDays: sampleProfile.restDays,
      );
      expect(outcome.isEmpty, isTrue);
      expect(outcome.quest.claimed, isFalse);
    });

    test('quête de pénalité : la moitié des objectifs lève le malus', () {
      final penalized = fresh.copyWith(
        penaltyUntil: _at(_thursday, 23).toUtc(),
      );
      final outcome = evaluateQuests(
        quest: quest,
        state: penalized,
        sessions: [
          _session(_thursday, const [
            CompletedSet(exerciseId: 'squat', activeSeconds: 60, reps: 15),
          ]),
        ],
        now: _at(_thursday, 14),
        restDays: sampleProfile.restDays,
      );
      expect(outcome.penaltyCleared, isTrue);
      expect(outcome.state.penaltyUntil, isNull);
      expect(outcome.quest.penaltyCleared, isTrue);
      expect(outcome.reward, isNull);
    });

    test('une quête d’un autre jour est ignorée', () {
      final outcome = evaluateQuests(
        quest: quest,
        state: fresh,
        sessions: const [],
        now: _at(_thursday.next, 9),
        restDays: sampleProfile.restDays,
      );
      expect(outcome.isEmpty, isTrue);
    });
  });

  group('questProgram', () {
    test('découpe les restes en séries raisonnables', () {
      final program = questProgram(
        id: 'quest_daily',
        name: 'Quête',
        objectives: const [
          QuestObjective(
            exerciseId: 'push_up',
            metric: QuestMetric.reps,
            target: 40,
          ),
          _walk,
          _squats,
        ],
        progress: const [10, 0, 30],
      )!;
      expect(program.items.length, 2);
      final pushUps = program.items.first;
      expect(pushUps.sets! * pushUps.reps!, greaterThanOrEqualTo(30));
      expect(pushUps.reps, lessThanOrEqualTo(gameConfig.quests.maxRepsPerSet));
      expect(program.items.last.exerciseId, 'walking');
      expect(
        program.items.last.sets! * program.items.last.durationSeconds!,
        greaterThanOrEqualTo(600),
      );
    });

    test('rien à faire : pas de séance', () {
      expect(
        questProgram(
          id: 'quest_daily',
          name: 'Quête',
          objectives: const [_squats],
          progress: const [30],
        ),
        isNull,
      );
    });
  });
}
