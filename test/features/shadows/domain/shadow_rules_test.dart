import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/hero_class.dart';
import 'package:arise/features/quests/domain/quest_board.dart';
import 'package:arise/features/shadows/domain/shadow_rules.dart';
import 'package:arise/features/shadows/domain/shadows_state.dart';
import 'package:flutter_test/flutter_test.dart';

ShadowsState _army(int count, {HeroClass? heroClass}) {
  var state = const ShadowsState();
  for (var i = 0; i < count; i++) {
    state = offerDungeonShadow(
      state,
      DungeonRun(
        weekStart: const CivilDate(2026, 1, 5).addDays(7 * i),
        theme: DungeonTheme.stoneCrypt,
      ),
      playerRank: RankId.b,
    );
    state = extractShadow(
      state,
      state.pending.single.key,
      now: DateTime.utc(2026),
      heroClass: heroClass,
    )!;
  }
  return state;
}

void main() {
  test('seuls les boss à partir du rang B offrent une Ombre', () {
    final state = offerBossShadows(const ShadowsState(), {
      RankId.e,
      RankId.d,
      RankId.c,
      RankId.b,
    });
    expect(state.pending.map((p) => p.key), ['boss_b']);
    expect(state.pending.single.source, ShadowSource.boss);
    // Une seconde offre ne crée pas de doublon.
    expect(offerBossShadows(state, {RankId.b}), state);
  });

  test('un donjon offre une Ombre à partir du rang B', () {
    const run = DungeonRun(
      weekStart: CivilDate(2026, 11, 9),
      theme: DungeonTheme.echoForest,
    );
    expect(
      offerDungeonShadow(const ShadowsState(), run, playerRank: RankId.c),
      const ShadowsState(),
    );
    final state = offerDungeonShadow(
      const ShadowsState(),
      run,
      playerRank: RankId.b,
    );
    expect(state.pending.single.stat, StatId.agility);
    expect(state.pending.single.key, 'dungeon_2026-11-09');
  });

  test('extraction : active tant qu’il reste de la place (5)', () {
    final state = _army(6);
    expect(state.shadows, hasLength(6));
    expect(state.active, hasLength(5));
    expect(state.pending, isEmpty);
    expect(extractShadow(state, 'absent', now: DateTime.utc(2026)), isNull);
  });

  test('le Nécromancien en active 7, au bonus doublé', () {
    final state = _army(7, heroClass: HeroClass.necromancer);
    expect(state.active, hasLength(7));
    final necro = shadowStatMultipliers(
      state,
      heroClass: HeroClass.necromancer,
    );
    expect(
      necro[StatId.strength],
      closeTo(1.04 * 1.04 * 1.04 * 1.04 * 1.04 * 1.04 * 1.04, 1e-9),
    );
    // Une autre classe : 5 Ombres en jeu, +2 % chacune.
    final other = shadowStatMultipliers(state, heroClass: HeroClass.tank);
    expect(
      other[StatId.strength],
      closeTo(1.02 * 1.02 * 1.02 * 1.02 * 1.02, 1e-9),
    );
  });

  test('mettre au repos puis réactiver ; refus quand c’est plein', () {
    final state = _army(6);
    final resting = state.shadows.last.id;
    expect(toggleShadow(state, resting).issue, ShadowIssue.full);
    final freed = toggleShadow(state, state.active.first).state;
    expect(freed.active, hasLength(4));
    final back = toggleShadow(freed, resting);
    expect(back.issue, isNull);
    expect(back.state.active, contains(resting));
    expect(toggleShadow(state, 'absent').issue, ShadowIssue.unknown);
  });
}
