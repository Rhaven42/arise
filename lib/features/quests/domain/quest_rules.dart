import 'dart:math';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/daily_quest.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';

/// Générateur pseudo-aléatoire stable (xorshift 32 bits) : une même graine
/// donne la même quête sur tous les appareils.
class _StableRandom {
  _StableRandom(int seed) : _state = (seed & 0xFFFFFFFF) == 0 ? 1 : seed;

  int _state;

  int nextInt(int max) {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state % max;
  }
}

int _seedOf(CivilDate day) => day.year * 10000 + day.month * 100 + day.day;

/// Arrondit au multiple de [step] le plus proche (au moins [step]).
int _roundTo(double value, int step) =>
    max(step, (value / step).round() * step);

/// Multiplicateur des objectifs selon le niveau du joueur (plafonné).
double questTargetMultiplier(int playerLevel, {QuestsConfig? config}) {
  final c = config ?? gameConfig.quests;
  return min(
    1 + max(0, playerLevel) * c.growthPerPlayerLevel,
    c.maxTargetMultiplier,
  );
}

/// Exercices utilisables dans une quête : catalogue validé (jamais un
/// exercice en attente de relecture ni personnalisé), équipement du joueur
/// et difficulté au plus d'un cran au-dessus de son niveau.
List<Exercise> questEligibleExercises(
  Iterable<Exercise> catalog,
  PlayerProfile profile,
) => [
  for (final exercise in catalog)
    if (!exercise.isCustom &&
        exercise.reviewStatus == ReviewStatus.validated &&
        exercise.isAvailableWith(profile.equipment) &&
        exercise.difficulty <= profile.level.index + 2)
      exercise,
];

/// Génère la quête quotidienne du Système (SPEC §9, §30).
///
/// - Jour de repos déclaré ou mode maladie : pas d'objectif, le Système
///   invite à récupérer (le repos est respecté).
/// - Sinon 3 ou 4 objectifs : deux exercices de force aux muscles
///   principaux différents, un effort de cardio chronométré et, une fois
///   sur deux, un gainage. Les quantités dépendent du niveau du
///   questionnaire, du niveau du joueur (plafonné) et de la difficulté.
DailyQuest generateDailyQuest({
  required CivilDate day,
  required PlayerProfile profile,
  required int playerLevel,
  required bool sick,
  required Iterable<Exercise> catalog,
  GameConfig config = gameConfig,
}) {
  if (sick || profile.restDays.contains(day.weekday)) {
    return DailyQuest(day: day, restDay: true);
  }
  final c = config.quests;
  final random = _StableRandom(_seedOf(day));
  final eligible = questEligibleExercises(catalog, profile);
  final fitness = profile.level.index;
  final multiplier = questTargetMultiplier(playerLevel, config: c);

  T? pick<T>(List<T> pool) =>
      pool.isEmpty ? null : pool[random.nextInt(pool.length)];

  double factor(Exercise exercise) =>
      c.difficultyTargetFactor[(exercise.difficulty - 1).clamp(
        0,
        c.difficultyTargetFactor.length - 1,
      )];

  QuestObjective reps(Exercise exercise) => QuestObjective(
    exerciseId: exercise.id,
    metric: QuestMetric.reps,
    target: _roundTo(
      c.repsTargetByFitnessLevel[fitness] * multiplier * factor(exercise),
      c.repsRounding,
    ),
  );

  final strength = [
    for (final e in eligible)
      if (e.type == ExerciseType.reps &&
          e.volumeRule == VolumeRule.strength &&
          e.mainStat == StatId.strength)
        e,
  ];
  final cardio = [
    for (final e in eligible)
      if (e.type == ExerciseType.duration && e.volumeRule == VolumeRule.cardio)
        e,
  ];
  final holds = [
    for (final e in eligible)
      if (e.type == ExerciseType.duration &&
          e.volumeRule == VolumeRule.strength)
        e,
  ];

  final count =
      c.dailyObjectivesMin +
      random.nextInt(c.dailyObjectivesMax - c.dailyObjectivesMin + 1);
  final objectives = <QuestObjective>[];

  final first = pick(strength);
  if (first != null) {
    objectives.add(reps(first));
    // Second exercice de force : d'autres muscles principaux si possible.
    final others = [
      for (final e in strength)
        if (e.id != first.id &&
            !e.primaryMuscles.any(first.primaryMuscles.contains))
          e,
    ];
    final second = pick(
      others.isEmpty
          ? [
              for (final e in strength)
                if (e.id != first.id) e,
            ]
          : others,
    );
    if (second != null) objectives.add(reps(second));
  }
  final run = pick(cardio);
  if (run != null) {
    final minutes = (c.cardioMinutesTargetByFitnessLevel[fitness] * multiplier)
        .round();
    objectives.add(
      QuestObjective(
        exerciseId: run.id,
        metric: QuestMetric.seconds,
        target: max(1, minutes) * 60,
      ),
    );
  }
  final hold = objectives.length < count ? pick(holds) : null;
  if (hold != null) {
    objectives.add(
      QuestObjective(
        exerciseId: hold.id,
        metric: QuestMetric.seconds,
        target: _roundTo(
          c.holdSecondsTargetByFitnessLevel[fitness] *
              multiplier *
              factor(hold),
          5,
        ),
      ),
    );
  }
  return DailyQuest(day: day, objectives: objectives);
}

/// Quantité réalisée pour chaque objectif pendant le jour de la quête
/// (séances de toutes origines, efforts sautés exclus), plafonnée à
/// l'objectif.
List<int> questProgress(
  List<QuestObjective> objectives,
  CivilDate day,
  Iterable<CompletedSession> sessions,
) {
  final done = List<int>.filled(objectives.length, 0);
  for (final session in sessions) {
    if (CivilDate.ofLocal(session.startedAt) != day) continue;
    for (final set in session.sets) {
      if (set.skipped) continue;
      for (var i = 0; i < objectives.length; i++) {
        final objective = objectives[i];
        if (objective.exerciseId != set.exerciseId) continue;
        done[i] += switch (objective.metric) {
          QuestMetric.reps => set.reps ?? 0,
          QuestMetric.seconds => set.activeSeconds,
        };
      }
    }
  }
  return [
    for (var i = 0; i < objectives.length; i++)
      min(done[i], objectives[i].target),
  ];
}

bool objectivesMet(List<QuestObjective> objectives, List<int> progress) =>
    objectives.isNotEmpty &&
    [for (var i = 0; i < objectives.length; i++) i]
        .every((i) => progress[i] >= objectives[i].target);

/// Quête de pénalité : une part des objectifs du jour (arrondie au-dessus),
/// courte et raisonnable (SPEC §7).
List<QuestObjective> penaltyObjectives(
  DailyQuest quest, {
  QuestsConfig? config,
}) {
  final share = (config ?? gameConfig.quests).penaltyTargetShare;
  return [
    for (final objective in quest.objectives)
      objective.copyWith(target: max(1, (objective.target * share).ceil())),
  ];
}

/// Récompense de la quête quotidienne.
class QuestReward {
  const QuestReward({
    required this.xp,
    required this.coins,
    required this.willpower,
  });

  final int xp;
  final Coins coins;
  final int willpower;
}

QuestReward dailyQuestReward(int playerLevel, {GameConfig? config}) {
  final c = config ?? gameConfig;
  final xp =
      c.quests.rewardXpBase + max(0, playerLevel) * c.quests.rewardXpPerLevel;
  return QuestReward(
    xp: xp,
    coins: Coins(xp),
    willpower: c.quests.rewardWillpower,
  );
}

/// Bilan des quêtes après une séance ou à l'ouverture.
class QuestOutcome {
  const QuestOutcome({
    required this.quest,
    required this.state,
    this.reward,
    this.gain,
    this.dayValidated = false,
    this.chest = Coins.zero,
    this.penaltyCleared = false,
  });

  final DailyQuest quest;
  final ProgressionState state;

  /// Récompense versée maintenant (quête terminée), sinon `null`.
  final QuestReward? reward;
  final XpGain? gain;

  /// La quête a validé le jour (aucune séance complète ne l'avait fait).
  final bool dayValidated;
  final Coins chest;

  /// La quête de pénalité vient d'être accomplie : le malus est levé.
  final bool penaltyCleared;

  bool get isEmpty => reward == null && !penaltyCleared;
}

/// Évalue les quêtes du jour d'après les séances enregistrées :
/// - quête de pénalité accomplie pendant le malus → malus levé ;
/// - quête quotidienne terminée → récompense versée une seule fois, Volonté
///   et validation du jour (série prolongée).
QuestOutcome evaluateQuests({
  required DailyQuest quest,
  required ProgressionState state,
  required Iterable<CompletedSession> sessions,
  required DateTime now,
  required Set<int> restDays,
  GameConfig config = gameConfig,
}) {
  final today = CivilDate.ofLocal(now);
  if (quest.day != today || !quest.hasObjectives) {
    return QuestOutcome(quest: quest, state: state);
  }
  var next = state;
  var updated = quest;
  var penaltyCleared = false;
  if (state.isPenaltyActive(now) && !quest.penaltyCleared) {
    final objectives = penaltyObjectives(quest, config: config.quests);
    if (objectivesMet(objectives, questProgress(objectives, today, sessions))) {
      next = next.copyWith(penaltyUntil: null);
      updated = updated.copyWith(penaltyCleared: true);
      penaltyCleared = true;
    }
  }

  if (quest.claimed ||
      !objectivesMet(
        quest.objectives,
        questProgress(quest.objectives, today, sessions),
      )) {
    return QuestOutcome(
      quest: updated,
      state: next,
      penaltyCleared: penaltyCleared,
    );
  }

  final reward = dailyQuestReward(next.level, config: config);
  final gain = addXp(next, reward.xp, config: config);
  next = gain.state.copyWith(
    coins: gain.state.coins + reward.coins.bronzeTotal,
    willpowerEarned: gain.state.willpowerEarned + reward.willpower,
  );
  final validation = validateDay(
    next,
    day: today,
    restDays: restDays,
    config: config,
  );
  if (validation != null) next = validation.state;
  return QuestOutcome(
    quest: updated.copyWith(claimed: true),
    state: next,
    reward: reward,
    gain: gain,
    dayValidated: validation != null,
    chest: validation?.chest ?? Coins.zero,
    penaltyCleared: penaltyCleared,
  );
}

/// Séance proposée pour terminer les objectifs restants : musculation,
/// répétitions découpées en séries, gainage et cardio chronométrés.
Program? questProgram({
  required String id,
  required String name,
  required List<QuestObjective> objectives,
  required List<int> progress,
  QuestsConfig? config,
}) {
  final c = config ?? gameConfig.quests;
  final items = <ProgramItem>[];
  for (var i = 0; i < objectives.length; i++) {
    final objective = objectives[i];
    final left = objective.target - progress[i];
    if (left <= 0) continue;
    switch (objective.metric) {
      case QuestMetric.reps:
        final sets = (left / c.maxRepsPerSet).ceil();
        items.add(
          ProgramItem(
            exerciseId: objective.exerciseId,
            sets: sets,
            reps: (left / sets).ceil(),
            restSeconds: 60,
          ),
        );
      case QuestMetric.seconds:
        final sets = objective.target > c.maxHoldSecondsPerSet * 3
            ? 1
            : (left / c.maxHoldSecondsPerSet).ceil();
        items.add(
          ProgramItem(
            exerciseId: objective.exerciseId,
            sets: sets,
            durationSeconds: (left / sets).ceil(),
            restSeconds: 45,
          ),
        );
    }
  }
  if (items.isEmpty) return null;
  return Program(
    id: id,
    name: name,
    format: ProgramFormat.strength,
    items: items,
  );
}
