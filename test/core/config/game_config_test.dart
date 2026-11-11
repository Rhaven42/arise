import 'package:arise/core/config/game_config.dart';
import 'package:flutter_test/flutter_test.dart';

bool _isStrictlyIncreasing(List<num> values) {
  for (var i = 1; i < values.length; i++) {
    if (values[i] <= values[i - 1]) return false;
  }
  return true;
}

Object? _valueAt(String path) {
  Object? node = gameConfig.toJson();
  for (final key in path.split('.')) {
    if (node is! Map<String, Object?> || !node.containsKey(key)) return null;
    node = node[key];
  }
  return node;
}

void main() {
  group('cohérence de la configuration de jeu', () {
    test('les rangs sont ordonnés, uniques et commencent au niveau 1', () {
      final levels = [for (final rank in gameConfig.ranks) rank.minLevel];
      expect(levels.first, 1);
      expect(_isStrictlyIncreasing(levels), isTrue);
      expect({
        for (final rank in gameConfig.ranks) rank.id,
      }, RankId.values.toSet());
    });

    test('le dernier rang est atteignable avant le niveau maximum', () {
      expect(
        gameConfig.ranks.last.minLevel,
        lessThan(gameConfig.progression.maxLevel),
      );
    });

    test('les seuils de la heatmap sont strictement croissants', () {
      final heatmap = gameConfig.heatmap;
      expect(_isStrictlyIncreasing(heatmap.weeklyThresholds), isTrue);
      expect(_isStrictlyIncreasing(heatmap.dailyThresholds), isTrue);
    });

    test('les paliers de coffres sont strictement croissants', () {
      expect(
        _isStrictlyIncreasing(gameConfig.streaks.chestMilestonesDays),
        isTrue,
      );
    });

    test('au moins 60 hauts faits, uniques, dans les 7 catégories', () {
      final definitions = gameConfig.achievements.definitions;
      expect(definitions.length, greaterThanOrEqualTo(60));
      final ids = [for (final d in definitions) d.id];
      expect(ids.toSet(), hasLength(ids.length));
      expect({
        for (final d in definitions) d.category,
      }, AchievementCategory.values.toSet());
      for (final d in definitions) {
        expect(d.threshold, greaterThan(0), reason: d.id);
      }
      final titles = [
        for (final d in definitions)
          if (d.titleId != null) d.titleId!,
      ];
      expect(titles.toSet(), hasLength(titles.length));
    });

    test('chaque aura est liée à un titre qui existe', () {
      final titles = {
        for (final d in gameConfig.achievements.definitions) ?d.titleId,
        for (final boss in [
          'rockGuardian',
          'silverStag',
          'windDancer',
          'basaltColossus',
          'crimsonComet',
          'stormLord',
        ])
          'title_$boss',
      };
      final auras = gameConfig.achievements.auras;
      expect({for (final a in auras) a.id}, hasLength(auras.length));
      for (final aura in auras) {
        expect(titles, contains(aura.titleId), reason: aura.id);
      }
    });

    test('les bornes d’intensité sont cohérentes', () {
      final intensity = gameConfig.intensity;
      expect(intensity.rpeMin, lessThan(intensity.rpeMax));
      expect(intensity.multiplierMin, lessThan(intensity.multiplierMax));
      expect(
        intensity.effectiveSetMinRpe,
        inInclusiveRange(intensity.rpeMin, intensity.rpeMax),
      );
    });

    test('chaque clé provisoire désigne une valeur existante', () {
      for (final key in gameConfig.provisionalKeys) {
        expect(_valueAt(key), isNotNull, reason: key);
      }
    });
  });
}
