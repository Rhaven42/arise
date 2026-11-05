import 'package:arise/features/muscle_analysis/domain/analysis_period.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wednesday = CivilDate(2026, 11, 4);

  test('jour, semaine du lundi au dimanche, mois et année', () {
    expect(
      PeriodRange.containing(AnalysisPeriod.day, wednesday).end,
      const CivilDate(2026, 11, 5),
    );
    final week = PeriodRange.containing(AnalysisPeriod.week, wednesday);
    expect(week.start, const CivilDate(2026, 11, 2));
    expect(week.end, const CivilDate(2026, 11, 9));
    final december = PeriodRange.containing(
      AnalysisPeriod.month,
      const CivilDate(2026, 12, 15),
    );
    expect(december.start, const CivilDate(2026, 12, 1));
    expect(december.end, const CivilDate(2027, 1, 1));
    final year = PeriodRange.containing(AnalysisPeriod.year, wednesday);
    expect(year.start, const CivilDate(2026, 1, 1));
    expect(year.contains(const CivilDate(2026, 12, 31)), isTrue);
    expect(year.contains(const CivilDate(2027, 1, 1)), isFalse);
  });

  test('passe à la période précédente ou suivante', () {
    final week = PeriodRange.containing(AnalysisPeriod.week, wednesday);
    expect(week.shift(-1).start, const CivilDate(2026, 10, 26));
    expect(week.shift(1).start, const CivilDate(2026, 11, 9));
    final month = PeriodRange.containing(AnalysisPeriod.month, wednesday);
    expect(month.shift(-1).start, const CivilDate(2026, 10, 1));
    expect(month.shift(-2).start, const CivilDate(2026, 9, 1));
  });

  test('la moyenne hebdomadaire compte les jours écoulés', () {
    final october = PeriodRange.containing(
      AnalysisPeriod.month,
      const CivilDate(2026, 10, 10),
    );
    // Mois passé : 31 jours.
    expect(october.weeksElapsed(wednesday), closeTo(31 / 7, 1e-9));
    // Mois en cours, 4e jour : au moins une semaine.
    final november = PeriodRange.containing(AnalysisPeriod.month, wednesday);
    expect(november.weeksElapsed(wednesday), 1);
    expect(
      november.weeksElapsed(const CivilDate(2026, 11, 14)),
      closeTo(14 / 7, 1e-9),
    );
  });
}
