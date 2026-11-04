import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/exercise_filter.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/exercises/presentation/exercise_labels.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Catalogue des exercices avec recherche et filtres.
class ExerciseListPage extends ConsumerWidget {
  const ExerciseListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final exercises = ref.watch(availableExercisesProvider);
    final filter = ref.watch(exerciseFilterControllerProvider);
    final owned = ref.watch(playerProfileProvider).value?.equipment ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exercisesTitle),
        actions: [
          IconButton(
            tooltip: l10n.customExerciseCreate,
            icon: const Icon(Icons.add),
            onPressed: () => context.go(AppRoutes.customExerciseNew),
          ),
        ],
      ),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: switch (exercises) {
              AsyncData(:final value) => _ExerciseList(
                exercises: filterExercises(
                  value,
                  filter,
                  ownedEquipment: owned,
                ),
              ),
              AsyncError() => Center(child: Text(l10n.errorGeneric)),
              _ => const Center(
                child: CircularProgressIndicator(color: AriseColors.gold),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(exerciseFilterControllerProvider);
    final controller = ref.read(exerciseFilterControllerProvider.notifier);
    final muscles = [...MuscleId.values]
      ..sort((a, b) => l10n.muscle(a).compareTo(l10n.muscle(b)));
    final stats = [
      for (final stat in StatId.values)
        if (stat != StatId.willpower) stat,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AriseSpacing.md,
        AriseSpacing.sm,
        AriseSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.exercisesSearchHint,
            ),
            onChanged: controller.setQuery,
          ),
          const SizedBox(height: AriseSpacing.sm),
          Wrap(
            spacing: AriseSpacing.sm,
            runSpacing: AriseSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterChip(
                label: Text(l10n.exercisesFilterMyEquipment),
                selected: filter.onlyAvailable,
                onSelected: (value) =>
                    controller.setOnlyAvailable(value: value),
              ),
              DropdownButton<StatId?>(
                value: filter.stat,
                hint: Text(l10n.exercisesFilterAllStats),
                items: [
                  DropdownMenuItem(child: Text(l10n.exercisesFilterAllStats)),
                  for (final stat in stats)
                    DropdownMenuItem(value: stat, child: Text(l10n.stat(stat))),
                ],
                onChanged: controller.setStat,
              ),
              DropdownButton<MuscleId?>(
                value: filter.muscle,
                hint: Text(l10n.exercisesFilterAllMuscles),
                items: [
                  DropdownMenuItem(
                    child: Text(l10n.exercisesFilterAllMuscles),
                  ),
                  for (final muscle in muscles)
                    DropdownMenuItem(
                      value: muscle,
                      child: Text(l10n.muscle(muscle)),
                    ),
                ],
                onChanged: controller.setMuscle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AriseSpacing.lg),
          child: Text(l10n.exercisesEmpty, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AriseSpacing.sm),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ListTile(
          title: Text(exercise.name),
          subtitle: Text(
            '${l10n.statSplit(exercise)} · ${l10n.equipmentSummary(exercise)}',
          ),
          trailing: exercise.isCustom
              ? Chip(label: Text(l10n.exerciseCustomBadge))
              : Text(l10n.exerciseDifficulty(exercise.difficulty)),
          onTap: () => context.go(AppRoutes.exerciseDetail(exercise.id)),
        );
      },
    );
  }
}
