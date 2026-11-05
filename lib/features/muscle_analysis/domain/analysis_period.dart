import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Période affichée par l'analyse musculaire.
enum AnalysisPeriod { day, week, month, year }

/// Intervalle de jours [start, end[ d'une période.
@immutable
class PeriodRange {
  const PeriodRange({
    required this.period,
    required this.start,
    required this.end,
  });

  /// Période contenant [day] : jour, semaine (lundi → dimanche), mois civil
  /// ou année civile.
  factory PeriodRange.containing(AnalysisPeriod period, CivilDate day) {
    return switch (period) {
      AnalysisPeriod.day => PeriodRange(
        period: period,
        start: day,
        end: day.next,
      ),
      AnalysisPeriod.week => () {
        final monday = day.addDays(1 - day.weekday);
        return PeriodRange(period: period, start: monday, end: monday.addDays(7));
      }(),
      AnalysisPeriod.month => PeriodRange(
        period: period,
        start: CivilDate(day.year, day.month, 1),
        end: day.month == 12
            ? CivilDate(day.year + 1, 1, 1)
            : CivilDate(day.year, day.month + 1, 1),
      ),
      AnalysisPeriod.year => PeriodRange(
        period: period,
        start: CivilDate(day.year, 1, 1),
        end: CivilDate(day.year + 1, 1, 1),
      ),
    };
  }

  final AnalysisPeriod period;
  final CivilDate start;

  /// Premier jour après la période.
  final CivilDate end;

  bool contains(CivilDate day) => !day.isBefore(start) && day.isBefore(end);

  /// Période précédente ou suivante ([offset] = −1 ou +1).
  PeriodRange shift(int offset) {
    final reference = offset < 0 ? start.previous : end;
    var range = PeriodRange.containing(period, reference);
    for (var i = 1; i < offset.abs(); i++) {
      range = range.shift(offset.sign);
    }
    return range;
  }

  /// Nombre de semaines servant à calculer la moyenne hebdomadaire : la
  /// période entière si elle est passée, sinon les jours déjà écoulés (au
  /// moins une semaine, pour ne pas gonfler un début de mois).
  double weeksElapsed(CivilDate today) {
    final last = today.isBefore(end) ? today.next : end;
    final days = last.daysSince(start);
    final weeks = days / 7;
    return weeks < 1 ? 1 : weeks;
  }

  @override
  bool operator ==(Object other) =>
      other is PeriodRange &&
      other.period == period &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(period, start, end);
}
