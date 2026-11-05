import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/progression/domain/level_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le premier palier est celui de l’Éveil, puis 100 × n^1,5', () {
    expect(xpToNextLevel(0), gameConfig.progression.tutorialXp);
    expect(xpToNextLevel(1), 100);
    expect(xpToNextLevel(2), 283);
    expect(xpToNextLevel(4), 800);
    expect(xpToNextLevel(9), 2700);
  });

  test('le rang suit le niveau', () {
    expect(rankOf(0), RankId.e);
    expect(rankOf(9), RankId.e);
    expect(rankOf(10), RankId.d);
    expect(rankOf(34), RankId.c);
    expect(rankOf(35), RankId.b);
    expect(rankOf(90), RankId.monarch);
  });

  test('dernier niveau de chaque rang', () {
    expect(lastLevelOfRank(RankId.e), 9);
    expect(lastLevelOfRank(RankId.d), 19);
    expect(lastLevelOfRank(RankId.c), 34);
    expect(lastLevelOfRank(RankId.s), 89);
    expect(lastLevelOfRank(RankId.monarch), isNull);
  });

  test('l’XP se bloque au dernier niveau d’un rang sans boss vaincu', () {
    expect(rankLockedAt(9, const {}), isTrue);
    expect(rankLockedAt(9, const {RankId.e}), isFalse);
    expect(rankLockedAt(8, const {}), isFalse);
    expect(rankLockedAt(19, const {RankId.e}), isTrue);
    expect(rankLockedAt(95, const {}), isFalse);
  });
}
