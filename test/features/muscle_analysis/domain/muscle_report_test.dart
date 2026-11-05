import 'package:arise/core/anatomy/heat_level.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/muscle_analysis/domain/analysis_period.dart';
import 'package:arise/features/muscle_analysis/domain/muscle_report.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  const today = CivilDate(2026, 11, 8);
  final week = PeriodRange.containing(AnalysisPeriod.week, today);
  final pool = exercises.values.toList();

  group('niveaux de la heatmap', () {
    test('seuils hebdomadaires 0 / <4 / <8 / <12 / 12+', () {
      expect(heatLevelFor(0, dayView: false), HeatLevel.none);
      expect(heatLevelFor(0.5, dayView: false), HeatLevel.low);
      expect(heatLevelFor(4, dayView: false), HeatLevel.some);
      expect(heatLevelFor(8, dayView: false), HeatLevel.medium);
      expect(heatLevelFor(11.9, dayView: false), HeatLevel.medium);
      expect(heatLevelFor(12, dayView: false), HeatLevel.high);
    });

    test('seuils de la vue jour 0 / 1 / 2-3 / 4-5 / 6+', () {
      expect(heatLevelFor(1, dayView: true), HeatLevel.low);
      expect(heatLevelFor(2, dayView: true), HeatLevel.some);
      expect(heatLevelFor(3, dayView: true), HeatLevel.some);
      expect(heatLevelFor(4, dayView: true), HeatLevel.medium);
      expect(heatLevelFor(6, dayView: true), HeatLevel.high);
    });
  });

  test('ne compte que les séances de la période', () {
    final report = buildMuscleReport(
      sessions: [
        session(ProgramFormat.strength, [
          for (var i = 0; i < 5; i++) set('push_up'),
        ], start: DateTime(2026, 11, 4, 18)),
        session(ProgramFormat.strength, [
          set('push_up'),
        ], start: DateTime(2026, 10, 30, 18)),
      ],
      exercisesById: exercises,
      range: week,
      today: today,
      suggestionPool: pool,
    );
    expect(report.sessionCount, 1);
    expect(report.values[MuscleId.pectoralisMidLower], 5);
    expect(report.levels[MuscleId.pectoralisMidLower], HeatLevel.some);
    expect(report.levels[MuscleId.quadriceps], HeatLevel.none);
    expect(report.values[report.musclesByVolume.last], 5);
    expect(report.values[report.musclesByVolume.first], isNull);
  });

  test('la vue mois donne une moyenne par semaine', () {
    final month = PeriodRange.containing(
      AnalysisPeriod.month,
      const CivilDate(2026, 10, 1),
    );
    final report = buildMuscleReport(
      sessions: [
        session(ProgramFormat.strength, [
          for (var i = 0; i < 31; i++) set('push_up'),
        ], start: DateTime(2026, 10, 12, 18)),
      ],
      exercisesById: exercises,
      range: month,
      today: today,
      suggestionPool: pool,
    );
    expect(report.values[MuscleId.pectoralisMidLower], closeTo(7, 1e-9));
  });

  test('signale un déséquilibre poussée / tirage', () {
    final report = buildMuscleReport(
      sessions: [
        session(ProgramFormat.strength, [
          for (var i = 0; i < 4; i++) set('push_up'),
          set('row'),
        ]),
      ],
      exercisesById: exercises,
      range: week,
      today: today,
      suggestionPool: pool,
    );
    final pushPull = report.alerts.firstWhere(
      (a) => a.kind == ImbalanceKind.pushPull,
    );
    expect(pushPull.dominantIsFirst, isTrue);
    expect(pushPull.ratio, 4);
  });

  test('signale un déséquilibre avant / arrière', () {
    final report = buildMuscleReport(
      sessions: [
        session(ProgramFormat.strength, [
          for (var i = 0; i < 4; i++) set('push_up'),
        ]),
        session(
          ProgramFormat.cardio,
          [set('walking', seconds: 30 * 60)],
          start: DateTime(2026, 11, 5, 8),
        ),
      ],
      exercisesById: exercises,
      range: week,
      today: today,
      suggestionPool: pool,
    );
    // Avant : 4 (pectoraux) + 2 (abdominaux) + 3 (quadriceps) ; arrière : 4.
    final frontBack = report.alerts.firstWhere(
      (a) => a.kind == ImbalanceKind.frontBack,
    );
    expect(frontBack.dominantIsFirst, isTrue);
    expect(frontBack.ratio, closeTo(9 / 4, 1e-9));
    expect(
      report.alerts.where((a) => a.kind == ImbalanceKind.pushPull),
      hasLength(1),
    );
  });

  test('pas d’alerte sous le volume minimal', () {
    final report = buildMuscleReport(
      sessions: [
        session(ProgramFormat.strength, [set('push_up')]),
      ],
      exercisesById: exercises,
      range: week,
      today: today,
      suggestionPool: pool,
    );
    expect(
      report.alerts.where((a) => a.kind == ImbalanceKind.pushPull),
      isEmpty,
    );
  });

  test('suggère un exercice du référentiel qui cible le muscle en retard', () {
    final report = buildMuscleReport(
      sessions: [
        session(ProgramFormat.strength, [set('push_up')]),
      ],
      exercisesById: exercises,
      range: week,
      today: today,
      suggestionPool: [pushUp, gluteBridge],
    );
    expect(report.suggestions, isNotEmpty);
    final glutes = report.suggestions.where(
      (s) => s.muscle == MuscleId.gluteusMaximus,
    );
    expect(glutes.single.exercise.id, 'glute_bridge');
    // Le secondaire (ischio-jambiers) d'un exercice ne suffit pas.
    expect(
      report.suggestions.where((s) => s.muscle == MuscleId.hamstrings),
      isEmpty,
    );
    expect(report.suggestions.length, lessThanOrEqualTo(3));
  });

  test('aucune suggestion sans séance sur la période', () {
    final report = buildMuscleReport(
      sessions: const [],
      exercisesById: exercises,
      range: week,
      today: today,
      suggestionPool: pool,
    );
    expect(report.suggestions, isEmpty);
    expect(report.alerts, isEmpty);
  });

  test('additionne la souplesse à part', () {
    final report = buildMuscleReport(
      sessions: [
        session(ProgramFormat.mobility, [set('stretch', seconds: 600)]),
      ],
      exercisesById: exercises,
      range: week,
      today: today,
      suggestionPool: pool,
    );
    expect(report.flexibilityMinutes, 10);
    expect(report.values, isEmpty);
  });
}
