import 'dart:math';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/profile/domain/player_profile.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/quest_board.dart';
import 'package:arise/features/quests/domain/quest_rules.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';

/// Lundi de la semaine de [day].
CivilDate weekStartOf(CivilDate day) => day.addDays(1 - day.weekday);

bool _inWeek(CivilDate weekStart, CivilDate day) =>
    !day.isBefore(weekStart) && day.isBefore(weekStart.addDays(7));

CivilDate _dayOf(CompletedSession session) =>
    CivilDate.ofLocal(session.startedAt);

int _seedOf(CivilDate day, int salt) =>
    (day.year * 10000 + day.month * 100 + day.day) * 31 + salt;

/// Tirage stable (même semaine, même résultat sur tous les appareils).
T? _pick<T>(List<T> pool, int seed) =>
    pool.isEmpty ? null : pool[seed.abs() % pool.length];

// --- Quête hebdomadaire ----------------------------------------------------

/// Quête de la semaine : séances complètes (jours d'entraînement moins un,
/// bornés), minutes d'effort actif selon le niveau, quêtes du jour.
WeeklyQuest generateWeeklyQuest({
  required CivilDate weekStart,
  required PlayerProfile profile,
  required int playerLevel,
  GameConfig config = gameConfig,
}) {
  final c = config.quests;
  final trainingDays = 7 - profile.restDays.length;
  final sessions = (trainingDays - 1).clamp(
    c.weeklySessionsMin,
    c.weeklySessionsMax,
  );
  final minutes =
      (c.weeklyActiveMinutesByFitnessLevel[profile.level.index] *
              questTargetMultiplier(playerLevel, config: c) /
              10)
          .round() *
      10;
  return WeeklyQuest(
    weekStart: weekStart,
    objectives: [
      WeeklyObjective(metric: WeeklyMetric.sessions, target: sessions),
      WeeklyObjective(metric: WeeklyMetric.activeMinutes, target: minutes),
      WeeklyObjective(
        metric: WeeklyMetric.dailyQuests,
        target: min(c.weeklyDailyQuests, max(1, trainingDays)),
      ),
    ],
  );
}

/// Avancement de chaque objectif de la semaine (plafonné à l'objectif).
List<int> weeklyProgress(
  WeeklyQuest quest,
  Iterable<CompletedSession> sessions,
) {
  final week = [
    for (final s in sessions)
      if (_inWeek(quest.weekStart, _dayOf(s))) s,
  ];
  return [
    for (final objective in quest.objectives)
      min(objective.target, switch (objective.metric) {
        WeeklyMetric.sessions => week.where((s) => s.completed).length,
        WeeklyMetric.activeMinutes =>
          week.fold<int>(0, (sum, s) => sum + s.activeSeconds) ~/ 60,
        WeeklyMetric.dailyQuests => quest.dailyQuestDays.length,
      }),
  ];
}

// --- Donjon hebdomadaire ---------------------------------------------------

/// Nombre de salles d'un donjon.
const int dungeonRoomCount = 3;

/// Préfixe des séances des salles de donjon.
const String dungeonProgramPrefix = 'dungeon_room_';

String dungeonRoomProgramId(int room) => '$dungeonProgramPrefix$room';

/// Salle désignée par un identifiant de séance, ou `null`.
int? dungeonRoomOfProgram(String programId) {
  if (!programId.startsWith(dungeonProgramPrefix)) return null;
  final room = int.tryParse(programId.substring(dungeonProgramPrefix.length));
  return room != null && room >= 0 && room < dungeonRoomCount ? room : null;
}

/// Thème de la semaine : force, endurance puis agilité, en alternance.
DungeonTheme dungeonThemeOf(CivilDate weekStart) {
  final weeks = weekStart.daysSince(const CivilDate(2026, 1, 5)) ~/ 7;
  return DungeonTheme.values[weeks % DungeonTheme.values.length];
}

/// Salles du donjon : séances générées à partir du catalogue validé et de
/// l'équipement du joueur, différentes d'une salle à l'autre.
///
/// - Crypte de Pierre (force) : trois exercices de force, en séries.
/// - Forêt des Échos (endurance) : circuit 20 s / 10 s d'exercices de cardio.
/// - Tour des Vents (agilité et gainage) : circuit d'agilité et de gainage.
List<Program> dungeonRooms({
  required DungeonRun run,
  required PlayerProfile profile,
  required int playerLevel,
  required Iterable<Exercise> catalog,
  GameConfig config = gameConfig,
}) {
  final c = config.quests;
  final eligible = questEligibleExercises(catalog, profile);
  final fitness = profile.level.index;
  final multiplier = questTargetMultiplier(playerLevel, config: c);
  final pool = switch (run.theme) {
    DungeonTheme.stoneCrypt => [
      for (final e in eligible)
        if (e.type == ExerciseType.reps && e.mainStat == StatId.strength) e,
    ],
    DungeonTheme.echoForest => [
      for (final e in eligible)
        if (e.mainStat == StatId.endurance &&
            e.id != 'walking' &&
            e.id != 'running' &&
            e.id != 'cycling')
          e,
    ],
    DungeonTheme.windTower => [
      for (final e in eligible)
        if (e.mainStat == StatId.agility ||
            (e.mainStat == StatId.vitality && e.type == ExerciseType.duration))
          e,
    ],
  };
  final defaults = config.intervalDefaults;
  return [
    for (var room = 0; room < dungeonRoomCount; room++)
      () {
        // Trois exercices par salle, en décalant le tirage d'une salle à
        // l'autre pour varier les efforts.
        final picks = <Exercise>[];
        for (var k = 0; k < pool.length && picks.length < 3; k++) {
          final e = _pick(pool, _seedOf(run.weekStart, room * 7 + k * 3))!;
          if (!picks.contains(e)) picks.add(e);
        }
        for (final e in pool) {
          if (picks.length >= min(3, pool.length)) break;
          if (!picks.contains(e)) picks.add(e);
        }
        final id = dungeonRoomProgramId(room);
        if (run.theme == DungeonTheme.stoneCrypt) {
          return Program(
            id: id,
            name: id,
            format: ProgramFormat.strength,
            items: [
              for (final e in picks)
                ProgramItem(
                  exerciseId: e.id,
                  sets: c.dungeonSetsPerExercise,
                  reps: max(
                    5,
                    (c.dungeonRepsByFitnessLevel[fitness] *
                            multiplier *
                            c.difficultyTargetFactor[(e.difficulty - 1).clamp(
                              0,
                              c.difficultyTargetFactor.length - 1,
                            )])
                        .round(),
                  ),
                  restSeconds: 60,
                ),
            ],
          );
        }
        return Program(
          id: id,
          name: id,
          format: ProgramFormat.interval,
          items: [for (final e in picks) ProgramItem(exerciseId: e.id)],
          interval: IntervalSettings(
            workSeconds: defaults.workSeconds,
            restSeconds: defaults.restSeconds,
            rounds: (c.dungeonRoundsByFitnessLevel[fitness] * multiplier)
                .round(),
            cycles: 1,
            restBetweenCyclesSeconds: defaults.restBetweenCyclesSeconds,
          ),
        );
      }(),
  ];
}

/// Jours où chaque salle a été franchie, dans l'ordre : une salle compte
/// si sa séance est complète, dans la semaine du donjon, un jour après la
/// salle précédente (une salle par jour au plus, le repos est respecté).
List<CivilDate> dungeonClearedDays(
  DungeonRun run,
  Iterable<CompletedSession> sessions,
) {
  final ordered = [
    for (final s in sessions)
      if (s.completed && _inWeek(run.weekStart, _dayOf(s))) s,
  ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final cleared = <CivilDate>[];
  for (final session in ordered) {
    final room = dungeonRoomOfProgram(session.programId ?? '');
    if (room != cleared.length) continue;
    final day = _dayOf(session);
    if (cleared.isNotEmpty && !day.isAfter(cleared.last)) continue;
    cleared.add(day);
    if (cleared.length == dungeonRoomCount) break;
  }
  return cleared;
}

/// Prochaine salle ouverte aujourd'hui, ou `null` : donjon terminé, salle
/// déjà franchie aujourd'hui, ou jour de repos / maladie ([resting]).
int? nextDungeonRoom(
  List<CivilDate> cleared,
  CivilDate today, {
  bool resting = false,
}) {
  if (resting || cleared.length >= dungeonRoomCount) return null;
  if (cleared.isNotEmpty && cleared.last == today) return null;
  return cleared.length;
}

/// Butin du donjon : un objet commun ou rare de la boutique pas encore
/// possédé (tirage stable), ou `null` si tout est déjà possédé.
EquipmentItem? dungeonLoot(DungeonRun run, Inventory inventory) {
  final candidates = [
    for (final item in equipmentCatalog)
      if ((item.rarity == Rarity.common || item.rarity == Rarity.rare) &&
          !inventory.owned.contains(item.id))
        item,
  ];
  return _pick(candidates, _seedOf(run.weekStart, 97));
}

// --- Événements d'Arisia ---------------------------------------------------

/// Événement saisonnier du calendrier d'Arisia (dates locales, incluses).
class ArisiaEvent {
  const ArisiaEvent({
    required this.id,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
    required this.metric,
    required this.target,
  });

  final String id;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;
  final WeeklyMetric metric;
  final int target;
}

/// Calendrier des événements (créations originales).
const List<ArisiaEvent> arisiaEvents = [
  ArisiaEvent(
    id: 'spring_awakening',
    startMonth: 3,
    startDay: 18,
    endMonth: 4,
    endDay: 1,
    metric: WeeklyMetric.sessions,
    target: 8,
  ),
  ArisiaEvent(
    id: 'summer_march',
    startMonth: 6,
    startDay: 18,
    endMonth: 7,
    endDay: 2,
    metric: WeeklyMetric.activeMinutes,
    target: 300,
  ),
  ArisiaEvent(
    id: 'harvest_feast',
    startMonth: 9,
    startDay: 20,
    endMonth: 10,
    endDay: 4,
    metric: WeeklyMetric.sessions,
    target: 8,
  ),
  ArisiaEvent(
    id: 'winter_solstice',
    startMonth: 12,
    startDay: 18,
    endMonth: 1,
    endDay: 3,
    metric: WeeklyMetric.activeMinutes,
    target: 300,
  ),
];

/// Édition en cours d'un événement.
class EventEdition {
  const EventEdition({
    required this.event,
    required this.start,
    required this.end,
  });

  final ArisiaEvent event;
  final CivilDate start;
  final CivilDate end;

  /// Clé de l'édition (`<id>-<année de début>`).
  String get key => '${event.id}-${start.year}';
}

/// Événement en cours le [day], ou `null`.
EventEdition? activeEvent(CivilDate day) {
  for (final event in arisiaEvents) {
    for (final year in [day.year - 1, day.year]) {
      final start = CivilDate(year, event.startMonth, event.startDay);
      final end = CivilDate(
        event.endMonth < event.startMonth ? year + 1 : year,
        event.endMonth,
        event.endDay,
      );
      if (!day.isBefore(start) && !day.isAfter(end)) {
        return EventEdition(event: event, start: start, end: end);
      }
    }
  }
  return null;
}

/// Avancement d'un événement (plafonné à l'objectif).
int eventProgress(EventEdition edition, Iterable<CompletedSession> sessions) {
  final inWindow = [
    for (final s in sessions)
      if (!_dayOf(s).isBefore(edition.start) && !_dayOf(s).isAfter(edition.end))
        s,
  ];
  final done = switch (edition.event.metric) {
    WeeklyMetric.sessions => inWindow.where((s) => s.completed).length,
    WeeklyMetric.activeMinutes =>
      inWindow.fold<int>(0, (sum, s) => sum + s.activeSeconds) ~/ 60,
    WeeklyMetric.dailyQuests => 0,
  };
  return min(done, edition.event.target);
}

// --- Évaluation -------------------------------------------------------------

/// Récompense en XP et en pièces d'une quête au-delà du jour.
class BoardReward {
  const BoardReward({required this.xp, required this.coins});

  final int xp;
  final Coins coins;
}

/// Bilan du tableau des quêtes après une séance.
class BoardOutcome {
  const BoardOutcome({
    required this.board,
    required this.state,
    required this.inventory,
    this.weeklyReward,
    this.roomCleared,
    this.dungeonCompleted = false,
    this.lootItem,
    this.lootCoins = Coins.zero,
    this.event,
    this.eventReward,
  });

  final QuestBoard board;
  final ProgressionState state;

  /// Inventaire avec le butin, ou `null` s'il n'a pas changé.
  final Inventory? inventory;
  final BoardReward? weeklyReward;

  /// Salle franchie grâce à la séance (0 à 2).
  final int? roomCleared;
  final bool dungeonCompleted;
  final EquipmentItem? lootItem;
  final Coins lootCoins;
  final EventEdition? event;
  final BoardReward? eventReward;

  bool get isEmpty =>
      weeklyReward == null && roomCleared == null && eventReward == null;
}

BoardReward _weekly(int level, GameConfig config) =>
    weeklyReward(level, config: config);

/// Récompense de la quête hebdomadaire selon le niveau.
BoardReward weeklyReward(int playerLevel, {GameConfig config = gameConfig}) {
  final c = config.quests;
  return BoardReward(
    xp: c.weeklyRewardXpBase + max(0, playerLevel) * c.weeklyRewardXpPerLevel,
    coins: Coins.of(silver: c.weeklyRewardSilver, config: config.coins),
  );
}

ProgressionState _pay(
  ProgressionState state,
  int xp,
  Coins coins,
  GameConfig config,
) {
  final gain = addXp(state, xp, config: config);
  return gain.state.copyWith(coins: gain.state.coins + coins.bronzeTotal);
}

/// Tableau à jour pour la semaine de [today] (nouvelle quête hebdomadaire
/// et nouveau donjon le lundi).
QuestBoard refreshBoard({
  required QuestBoard board,
  required CivilDate today,
  required PlayerProfile profile,
  required int playerLevel,
  GameConfig config = gameConfig,
}) {
  final week = weekStartOf(today);
  var next = board;
  if (board.weekly?.weekStart != week) {
    next = next.copyWith(
      weekly: generateWeeklyQuest(
        weekStart: week,
        profile: profile,
        playerLevel: playerLevel,
        config: config,
      ),
    );
  }
  if (board.dungeon?.weekStart != week) {
    next = next.copyWith(
      dungeon: DungeonRun(weekStart: week, theme: dungeonThemeOf(week)),
    );
  }
  return next;
}

/// Évalue la semaine, le donjon et l'événement en cours d'après les séances
/// enregistrées ; chaque récompense n'est versée qu'une fois.
///
/// [dailyQuestDone] signale que la quête du jour vient d'être accomplie.
BoardOutcome evaluateBoard({
  required QuestBoard board,
  required ProgressionState state,
  required Inventory inventory,
  required Iterable<CompletedSession> sessions,
  required DateTime now,
  required PlayerProfile profile,
  bool dailyQuestDone = false,
  CompletedSession? lastSession,
  GameConfig config = gameConfig,
}) {
  final c = config.quests;
  final today = CivilDate.ofLocal(now);
  var next = refreshBoard(
    board: board,
    today: today,
    profile: profile,
    playerLevel: state.level,
    config: config,
  );
  var progression = state;
  Inventory? newInventory;

  // Semaine.
  var weekly = next.weekly!;
  final dayKey = today.toString();
  if (dailyQuestDone && !weekly.dailyQuestDays.contains(dayKey)) {
    weekly = weekly.copyWith(
      dailyQuestDays: [...weekly.dailyQuestDays, dayKey],
    );
  }
  BoardReward? weeklyReward;
  final progress = weeklyProgress(weekly, sessions);
  final weeklyDone = [for (var i = 0; i < weekly.objectives.length; i++) i]
      .every((i) => progress[i] >= weekly.objectives[i].target);
  if (!weekly.claimed && weeklyDone) {
    weeklyReward = _weekly(state.level, config);
    progression = _pay(
      progression,
      weeklyReward.xp,
      weeklyReward.coins,
      config,
    );
    weekly = weekly.copyWith(claimed: true);
  }
  next = next.copyWith(weekly: weekly);

  // Donjon.
  var dungeon = next.dungeon!;
  final cleared = dungeonClearedDays(dungeon, sessions);
  final lastRoom = lastSession == null
      ? null
      : dungeonRoomOfProgram(lastSession.programId ?? '');
  final roomCleared =
      lastRoom != null &&
          lastRoom < cleared.length &&
          cleared[lastRoom] == CivilDate.ofLocal(lastSession!.startedAt)
      ? lastRoom
      : null;
  var dungeonCompleted = false;
  EquipmentItem? loot;
  var lootCoins = Coins.zero;
  if (!dungeon.looted && cleared.length == dungeonRoomCount) {
    dungeonCompleted = true;
    loot = dungeonLoot(dungeon, inventory);
    if (loot != null) {
      newInventory = inventory.copyWith(owned: [...inventory.owned, loot.id]);
    } else {
      lootCoins = Coins.of(
        silver: c.dungeonFallbackSilver,
        config: config.coins,
      );
    }
    progression = _pay(progression, c.dungeonRewardXp, lootCoins, config);
    dungeon = dungeon.copyWith(looted: true, lootItemId: loot?.id);
  }
  next = next.copyWith(dungeon: dungeon);

  // Événement.
  final edition = activeEvent(today);
  BoardReward? eventReward;
  if (edition != null &&
      !next.claimedEvents.contains(edition.key) &&
      eventProgress(edition, sessions) >= edition.event.target) {
    eventReward = BoardReward(
      xp: c.eventRewardXp,
      coins: Coins.of(silver: c.eventRewardSilver, config: config.coins),
    );
    progression = _pay(progression, eventReward.xp, eventReward.coins, config);
    next = next.copyWith(claimedEvents: [...next.claimedEvents, edition.key]);
  }

  return BoardOutcome(
    board: next,
    state: progression,
    inventory: newInventory,
    weeklyReward: weeklyReward,
    roomCleared: roomCleared,
    dungeonCompleted: dungeonCompleted,
    lootItem: loot,
    lootCoins: lootCoins,
    event: edition,
    eventReward: eventReward,
  );
}

/// Bilan complet des quêtes après une séance : quête du jour (et de
/// pénalité), puis semaine, donjon et événement.
class QuestReport {
  const QuestReport({required this.daily, required this.board});

  final QuestOutcome daily;
  final BoardOutcome board;

  bool get isEmpty => daily.isEmpty && board.isEmpty;
}
