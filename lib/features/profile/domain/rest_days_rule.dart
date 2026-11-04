import 'package:arise/core/config/game_config.dart';

/// Règle des jours de repos : entre 1 et 3 jours par semaine (configurable),
/// numérotés de 1 (lundi) à 7 (dimanche).
abstract final class RestDaysRule {
  static const int firstWeekday = DateTime.monday;
  static const int lastWeekday = DateTime.sunday;

  static int get minDays => gameConfig.rest.minRestDaysPerWeek;
  static int get maxDays => gameConfig.rest.maxRestDaysPerWeek;

  static bool isValidWeekday(int day) =>
      day >= firstWeekday && day <= lastWeekday;

  /// Vrai si la sélection respecte la règle.
  static bool isValid(Set<int> days) =>
      days.every(isValidWeekday) &&
      days.length >= minDays &&
      days.length <= maxDays;

  /// Vrai si un jour supplémentaire peut encore être ajouté.
  static bool canAddMore(Set<int> days) => days.length < maxDays;
}
