import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/domain/session_xp.dart';
import 'package:flutter_test/flutter_test.dart';

const _burpee = Exercise(
  id: 'burpee',
  name: 'Burpees',
  type: ExerciseType.reps,
  volumeRule: VolumeRule.interval,
  stats: {StatId.endurance: 0.7, StatId.strength: 0.3},
  primaryMuscles: [MuscleId.quadriceps],
);
const _exercises = {'burpee': _burpee};

void main() {
  group('intensityMultiplier', () {
    test('va de 0,8 à 1,3 et reste borné', () {
      expect(intensityMultiplier(1), closeTo(0.8, 1e-9));
      expect(intensityMultiplier(10), closeTo(1.3, 1e-9));
      expect(intensityMultiplier(0), closeTo(0.8, 1e-9));
      expect(intensityMultiplier(12), closeTo(1.3, 1e-9));
      expect(intensityMultiplier(4) < intensityMultiplier(5), isTrue);
    });
  });

  group('normalizedVolume', () {
    final xp = gameConfig.xp;
    test('répétitions, distance ou durée', () {
      expect(
        normalizedVolume(
          CompletedSet(
            exerciseId: 'a',
            activeSeconds: 99,
            reps: xp.repsPerVolumeUnit * 2,
          ),
        ),
        2,
      );
      expect(
        normalizedVolume(
          CompletedSet(
            exerciseId: 'a',
            activeSeconds: 99,
            meters: xp.metersPerVolumeUnit * 3,
          ),
        ),
        3,
      );
      expect(
        normalizedVolume(
          CompletedSet(exerciseId: 'a', activeSeconds: xp.secondsPerVolumeUnit),
        ),
        1,
      );
    });
  });

  group('computeSessionXp', () {
    final unit = gameConfig.xp.repsPerVolumeUnit;
    final base = gameConfig.xp.baseXpPerVolumeUnit;
    CompletedSet set({int rpe = 10, int seconds = 60, bool skipped = false}) =>
        CompletedSet(
          exerciseId: 'burpee',
          activeSeconds: seconds,
          reps: unit,
          rpe: rpe,
          skipped: skipped,
        );

    test('XP = base × volume × intensité, répartie par stat', () {
      final xp = computeSessionXp(
        sets: [set(), set(rpe: 1)],
        exercisesById: _exercises,
        priorActiveSecondsToday: 0,
      );
      expect(xp.total, (base * 1.3 + base * 0.8).round());
      expect(xp.byStat[StatId.endurance], (xp.total * 0.7).round());
      expect(xp.byStat[StatId.strength], (xp.total * 0.3).round());
      expect(xp.activeSeconds, 120);
      expect(xp.exceededDailyCap, isFalse);
    });

    test('les efforts passés ne rapportent rien', () {
      final xp = computeSessionXp(
        sets: [set(skipped: true)],
        exercisesById: _exercises,
        priorActiveSecondsToday: 0,
      );
      expect(xp.total, 0);
      expect(xp.activeSeconds, 0);
    });

    test('au-delà de 120 min dans la journée, l’XP est divisée par deux', () {
      final cap = gameConfig.dailyEffort.activeMinutesCap * 60;
      final normal = computeSessionXp(
        sets: [set()],
        exercisesById: _exercises,
        priorActiveSecondsToday: 0,
      );
      final over = computeSessionXp(
        sets: [set()],
        exercisesById: _exercises,
        priorActiveSecondsToday: cap,
      );
      expect(over.exceededDailyCap, isTrue);
      expect(over.secondsOverCap, 60);
      expect(
        over.total,
        (normal.total * gameConfig.dailyEffort.overCapXpMultiplier).round(),
      );
    });

    test('un effort à cheval sur le plafond est réparti au prorata', () {
      final cap = gameConfig.dailyEffort.activeMinutesCap * 60;
      final xp = computeSessionXp(
        sets: [set()],
        exercisesById: _exercises,
        priorActiveSecondsToday: cap - 30,
      );
      expect(xp.secondsOverCap, 30);
      expect(xp.total, (base * 1.3 * 0.75).round());
    });
  });

  test('activeSecondsOnDay ne compte que les séances du jour local', () {
    CompletedSession session(DateTime start, int seconds) => CompletedSession(
      id: start.toIso8601String(),
      programName: 'P',
      format: ProgramFormat.strength,
      startedAt: start,
      endedAt: start,
      sets: const [],
      activeSeconds: seconds,
      xpEarned: 0,
      completed: true,
    );
    final day = DateTime(2026, 11, 5, 20);
    final sessions = [
      session(DateTime(2026, 11, 5, 7), 600),
      session(DateTime(2026, 11, 5, 23, 59), 300),
      session(DateTime(2026, 11, 4, 23, 59), 999),
      session(DateTime(2026, 11, 6), 999),
    ];
    expect(activeSecondsOnDay(sessions, day), 900);
  });
}
