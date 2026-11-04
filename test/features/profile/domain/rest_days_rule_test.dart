import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/profile/domain/rest_days_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestDaysRule', () {
    test('suit la configuration de jeu (1 à 3 jours)', () {
      expect(RestDaysRule.minDays, gameConfig.rest.minRestDaysPerWeek);
      expect(RestDaysRule.maxDays, gameConfig.rest.maxRestDaysPerWeek);
    });

    test('refuse une sélection vide', () {
      expect(RestDaysRule.isValid({}), isFalse);
    });

    test('accepte de 1 à 3 jours', () {
      expect(RestDaysRule.isValid({1}), isTrue);
      expect(RestDaysRule.isValid({1, 4}), isTrue);
      expect(RestDaysRule.isValid({1, 4, 7}), isTrue);
    });

    test('refuse plus de 3 jours', () {
      expect(RestDaysRule.isValid({1, 2, 3, 4}), isFalse);
      expect(RestDaysRule.canAddMore({1, 2, 3}), isFalse);
      expect(RestDaysRule.canAddMore({1, 2}), isTrue);
    });

    test('refuse un jour hors de la semaine', () {
      expect(RestDaysRule.isValidWeekday(0), isFalse);
      expect(RestDaysRule.isValidWeekday(8), isFalse);
      expect(RestDaysRule.isValid({0}), isFalse);
    });
  });
}
