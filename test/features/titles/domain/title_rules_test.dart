import 'package:arise/features/achievements/domain/achievements_state.dart';
import 'package:arise/features/titles/domain/title_rules.dart';
import 'package:arise/features/titles/domain/titles_state.dart';
import 'package:arise/features/trials/domain/trials_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final achievements = AchievementsState(
    unlocked: {
      'first_session': DateTime.utc(2026),
      'dawn_10': DateTime.utc(2026),
    },
  );
  const trials = TrialsState(titles: ['title_rockGuardian']);
  final earned = earnedTitles(trials: trials, achievements: achievements);

  test('titres des boss puis des hauts faits, sans doublon', () {
    expect(earned, [
      'title_rockGuardian',
      'title_awakened',
      'title_dawn_monarch',
    ]);
  });

  test('un titre débloque son aura', () {
    expect(earnedAuras(earned).map((a) => a.id), ['aura_dawn']);
  });

  test('on n’équipe que ce qui est obtenu', () {
    const state = TitlesState();
    expect(equipTitle(state, 'title_veteran', earned: earned), isNull);
    final titled = equipTitle(state, 'title_awakened', earned: earned)!;
    expect(titled.equippedTitle, 'title_awakened');
    expect(equipAura(titled, 'aura_storm', earned: earned), isNull);
    final aura = equipAura(titled, 'aura_dawn', earned: earned)!;
    expect(
      aura,
      const TitlesState(
        equippedTitle: 'title_awakened',
        equippedAura: 'aura_dawn',
      ),
    );
    expect(equipTitle(aura, null, earned: earned)?.equippedAura, 'aura_dawn');
  });

  test('un choix qui n’est plus obtenu n’est pas porté', () {
    const state = TitlesState(
      equippedTitle: 'title_veteran',
      equippedAura: 'aura_dawn',
    );
    expect(
      wornTitles(state, earned: const ['title_awakened']),
      const TitlesState(),
    );
  });
}
