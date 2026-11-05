import 'package:arise/core/anatomy/heat_level.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/muscle_analysis/domain/analysis_period.dart';
import 'package:arise/features/muscle_analysis/domain/muscle_volume.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';

/// Type de déséquilibre signalé.
enum ImbalanceKind { frontBack, pushPull }

/// Déséquilibre entre deux groupes : [dominant] reçoit [ratio] fois plus de
/// volume que l'autre.
class ImbalanceAlert {
  const ImbalanceAlert({
    required this.kind,
    required this.dominantIsFirst,
    required this.ratio,
  });

  final ImbalanceKind kind;

  /// Vrai si le groupe dominant est l'avant (ou la poussée).
  final bool dominantIsFirst;
  final double ratio;
}

/// Exercice proposé pour un muscle en retard.
class MuscleSuggestion {
  const MuscleSuggestion({required this.muscle, required this.exercise});

  final MuscleId muscle;
  final Exercise exercise;
}

/// Analyse musculaire d'une période.
class MuscleReport {
  const MuscleReport({
    required this.range,
    required this.values,
    required this.levels,
    required this.flexibilityMinutes,
    required this.alerts,
    required this.suggestions,
    required this.sessionCount,
  });

  final PeriodRange range;

  /// Séries effectives par muscle : moyenne par semaine (semaine, mois,
  /// année) ou total du jour (vue jour).
  final Map<MuscleId, double> values;
  final Map<MuscleId, HeatLevel> levels;

  /// Minutes de mobilité et d'étirements sur la période.
  final int flexibilityMinutes;
  final List<ImbalanceAlert> alerts;
  final List<MuscleSuggestion> suggestions;
  final int sessionCount;

  /// Muscles du moins au plus travaillé.
  List<MuscleId> get musclesByVolume =>
      [...MuscleId.values]
        ..sort((a, b) => (values[a] ?? 0).compareTo(values[b] ?? 0));
}

/// Niveau d'un muscle selon les seuils de la vue (ANATOMY.md §4).
HeatLevel heatLevelFor(
  double value, {
  required bool dayView,
  HeatmapConfig? config,
}) {
  final c = config ?? gameConfig.heatmap;
  final thresholds = dayView ? c.dailyThresholds : c.weeklyThresholds;
  if (value <= 0) return HeatLevel.none;
  if (value < thresholds[0]) return HeatLevel.low;
  if (value < thresholds[1]) return HeatLevel.some;
  if (value < thresholds[2]) return HeatLevel.medium;
  return HeatLevel.high;
}

/// Construit l'analyse de la période [range] à partir des séances.
///
/// [suggestionPool] : exercices que le joueur peut faire (référentiel validé
/// et équipement disponible) ; seuls ceux dont le muscle en retard est un
/// muscle principal sont proposés.
MuscleReport buildMuscleReport({
  required List<CompletedSession> sessions,
  required Map<String, Exercise> exercisesById,
  required PeriodRange range,
  required CivilDate today,
  required List<Exercise> suggestionPool,
  GameConfig config = gameConfig,
}) {
  final totals = <MuscleId, double>{};
  var flexibilitySeconds = 0;
  var push = 0.0;
  var pull = 0.0;
  var count = 0;

  for (final session in sessions) {
    if (!range.contains(CivilDate.ofLocal(session.startedAt))) continue;
    count++;
    final volume = sessionVolume(session, exercisesById, config: config);
    for (final entry in volume.points.entries) {
      totals.update(
        entry.key,
        (v) => v + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    flexibilitySeconds += volume.flexibilitySeconds;
    push += volume.pushSets;
    pull += volume.pullSets;
  }

  final dayView = range.period == AnalysisPeriod.day;
  final divisor = dayView ? 1.0 : range.weeksElapsed(today);
  final values = {
    for (final entry in totals.entries) entry.key: entry.value / divisor,
  };
  final levels = {
    for (final muscle in MuscleId.values)
      muscle: heatLevelFor(values[muscle] ?? 0, dayView: dayView),
  };

  double sumView(BodyView view) => totals.entries
      .where((e) => e.key.view == view)
      .fold(0, (sum, e) => sum + e.value);

  final alerts = <ImbalanceAlert>[
    ?_imbalance(
      ImbalanceKind.frontBack,
      sumView(BodyView.front),
      sumView(BodyView.back),
      config.balance,
    ),
    ?_imbalance(ImbalanceKind.pushPull, push, pull, config.balance),
  ];

  return MuscleReport(
    range: range,
    values: values,
    levels: levels,
    flexibilityMinutes: flexibilitySeconds ~/ 60,
    alerts: alerts,
    suggestions: count == 0
        ? const []
        : _suggestions(levels, values, suggestionPool, config.balance),
    sessionCount: count,
  );
}

ImbalanceAlert? _imbalance(
  ImbalanceKind kind,
  double first,
  double second,
  BalanceConfig config,
) {
  if (first + second < config.minVolumeForAlert) return null;
  final high = first >= second ? first : second;
  final low = first >= second ? second : first;
  final ratio = low == 0 ? double.infinity : high / low;
  if (ratio <= config.imbalanceRatio) return null;
  return ImbalanceAlert(
    kind: kind,
    dominantIsFirst: first >= second,
    ratio: ratio,
  );
}

/// Muscles en retard (pas du tout ou pas assez travaillés), du plus faible
/// au moins faible, chacun avec l'exercice le plus simple qui le cible.
List<MuscleSuggestion> _suggestions(
  Map<MuscleId, HeatLevel> levels,
  Map<MuscleId, double> values,
  List<Exercise> pool,
  BalanceConfig config,
) {
  final lagging = [
    for (final muscle in MuscleId.values)
      if (levels[muscle] == HeatLevel.none || levels[muscle] == HeatLevel.low)
        muscle,
  ]..sort((a, b) => (values[a] ?? 0).compareTo(values[b] ?? 0));

  final result = <MuscleSuggestion>[];
  final used = <String>{};
  for (final muscle in lagging) {
    final candidates =
        pool
            .where(
              (e) =>
                  e.isPublishable &&
                  !e.isCustom &&
                  e.primaryMuscles.contains(muscle) &&
                  !used.contains(e.id),
            )
            .toList()
          ..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    if (candidates.isEmpty) continue;
    used.add(candidates.first.id);
    result.add(MuscleSuggestion(muscle: muscle, exercise: candidates.first));
    if (result.length >= config.maxSuggestions) break;
  }
  return result;
}
