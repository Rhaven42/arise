import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/muscle_analysis/domain/muscle_volume.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/quest_board_rules.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';

/// Tout ce dont les hauts faits ont besoin, lu par la couche présentation.
class AchievementInputs {
  const AchievementInputs({
    required this.sessions,
    required this.exercisesById,
    required this.progression,
    required this.now,
    this.trials = const TrialsState(),
    this.restDays = const {},
    this.dailyQuestsDone = 0,
    this.shadows = 0,
    this.itemsOwned = 0,
    this.customExercises = 0,
    this.programs = 0,
    this.eventsCompleted = 0,
  });

  final List<CompletedSession> sessions;
  final Map<String, Exercise> exercisesById;
  final ProgressionState progression;
  final DateTime now;
  final TrialsState trials;

  /// Jours de repos déclarés (1 = lundi … 7 = dimanche).
  final Set<int> restDays;
  final int dailyQuestsDone;
  final int shadows;
  final int itemsOwned;
  final int customExercises;
  final int programs;
  final int eventsCompleted;
}

/// Valeur de chaque mesure suivie par les hauts faits.
Map<AchievementMetric, int> computeAchievementMetrics(
  AchievementInputs inputs, {
  GameConfig config = gameConfig,
}) {
  final c = config.achievements;
  final sessions = inputs.sessions;
  final completed = [
    for (final s in sessions)
      if (s.completed) s,
  ];
  final progression = inputs.progression;

  var reps = 0;
  var effectiveSets = 0;
  final exercises = <String>{};
  for (final session in sessions) {
    for (final set in session.sets) {
      if (set.skipped) continue;
      reps += set.reps ?? 0;
      exercises.add(set.exerciseId);
      final rpe = set.rpe;
      if (rpe != null && rpe >= config.intensity.effectiveSetMinRpe) {
        effectiveSets++;
      }
    }
  }

  // Volume par semaine (lundi) : jambes, poussée / tirage, face / dos.
  final legMuscles = {
    for (final m in MuscleId.values)
      if (c.legMuscles.contains(m.key)) m,
  };
  final weeks = <CivilDate, _WeekVolume>{};
  final worked = <MuscleId>{};
  var flexibilitySeconds = 0;
  for (final session in sessions) {
    final volume = sessionVolume(session, inputs.exercisesById, config: config);
    final week = weekStartOf(CivilDate.ofLocal(session.startedAt));
    final w = weeks.putIfAbsent(week, _WeekVolume.new);
    flexibilitySeconds += volume.flexibilitySeconds;
    w
      ..push += volume.pushSets
      ..pull += volume.pullSets;
    for (final entry in volume.points.entries) {
      if (entry.value <= 0) continue;
      worked.add(entry.key);
      if (legMuscles.contains(entry.key)) w.legs += entry.value;
      if (entry.key.view == BodyView.front) {
        w.front += entry.value;
      } else {
        w.back += entry.value;
      }
    }
  }
  final ratio = config.balance.imbalanceRatio;
  bool balanced(double a, double b) =>
      a >= c.balancedWeekMinPoints &&
      b >= c.balancedWeekMinPoints &&
      (a > b ? a / b : b / a) <= ratio;

  int minutesOfDay(DateTime moment) {
    final local = moment.toLocal();
    return local.hour * 60 + local.minute;
  }

  final lastRoom = dungeonRoomProgramId(dungeonRoomCount - 1);
  final stats = [for (final stat in StatId.values) progression.stat(stat)];
  return {
    AchievementMetric.sessionsCompleted: completed.length,
    AchievementMetric.bestStreak: progression.bestStreak,
    AchievementMetric.dailyQuests: inputs.dailyQuestsDone,
    AchievementMetric.activeMinutes:
        sessions.fold<int>(0, (sum, s) => sum + s.activeSeconds) ~/ 60,
    AchievementMetric.totalReps: reps,
    AchievementMetric.effectiveSets: effectiveSets,
    AchievementMetric.longSessions: completed
        .where(
          (s) =>
              s.activeSeconds >= c.longSessionMinutes * 60 &&
              !s.exceededDailyCap,
        )
        .length,
    AchievementMetric.level: progression.level,
    AchievementMetric.strength: progression.stat(StatId.strength),
    AchievementMetric.endurance: progression.stat(StatId.endurance),
    AchievementMetric.agility: progression.stat(StatId.agility),
    AchievementMetric.vitality: progression.stat(StatId.vitality),
    AchievementMetric.willpower: progression.stat(StatId.willpower),
    AchievementMetric.lowestStat: stats.reduce((a, b) => a < b ? a : b),
    AchievementMetric.bossesDefeated: progression.defeatedBosses.length,
    AchievementMetric.firstTryBosses: progression.defeatedBosses
        .where((rank) => (inputs.trials.attempts[rank] ?? 1) <= 1)
        .length,
    AchievementMetric.shadows: inputs.shadows,
    AchievementMetric.distinctExercises: exercises.length,
    AchievementMetric.customExercises: inputs.customExercises,
    AchievementMetric.programs: inputs.programs,
    AchievementMetric.formatsTried: {for (final s in completed) s.format}
        .length,
    AchievementMetric.dungeonsCleared: completed
        .where((s) => s.programId == lastRoom)
        .length,
    AchievementMetric.itemsOwned: inputs.itemsOwned,
    AchievementMetric.eventsCompleted: inputs.eventsCompleted,
    AchievementMetric.legWeeksInARow: _longestRun(
      weeks,
      (w) => w.legs >= c.legWeekMinPoints,
    ),
    AchievementMetric.balancedPushPullWeeks: weeks.values
        .where((w) => balanced(w.push, w.pull))
        .length,
    AchievementMetric.balancedFrontBackWeeks: weeks.values
        .where((w) => balanced(w.front, w.back))
        .length,
    AchievementMetric.musclesWorked: worked.length,
    AchievementMetric.flexibilityMinutes: flexibilitySeconds ~/ 60,
    AchievementMetric.dawnSessions: completed
        .where((s) => minutesOfDay(s.startedAt) < c.dawnBeforeMinutes)
        .length,
    AchievementMetric.eveningSessions: completed
        .where((s) => minutesOfDay(s.startedAt) >= c.eveningFromMinutes)
        .length,
    AchievementMetric.newYearSessions: completed.where((s) {
      final day = CivilDate.ofLocal(s.startedAt);
      return day.month == 1 && day.day == 1;
    }).length,
    AchievementMetric.restDaysRespected: _restDaysRespected(inputs),
    AchievementMetric.painStops: sessions.where((s) => s.stoppedForPain).length,
  };
}

class _WeekVolume {
  double legs = 0;
  double push = 0;
  double pull = 0;
  double front = 0;
  double back = 0;
}

/// Plus longue suite de semaines consécutives qui vérifient [ok].
int _longestRun(
  Map<CivilDate, _WeekVolume> weeks,
  bool Function(_WeekVolume) ok,
) {
  final good = [
    for (final entry in weeks.entries)
      if (ok(entry.value)) entry.key,
  ]..sort();
  var best = 0;
  var run = 0;
  CivilDate? previous;
  for (final week in good) {
    run = previous != null && previous.addDays(7) == week ? run + 1 : 1;
    if (run > best) best = run;
    previous = week;
  }
  return best;
}

/// Jours de repos déclarés, passés depuis la première séance, sans séance.
int _restDaysRespected(AchievementInputs inputs) {
  if (inputs.sessions.isEmpty || inputs.restDays.isEmpty) return 0;
  final trained = {
    for (final s in inputs.sessions) CivilDate.ofLocal(s.startedAt),
  };
  final first = trained.reduce((a, b) => a.isBefore(b) ? a : b);
  final today = CivilDate.ofLocal(inputs.now);
  var count = 0;
  for (var day = first; day.isBefore(today); day = day.addDays(1)) {
    if (inputs.restDays.contains(day.weekday) && !trained.contains(day)) {
      count++;
    }
  }
  return count;
}
