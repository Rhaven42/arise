import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/inventory/domain/equipment.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:arise/features/quests/domain/quest_board.dart';
import 'package:arise/features/quests/domain/quest_board_rules.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

// Semaine du lundi 9 novembre 2026.
const _monday = CivilDate(2026, 11, 9);

DateTime _at(CivilDate day, [int hour = 12]) =>
    DateTime(day.year, day.month, day.day, hour);

CompletedSession _session(
  CivilDate day, {
  String? programId,
  bool completed = true,
  int activeSeconds = 1200,
  int hour = 12,
}) => CompletedSession(
  id: 's-$day-$programId-$hour',
  programName: 'test',
  programId: programId,
  format: ProgramFormat.strength,
  startedAt: _at(day, hour).toUtc(),
  endedAt: _at(day, hour + 1).toUtc(),
  sets: const [],
  activeSeconds: activeSeconds,
  xpEarned: 10,
  completed: completed,
);

void main() {
  test('la semaine commence le lundi', () {
    expect(weekStartOf(const CivilDate(2026, 11, 11)), _monday);
    expect(weekStartOf(const CivilDate(2026, 11, 15)), _monday);
    expect(weekStartOf(_monday), _monday);
  });

  group('quête hebdomadaire', () {
    test('objectifs selon les jours d’entraînement et le niveau', () {
      final quest = generateWeeklyQuest(
        weekStart: _monday,
        profile: sampleProfile,
        playerLevel: 1,
      );
      // 5 jours d'entraînement : 4 séances.
      expect(quest.objectives.map((o) => o.metric), WeeklyMetric.values);
      expect(quest.objectives.first.target, 4);
      expect(quest.objectives[1].target % 10, 0);
      expect(quest.objectives.last.target, gameConfig.quests.weeklyDailyQuests);
    });

    test('avancement : séances complètes et minutes de la semaine', () {
      final quest = generateWeeklyQuest(
        weekStart: _monday,
        profile: sampleProfile,
        playerLevel: 1,
      ).copyWith(dailyQuestDays: ['2026-11-09']);
      final progress = weeklyProgress(quest, [
        _session(_monday),
        _session(_monday.addDays(1), completed: false),
        // Semaine précédente : ignorée.
        _session(_monday.addDays(-1)),
      ]);
      expect(progress, [1, 40, 1]);
    });
  });

  group('donjon', () {
    final run = DungeonRun(weekStart: _monday, theme: dungeonThemeOf(_monday));

    test('trois salles du catalogue validé, différentes et réalisables', () {
      final ids = {for (final e in testCatalog) e.id};
      for (final theme in DungeonTheme.values) {
        final rooms = dungeonRooms(
          run: run.copyWith(theme: theme),
          profile: sampleProfile,
          playerLevel: 1,
          catalog: testCatalog,
        );
        expect(rooms, hasLength(dungeonRoomCount));
        for (var i = 0; i < rooms.length; i++) {
          expect(rooms[i].id, dungeonRoomProgramId(i));
          expect(rooms[i].items, isNotEmpty, reason: theme.name);
          for (final item in rooms[i].items) {
            expect(ids, contains(item.exerciseId));
          }
        }
      }
    });

    test('une salle par jour, dans l’ordre', () {
      final sessions = [
        _session(_monday, programId: 'dungeon_room_0'),
        // Même jour : la salle 2 ne compte pas encore.
        _session(_monday, programId: 'dungeon_room_1', hour: 15),
        _session(_monday.addDays(1), programId: 'dungeon_room_1'),
        // Salle interrompue : ne compte pas.
        _session(
          _monday.addDays(2),
          programId: 'dungeon_room_2',
          completed: false,
        ),
      ];
      final cleared = dungeonClearedDays(run, sessions);
      expect(cleared, [_monday, _monday.addDays(1)]);
      expect(nextDungeonRoom(cleared, _monday.addDays(1)), isNull);
      expect(nextDungeonRoom(cleared, _monday.addDays(2)), 2);
      expect(
        nextDungeonRoom(cleared, _monday.addDays(2), resting: true),
        isNull,
      );
    });

    test('butin : un objet commun ou rare non possédé, sinon des pièces', () {
      final loot = dungeonLoot(run, const Inventory())!;
      expect(loot.rarity, anyOf(Rarity.common, Rarity.rare));
      final all = Inventory(
        owned: [for (final item in equipmentCatalog) item.id],
      );
      expect(dungeonLoot(run, all), isNull);
    });
  });

  group('événements', () {
    test('le solstice d’hiver couvre le passage d’année', () {
      final edition = activeEvent(const CivilDate(2027, 1, 2))!;
      expect(edition.event.id, 'winter_solstice');
      expect(edition.key, 'winter_solstice-2026');
      expect(activeEvent(const CivilDate(2026, 11, 11)), isNull);
    });
  });

  group('evaluateBoard', () {
    final state = ProgressionState.initial(_monday).copyWith(level: 3);

    test('donjon terminé : butin livré une seule fois', () {
      final sessions = [
        for (var i = 0; i < dungeonRoomCount; i++)
          _session(_monday.addDays(i), programId: dungeonRoomProgramId(i)),
      ];
      final outcome = evaluateBoard(
        board: const QuestBoard(),
        state: state,
        inventory: const Inventory(),
        sessions: sessions,
        now: _at(_monday.addDays(2), 14),
        profile: sampleProfile,
        lastSession: sessions.last,
      );
      expect(outcome.roomCleared, 2);
      expect(outcome.dungeonCompleted, isTrue);
      expect(outcome.lootItem, isNotNull);
      expect(outcome.inventory?.owned, [outcome.lootItem!.id]);
      expect(outcome.board.dungeon?.looted, isTrue);
      expect(outcome.state.totalXp, greaterThan(state.totalXp));

      final again = evaluateBoard(
        board: outcome.board,
        state: outcome.state,
        inventory: outcome.inventory!,
        sessions: sessions,
        now: _at(_monday.addDays(2), 15),
        profile: sampleProfile,
      );
      expect(again.dungeonCompleted, isFalse);
      expect(again.inventory, isNull);
      expect(again.state, outcome.state);
    });

    test('semaine accomplie : récompense versée une seule fois', () {
      final weekly = generateWeeklyQuest(
        weekStart: _monday,
        profile: sampleProfile,
        playerLevel: 3,
      ).copyWith(dailyQuestDays: ['2026-11-09', '2026-11-10']);
      final sessions = [
        for (var i = 0; i < 6; i++)
          _session(_monday.addDays(i), activeSeconds: 3600),
      ];
      final outcome = evaluateBoard(
        board: QuestBoard(weekly: weekly),
        state: state,
        inventory: const Inventory(),
        sessions: sessions,
        now: _at(_monday.addDays(5), 18),
        profile: sampleProfile,
        dailyQuestDone: true,
      );
      expect(outcome.board.weekly?.dailyQuestDays, hasLength(3));
      expect(outcome.weeklyReward?.xp, weeklyReward(3).xp);
      expect(outcome.board.weekly?.claimed, isTrue);
      expect(
        outcome.state.coins,
        state.coins + weeklyReward(3).coins.bronzeTotal,
      );
    });

    test('un nouveau lundi renouvelle la semaine et le donjon', () {
      final board = refreshBoard(
        board: const QuestBoard(),
        today: _monday.addDays(3),
        profile: sampleProfile,
        playerLevel: 1,
      );
      final next = refreshBoard(
        board: board,
        today: _monday.addDays(7),
        profile: sampleProfile,
        playerLevel: 1,
      );
      expect(next.weekly?.weekStart, _monday.addDays(7));
      expect(next.dungeon?.weekStart, _monday.addDays(7));
      expect(next.dungeon?.theme, isNot(board.dungeon?.theme));
    });
  });
}
