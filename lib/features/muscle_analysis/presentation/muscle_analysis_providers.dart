import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/muscle_analysis/domain/analysis_period.dart';
import 'package:arise/features/muscle_analysis/domain/muscle_report.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'muscle_analysis_providers.g.dart';

/// Période affichée (semaine en cours par défaut).
@riverpod
class AnalysisRange extends _$AnalysisRange {
  @override
  PeriodRange build() => PeriodRange.containing(
    AnalysisPeriod.week,
    CivilDate.ofLocal(ref.read(clockProvider)()),
  );

  CivilDate get _today => CivilDate.ofLocal(ref.read(clockProvider)());

  /// Change de vue en gardant la période qui contient le même jour.
  void select(AnalysisPeriod period) {
    final anchor = state.contains(_today) ? _today : state.start;
    state = PeriodRange.containing(period, anchor);
  }

  void previous() => state = state.shift(-1);

  /// Avance d'une période, sans dépasser celle d'aujourd'hui.
  void next() {
    if (!canGoNext) return;
    state = state.shift(1);
  }

  bool get canGoNext => !state.end.isAfter(_today);
}

/// Analyse musculaire de la période affichée.
@riverpod
Future<MuscleReport> muscleReport(Ref ref) async {
  final range = ref.watch(analysisRangeProvider);
  final sessions = await ref.watch(completedSessionsProvider.future);
  final exercises = await ref.watch(exercisesByIdProvider.future);
  final available = await ref.watch(availableExercisesProvider.future);
  final profile = await ref.watch(playerProfileProvider.future);
  final owned = profile?.equipment ?? const {};
  return buildMuscleReport(
    sessions: sessions,
    exercisesById: exercises,
    range: range,
    today: CivilDate.ofLocal(ref.read(clockProvider)()),
    suggestionPool: [
      for (final exercise in available)
        if (exercise.isAvailableWith(owned)) exercise,
    ],
  );
}
