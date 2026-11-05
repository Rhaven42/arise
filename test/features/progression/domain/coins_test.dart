import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/progression/domain/coins.dart';
import 'package:arise/features/progression/domain/progression_rules.dart';
import 'package:arise/features/progression/domain/progression_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('100 bronze = 1 argent, 100 argent = 1 or', () {
    final coins = Coins.of(gold: 2, silver: 3, bronze: 45);
    expect(coins.bronzeTotal, 20345);
    expect(coins.gold(), 2);
    expect(coins.silver(), 3);
    expect(coins.bronze(), 45);
    expect(const Coins(199).silver(), 1);
    expect(const Coins(199).bronze(), 99);
    expect(Coins.of(silver: 1) + Coins.of(bronze: 5), const Coins(105));
  });

  test('les exercices difficiles rapportent davantage', () {
    final easy = sessionCoins({1: 100});
    final medium = sessionCoins({2: 100});
    final hard = sessionCoins({3: 100});
    expect(easy, const Coins(100));
    expect(medium.bronzeTotal, greaterThan(easy.bronzeTotal));
    expect(hard.bronzeTotal, greaterThan(medium.bronzeTotal));
    // Le bonus de série s'applique aussi aux pièces.
    expect(sessionCoins({1: 100}, multiplier: 1.5), const Coins(150));
  });

  test('une séance rapporte des pièces selon la difficulté', () {
    final state = ProgressionState.initial(const CivilDate(2026, 11, 2));
    final p = applySession(
      state,
      baseXp: 60,
      baseXpByStat: const {StatId.strength: 60},
      baseXpByDifficulty: const {1: 20, 3: 40},
      completed: false,
      now: DateTime(2026, 11, 2, 18),
      restDays: const {},
    );
    expect(p.sessionCoins, sessionCoins(const {1: 20, 3: 40}));
    expect(p.state.coins, p.coinsGained.bronzeTotal);
  });

  test('les cristaux d’une ancienne sauvegarde deviennent du bronze', () {
    final json =
        ProgressionState.initial(const CivilDate(2026, 11, 2)).toJson()
          ..remove('coins')
          ..['crystals'] = 57;
    expect(ProgressionState.fromJson(json).coins, 57);
  });
}
