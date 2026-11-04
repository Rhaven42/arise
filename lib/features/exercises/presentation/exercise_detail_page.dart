import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/anatomy/muscle_legend.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/presentation/animation/exercise_animation_player.dart';
import 'package:arise/features/exercises/presentation/exercise_labels.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Fiche d'un exercice : animation, muscles, consignes et erreurs.
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final exercises = ref.watch(exercisesByIdProvider);
    return switch (exercises) {
      AsyncData(:final value) => switch (value[exerciseId]) {
        final exercise? => _ExerciseDetail(exercise: exercise),
        null => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(l10n.exerciseNotFound)),
        ),
      },
      AsyncError() => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AriseColors.gold),
        ),
      ),
    };
  }
}

class _ExerciseDetail extends ConsumerWidget {
  const _ExerciseDetail({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final player = ref.watch(exerciseAnimationPlayerProvider);
    final roles = exercise.muscleRoles;

    String muscleLine(MuscleId muscle) => exercise.weakMuscles.contains(muscle)
        ? l10n.muscleWeak(l10n.muscle(muscle))
        : l10n.muscle(muscle);

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          if (exercise.isCustom)
            IconButton(
              tooltip: l10n.customExerciseEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.go(AppRoutes.customExerciseEdit(exercise.id)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          if (exercise.motion != null) ...[
            StoneFrame(
              padding: const EdgeInsets.all(AriseSpacing.sm),
              child: SizedBox(
                height: 220,
                child: player.build(
                  motionId: exercise.motion,
                  highlights: roles,
                  semanticLabel: l10n.exerciseAnimationSemantics(exercise.name),
                ),
              ),
            ),
            const SizedBox(height: AriseSpacing.md),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final view in BodyView.values)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.bodyViewLabel(view.name),
                        style: textTheme.labelMedium,
                      ),
                      const SizedBox(height: AriseSpacing.xs),
                      SizedBox(
                        height: 260,
                        child: BodyMap(
                          view: view,
                          highlights: roles,
                          semanticLabel: l10n.musclesSemantics(exercise, view),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AriseSpacing.sm),
          const MuscleLegend(),
          const SizedBox(height: AriseSpacing.lg),
          _Section(
            title: l10n.musclePrimaryLegend,
            lines: [for (final m in exercise.primaryMuscles) muscleLine(m)],
          ),
          if (exercise.secondaryMuscles.isNotEmpty)
            _Section(
              title: l10n.muscleSecondaryLegend,
              lines: [for (final m in exercise.secondaryMuscles) muscleLine(m)],
            ),
          _Section(
            title: l10n.exerciseInfoTitle,
            lines: [
              l10n.statSplit(exercise),
              l10n.exerciseTypeLabel(exercise.type),
              l10n.equipmentSummary(exercise),
              if (!exercise.isCustom)
                l10n.exerciseDifficulty(exercise.difficulty),
            ],
          ),
          if (exercise.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AriseSpacing.lg),
              child: Text(exercise.description, style: textTheme.bodyLarge),
            ),
          if (exercise.instructions.isNotEmpty)
            _Section(
              title: l10n.exerciseInstructionsTitle,
              lines: exercise.instructions,
              numbered: true,
            ),
          if (exercise.mistakes.isNotEmpty)
            _Section(
              title: l10n.exerciseMistakesTitle,
              lines: exercise.mistakes,
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.lines,
    this.numbered = false,
  });

  final String title;
  final List<String> lines;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AriseSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(color: AriseColors.gold),
            ),
          ),
          const SizedBox(height: AriseSpacing.xs),
          for (final (index, line) in lines.indexed)
            Padding(
              padding: const EdgeInsets.only(top: AriseSpacing.xs),
              child: Text(
                numbered ? '${index + 1}. $line' : '• $line',
                style: textTheme.bodyLarge,
              ),
            ),
        ],
      ),
    );
  }
}
