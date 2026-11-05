import 'dart:async';
import 'dart:ui';

import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/core/utils/ids.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/features/workout_player/data/drift_completed_session_repository.dart';
import 'package:arise/features/workout_player/domain/completed_session.dart';
import 'package:arise/features/workout_player/domain/completed_session_repository.dart';
import 'package:arise/features/workout_player/domain/session_summary.dart';
import 'package:arise/features/workout_player/domain/session_xp.dart';
import 'package:arise/features/workout_player/domain/workout_plan.dart';
import 'package:arise/features/workout_player/domain/workout_run.dart';
import 'package:arise/features/workout_player/domain/workout_step.dart';
import 'package:arise/features/workout_player/presentation/workout_cues.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workout_providers.freezed.dart';
part 'workout_providers.g.dart';

@Riverpod(keepAlive: true)
CompletedSessionRepository completedSessionRepository(Ref ref) =>
    DriftCompletedSessionRepository(ref.watch(appDatabaseProvider));

/// Historique des séances, de la plus récente à la plus ancienne.
@Riverpod(keepAlive: true)
Stream<List<CompletedSession>> completedSessions(Ref ref) =>
    ref.watch(completedSessionRepositoryProvider).watchAll();

/// Période de rafraîchissement du minuteur.
const workoutTickInterval = Duration(milliseconds: 250);

/// État affiché par le lecteur de séance.
@freezed
abstract class WorkoutView with _$WorkoutView {
  const factory WorkoutView({
    required Program program,
    required Map<String, Exercise> exercises,
    required WorkoutRun run,
    required DateTime now,

    /// Fin de séance : intensité unique à saisir pour les efforts sans
    /// intensité par série (Tabata, cardio, mobilité).
    @Default(false) bool awaitingSessionIntensity,

    /// Séance enregistrée, affichée dans le récapitulatif.
    CompletedSession? summary,
  }) = _WorkoutView;

  const WorkoutView._();

  Exercise? exerciseOf(WorkoutStep? step) =>
      step?.exerciseId == null ? null : exercises[step!.exerciseId];
}

/// Pilote une séance : minuteur, signaux, saisies et enregistrement.
@riverpod
class WorkoutController extends _$WorkoutController {
  Timer? _timer;
  WorkoutCues? _cues;
  bool _sounds = true;
  bool _voice = false;
  int? _lastCountdownSecond;

  @override
  Future<WorkoutView?> build(String programId) async {
    final programs = await ref.read(programsProvider.future);
    final program = programs.where((p) => p.id == programId).firstOrNull;
    if (program == null) return null;

    final exercises = await ref.read(exercisesByIdProvider.future);
    final profile = await ref.read(playerProfileProvider.future);
    _sounds = profile?.workoutSounds ?? true;
    _voice = profile?.workoutVoice ?? false;
    _cues = ref.read(workoutCuesProvider);

    final now = _now();
    final run = WorkoutRun.start(buildWorkoutSteps(program), now);
    _timer = Timer.periodic(workoutTickInterval, (_) => _onTick());
    ref.onDispose(() {
      _timer?.cancel();
      unawaited(_cues?.keepScreenOn(enabled: false));
    });
    unawaited(_cues?.keepScreenOn(enabled: true));

    final view = WorkoutView(
      program: program,
      exercises: exercises,
      run: run,
      now: now,
    );
    _announce(view, run.currentStep);
    return view;
  }

  DateTime _now() => ref.read(clockProvider)();

  WorkoutView? get _view => state.value;

  void _onTick() {
    final view = _view;
    if (view == null || view.run.isFinished) return;
    final now = _now();
    final run = view.run.tick(now);
    _countdownCue(run, now);
    _update(view, run, now);
  }

  void completeWork({int? reps, int? meters}) =>
      _apply((run, now) => run.completeWork(now, reps: reps, meters: meters));

  void submitIntensity(int rpe) =>
      _apply((run, now) => run.submitIntensity(now, rpe));

  void skip() => _apply((run, now) => run.skip(now));

  void pause() => _apply((run, now) => run.pause(now));

  void resume() => _apply((run, now) => run.resume(now));

  /// Arrête la séance ; les efforts réalisés sont enregistrés.
  Future<void> stop(StopReason reason) async {
    final view = _view;
    if (view == null || view.summary != null) return;
    final now = _now();
    final run = view.run.stop(now, reason);
    _timer?.cancel();
    await _finalize(view.copyWith(run: run, now: now));
  }

  /// Intensité unique de fin de séance.
  Future<void> submitSessionIntensity(int rpe) async {
    final view = _view;
    if (view == null || !view.awaitingSessionIntensity) return;
    await _finalize(
      view.copyWith(
        run: view.run.applySessionIntensity(rpe),
        awaitingSessionIntensity: false,
      ),
    );
  }

  void _apply(WorkoutRun Function(WorkoutRun run, DateTime now) change) {
    final view = _view;
    if (view == null || view.run.isFinished) return;
    final now = _now();
    _update(view, change(view.run, now), now);
  }

  void _update(WorkoutView view, WorkoutRun run, DateTime now) {
    final stepChanged = run.index != view.run.index;
    var next = view.copyWith(run: run, now: now);
    if (stepChanged) {
      _lastCountdownSecond = null;
      if (run.isFinished) {
        _timer?.cancel();
        final needsIntensity = run.results.any(
          (r) => r.rpe == null && !r.skipped,
        );
        next = next.copyWith(awaitingSessionIntensity: needsIntensity);
        state = AsyncData(next);
        if (!needsIntensity) unawaited(_finalize(next));
        return;
      }
      _announce(next, run.currentStep);
    }
    state = AsyncData(next);
  }

  Future<void> _finalize(WorkoutView view) async {
    final repository = ref.read(completedSessionRepositoryProvider);
    final history = await repository.readAll();
    final now = _now();
    final summary = summarizeRun(
      id: generateId(now),
      program: view.program,
      run: view.run,
      exercisesById: view.exercises,
      priorActiveSecondsToday: activeSecondsOnDay(history, view.run.startedAt),
      now: now,
    );
    await repository.save(summary);
    if (!ref.mounted) return;
    state = AsyncData(view.copyWith(summary: summary, now: now));
    unawaited(_cues?.keepScreenOn(enabled: false));
    if (_sounds) unawaited(_cues?.play(CueSound.finish));
    if (_voice) unawaited(_cues?.speak(_l10n.workoutVoiceFinish));
  }

  /// Bip à chacune des trois dernières secondes d'un compte à rebours.
  void _countdownCue(WorkoutRun run, DateTime now) {
    final left = run.remaining(now);
    if (left == null || run.isPaused || run.isAwaitingIntensity) return;
    final second = (left.inMilliseconds / 1000).ceil();
    if (second >= 1 && second <= 3 && second != _lastCountdownSecond) {
      _lastCountdownSecond = second;
      if (_sounds) unawaited(_cues?.play(CueSound.countdown));
    }
  }

  void _announce(WorkoutView view, WorkoutStep? step) {
    if (step == null) return;
    if (_sounds) {
      unawaited(_cues?.play(step.isWork ? CueSound.start : CueSound.rest));
    }
    if (!_voice) return;
    final l10n = _l10n;
    final seconds = step.targetSeconds;
    if (!step.isWork) {
      unawaited(_cues?.speak(l10n.workoutVoiceRest(seconds ?? 0)));
      return;
    }
    final name = view.exerciseOf(step)?.name ?? '';
    final detail = switch (step) {
      WorkoutStep(targetReps: final reps?) => l10n.workoutTargetReps(reps),
      WorkoutStep(targetMeters: final meters?) => l10n.workoutTargetMeters(
        meters,
      ),
      WorkoutStep(targetSeconds: final s?) => l10n.workoutVoiceSeconds(s),
      _ => '',
    };
    unawaited(_cues?.speak(l10n.workoutVoiceWork(name, detail)));
  }

  AppLocalizations get _l10n => lookupAppLocalizations(const Locale('fr'));
}
