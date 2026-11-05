import 'package:arise/features/workout_player/domain/workout_step.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_run.freezed.dart';

/// Raison de l'arrêt anticipé d'une séance.
enum StopReason {
  /// Le joueur a choisi d'arrêter.
  userStopped,

  /// Douleur, malaise ou fatigue extrême signalés.
  painOrDiscomfort,
}

/// Résultat d'un effort réalisé (ou passé) pendant la séance.
@freezed
abstract class StepResult with _$StepResult {
  const factory StepResult({
    required int stepIndex,

    /// Durée réelle de l'effort, pauses exclues.
    required int activeSeconds,
    int? reps,
    int? meters,

    /// Intensité ressentie de 1 à 10.
    int? rpe,
    @Default(false) bool skipped,
  }) = _StepResult;
}

/// État d'une séance en cours : une machine à états pure, pilotée par
/// l'horloge fournie à chaque appel (testable sans attendre).
@freezed
abstract class WorkoutRun with _$WorkoutRun {
  const factory WorkoutRun({
    required List<WorkoutStep> steps,
    required DateTime startedAt,
    required int index,
    required DateTime stepStartedAt,

    /// Temps passé en pause pendant l'étape en cours.
    @Default(Duration.zero) Duration pausedInStep,
    DateTime? pausedAt,
    @Default([]) List<StepResult> results,

    /// Effort terminé en attente de la saisie de l'intensité.
    StepResult? pendingIntensity,
    DateTime? endedAt,
    StopReason? stopReason,
  }) = _WorkoutRun;

  const WorkoutRun._();

  /// Démarre une séance sur sa première étape.
  factory WorkoutRun.start(List<WorkoutStep> steps, DateTime now) {
    return WorkoutRun(
      steps: steps,
      startedAt: now,
      index: 0,
      stepStartedAt: now,
      endedAt: steps.isEmpty ? now : null,
    );
  }

  bool get isFinished => endedAt != null;

  bool get isPaused => pausedAt != null;

  bool get isAwaitingIntensity => pendingIntensity != null;

  WorkoutStep? get currentStep =>
      isFinished || index >= steps.length ? null : steps[index];

  /// Prochain effort après l'étape en cours (pour l'annoncer).
  WorkoutStep? get nextWork {
    for (var i = index + 1; i < steps.length; i++) {
      if (steps[i].isWork) return steps[i];
    }
    return null;
  }

  int get workStepCount => steps.where((s) => s.isWork).length;

  int get completedWorkCount => results.length;

  /// Temps écoulé dans l'étape en cours, pauses exclues.
  Duration elapsed(DateTime now) {
    final reference = pausedAt ?? now;
    final value = reference.difference(stepStartedAt) - pausedInStep;
    return value.isNegative ? Duration.zero : value;
  }

  /// Temps restant d'une étape chronométrée, `null` sinon.
  Duration? remaining(DateTime now) {
    final target = currentStep?.targetSeconds;
    if (target == null) return null;
    final value = Duration(seconds: target) - elapsed(now);
    return value.isNegative ? Duration.zero : value;
  }

  /// Fait avancer les étapes chronométrées arrivées à leur terme.
  WorkoutRun tick(DateTime now) {
    if (isFinished || isPaused || isAwaitingIntensity) return this;
    final step = currentStep;
    final left = remaining(now);
    if (step == null || left == null || left > Duration.zero) return this;
    // Instant exact de la fin du compte à rebours, pour ne pas décaler
    // l'étape suivante si l'horloge a tardé.
    final endedAt = stepStartedAt
        .add(pausedInStep)
        .add(Duration(seconds: step.targetSeconds!));
    final next = step.isWork
        ? _completeWork(
            endedAt,
            StepResult(stepIndex: index, activeSeconds: step.targetSeconds!),
          )
        : _advance(endedAt);
    return next.tick(now);
  }

  /// Termine l'effort en cours (répétitions ou distance réalisées).
  WorkoutRun completeWork(DateTime now, {int? reps, int? meters}) {
    final step = currentStep;
    if (step == null || !step.isWork || isAwaitingIntensity) return this;
    final resumed = _resume(now);
    return resumed._completeWork(
      now,
      StepResult(
        stepIndex: index,
        activeSeconds: resumed.elapsed(now).inSeconds,
        reps: reps ?? step.targetReps,
        meters: meters ?? step.targetMeters,
      ),
    );
  }

  /// Enregistre l'intensité ressentie de l'effort qui vient de finir.
  WorkoutRun submitIntensity(DateTime now, int rpe) {
    final pending = pendingIntensity;
    if (pending == null) return this;
    return copyWith(
      results: [
        ...results,
        pending.copyWith(rpe: rpe),
      ],
      pendingIntensity: null,
    )._advance(now);
  }

  /// Passe l'étape en cours (repos écourté ou effort non réalisé).
  WorkoutRun skip(DateTime now) {
    final step = currentStep;
    if (step == null || isAwaitingIntensity) return this;
    if (!step.isWork) return _advance(now);
    return copyWith(
      results: [
        ...results,
        StepResult(stepIndex: index, activeSeconds: 0, skipped: true),
      ],
    )._advance(now);
  }

  WorkoutRun pause(DateTime now) =>
      isFinished || isPaused ? this : copyWith(pausedAt: now);

  WorkoutRun resume(DateTime now) => _resume(now);

  /// Arrête la séance avant la fin.
  WorkoutRun stop(DateTime now, StopReason reason) {
    if (isFinished) return this;
    final pending = pendingIntensity;
    return copyWith(
      results: [...results, ?pending],
      pendingIntensity: null,
      endedAt: now,
      stopReason: reason,
      pausedAt: null,
    );
  }

  /// Applique une intensité unique aux efforts qui n'en ont pas (formats
  /// sans saisie par série : Tabata, cardio, mobilité).
  WorkoutRun applySessionIntensity(int rpe) => copyWith(
    results: [
      for (final result in results)
        result.rpe == null && !result.skipped
            ? result.copyWith(rpe: rpe)
            : result,
    ],
  );

  /// Vrai si tous les efforts prévus ont été réalisés.
  bool get isComplete =>
      isFinished &&
      stopReason == null &&
      results.length == workStepCount &&
      results.every((r) => !r.skipped);

  WorkoutRun _resume(DateTime now) {
    final since = pausedAt;
    if (since == null) return this;
    return copyWith(
      pausedAt: null,
      pausedInStep: pausedInStep + now.difference(since),
    );
  }

  WorkoutRun _completeWork(DateTime now, StepResult result) {
    final step = steps[index];
    if (step.asksIntensity) {
      return copyWith(pendingIntensity: result, stepStartedAt: now);
    }
    return copyWith(results: [...results, result])._advance(now);
  }

  WorkoutRun _advance(DateTime now) {
    final nextIndex = index + 1;
    return copyWith(
      index: nextIndex,
      stepStartedAt: now,
      pausedInStep: Duration.zero,
      pausedAt: null,
      endedAt: nextIndex >= steps.length ? now : null,
    );
  }
}
