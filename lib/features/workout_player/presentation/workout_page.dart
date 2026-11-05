import 'dart:async';

import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/design_system/widgets/number_stepper.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/exercises/presentation/animation/exercise_animation_player.dart';
import 'package:arise/features/workout_player/domain/workout_run.dart';
import 'package:arise/features/workout_player/domain/workout_step.dart';
import 'package:arise/features/workout_player/presentation/widgets/countdown_ring.dart';
import 'package:arise/features/workout_player/presentation/widgets/intensity_picker.dart';
import 'package:arise/features/workout_player/presentation/widgets/workout_summary_view.dart';
import 'package:arise/features/workout_player/presentation/workout_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lecteur de séance : enchaîne les efforts et les repos d'un programme.
class WorkoutPage extends ConsumerWidget {
  const WorkoutPage({required this.programId, super.key});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final provider = workoutControllerProvider(programId);
    final async = ref.watch(provider);
    final view = async.value;

    void close() => context.go(AppRoutes.programs);

    Future<void> confirmStop() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.workoutStopConfirmTitle),
          content: Text(l10n.workoutStopConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.workoutContinue),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.workoutStopConfirm),
            ),
          ],
        ),
      );
      if (confirmed ?? false) {
        await ref.read(provider.notifier).stop(StopReason.userStopped);
      }
    }

    final Widget body;
    if (async.isLoading && view == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (view == null) {
      body = _Message(text: l10n.workoutProgramMissing, onClose: close);
    } else if (view.summary case final summary?) {
      body = WorkoutSummaryView(
        session: summary,
        exercises: view.exercises,
        onClose: close,
      );
    } else if (view.run.steps.isEmpty) {
      body = _Message(text: l10n.workoutEmptyProgram, onClose: close);
    } else if (view.awaitingSessionIntensity) {
      body = ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          IntensityPicker(
            title: l10n.workoutIntensitySessionTitle,
            onSubmitted: (rpe) => unawaited(
              ref.read(provider.notifier).submitSessionIntensity(rpe),
            ),
          ),
        ],
      );
    } else if (view.run.isFinished) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = _RunningWorkout(view: view, programId: programId);
    }

    // Séance en cours (y compris la saisie finale de l'intensité) : un retour
    // arrière demande confirmation et enregistre les efforts réalisés.
    final active = view != null && view.summary == null ? view : null;
    final running = active != null;
    final controller = ref.read(provider.notifier);

    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(confirmStop());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(view?.program.name ?? l10n.workoutStart),
          automaticallyImplyLeading: false,
          leading: running
              ? IconButton(
                  tooltip: l10n.workoutStop,
                  icon: const Icon(Icons.close),
                  onPressed: () => unawaited(confirmStop()),
                )
              : null,
          actions: [
            if (active != null &&
                !active.run.isFinished &&
                !active.run.isAwaitingIntensity)
              IconButton(
                tooltip: active.run.isPaused
                    ? l10n.workoutResume
                    : l10n.workoutPause,
                icon: Icon(
                  active.run.isPaused ? Icons.play_arrow : Icons.pause,
                ),
                onPressed: active.run.isPaused
                    ? controller.resume
                    : controller.pause,
              ),
          ],
        ),
        body: SafeArea(child: body),
      ),
    );
  }
}

class _RunningWorkout extends ConsumerWidget {
  const _RunningWorkout({required this.view, required this.programId});

  final WorkoutView view;
  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(workoutControllerProvider(programId).notifier);
    final run = view.run;
    final step = run.currentStep!;
    final exercise = view.exerciseOf(step);
    final player = ref.watch(exerciseAnimationPlayerProvider);
    final isRest = !step.isWork;

    Future<void> reportPain() async {
      await controller.stop(StopReason.painOrDiscomfort);
    }

    return ListView(
      padding: const EdgeInsets.all(AriseSpacing.md),
      children: [
        Text(
          l10n.workoutProgress(
            run.completedWorkCount + (run.isAwaitingIntensity ? 1 : 0),
            run.workStepCount,
          ),
          style: textTheme.labelMedium,
        ),
        const SizedBox(height: AriseSpacing.xs),
        LinearProgressIndicator(
          value: run.workStepCount == 0
              ? 0
              : run.completedWorkCount / run.workStepCount,
          color: AriseColors.gold,
          backgroundColor: AriseColors.stoneLight,
        ),
        const SizedBox(height: AriseSpacing.md),
        if (run.isAwaitingIntensity)
          IntensityPicker(
            key: ValueKey('intensity-${run.index}'),
            title: l10n.workoutIntensityTitle,
            onSubmitted: controller.submitIntensity,
          )
        else ...[
          Semantics(
            header: true,
            child: Text(
              isRest ? l10n.workoutRest : exercise?.name ?? '',
              style: textTheme.headlineMedium?.copyWith(
                color: isRest ? AriseColors.mana : AriseColors.goldBright,
              ),
            ),
          ),
          if (_stepDetail(l10n, step) case final detail?)
            Text(detail, style: textTheme.bodyLarge),
          if (isRest && exercise != null)
            Text(l10n.workoutNext(exercise.name), style: textTheme.bodyLarge),
          const SizedBox(height: AriseSpacing.md),
          StoneFrame(
            padding: const EdgeInsets.all(AriseSpacing.sm),
            child: SizedBox(
              height: 180,
              child: exercise == null
                  ? const SizedBox.shrink()
                  : player.build(
                      // L'animation s'arrête pendant les repos et les pauses.
                      motionId: isRest || run.isPaused
                          ? null
                          : exercise.motion,
                      highlights: exercise.muscleRoles,
                      semanticLabel: exercise.name,
                    ),
            ),
          ),
          const SizedBox(height: AriseSpacing.lg),
          if (run.isPaused)
            Center(
              child: Text(l10n.workoutPaused, style: textTheme.titleLarge),
            ),
          if (run.remaining(view.now) case final remaining?)
            Center(
              child: CountdownRing(
                remaining: remaining,
                total: Duration(seconds: step.targetSeconds!),
                color: isRest ? AriseColors.mana : AriseColors.gold,
              ),
            ),
          if (step.isWork && !step.isTimed)
            _ManualEffort(
              key: ValueKey('manual-${run.index}'),
              step: step,
              onDone: (reps) => controller.completeWork(reps: reps),
            ),
          const SizedBox(height: AriseSpacing.md),
          if (step.isWork && step.isTimed)
            AriseButton(
              label: l10n.workoutDoneEffort,
              onPressed: () => controller.completeWork(),
            ),
          const SizedBox(height: AriseSpacing.sm),
          AriseButton(
            label: isRest ? l10n.workoutSkipRest : l10n.workoutSkipEffort,
            variant: AriseButtonVariant.secondary,
            onPressed: controller.skip,
          ),
        ],
        const SizedBox(height: AriseSpacing.xl),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AriseColors.danger,
            side: const BorderSide(color: AriseColors.danger, width: 1.5),
          ),
          icon: const Icon(Icons.health_and_safety),
          label: Text(l10n.workoutPainButton),
          onPressed: () => unawaited(reportPain()),
        ),
      ],
    );
  }

  String? _stepDetail(AppLocalizations l10n, WorkoutStep step) {
    final parts = <String>[
      if (step case WorkoutStep(:final setNumber?, :final setCount?))
        l10n.workoutSetOf(setNumber, setCount),
      if (step case WorkoutStep(
        :final round?,
        :final roundCount?,
        :final cycle?,
        :final cycleCount?,
      ))
        l10n.workoutRoundOf(round, roundCount, cycle, cycleCount),
      if (step.targetMeters case final meters?)
        l10n.workoutTargetMeters(meters),
      if (step.loadKg case final kg?)
        l10n.workoutLoad(kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1)),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Effort sans minuteur : répétitions (ajustables) ou distance.
class _ManualEffort extends StatefulWidget {
  const _ManualEffort({
    required this.step,
    required this.onDone,
    super.key,
  });

  final WorkoutStep step;
  final ValueChanged<int?> onDone;

  @override
  State<_ManualEffort> createState() => _ManualEffortState();
}

class _ManualEffortState extends State<_ManualEffort> {
  late int? _reps = widget.step.targetReps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reps = _reps;
    final label = l10n.workoutRepsDone;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reps != null)
          NumberStepper(
            label: label,
            value: reps,
            display: l10n.workoutTargetReps(reps),
            step: 1,
            min: 0,
            max: 500,
            decreaseLabel: l10n.decreaseLabel(label),
            increaseLabel: l10n.increaseLabel(label),
            onChanged: (value) => setState(() => _reps = value.toInt()),
          ),
        const SizedBox(height: AriseSpacing.md),
        AriseButton(
          label: widget.step.setNumber == null
              ? l10n.workoutDoneEffort
              : l10n.workoutDoneSet,
          icon: Icons.check,
          onPressed: () => widget.onDone(reps),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AriseSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: AriseSpacing.md),
            AriseButton(label: l10n.workoutSummaryClose, onPressed: onClose),
          ],
        ),
      ),
    );
  }
}
