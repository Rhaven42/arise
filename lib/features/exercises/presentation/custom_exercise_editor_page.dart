import 'dart:async';

import 'package:arise/core/anatomy/body_map.dart';
import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/anatomy/muscle_legend.dart';
import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/utils/ids.dart';
import 'package:arise/features/exercises/domain/custom_exercise_draft.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/exercises/presentation/exercise_labels.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Création ou modification d'un exercice personnalisé.
///
/// Les muscles se choisissent en touchant la silhouette : une fois pour
/// « principal », deux fois pour « secondaire », trois fois pour retirer.
class CustomExerciseEditorPage extends ConsumerWidget {
  const CustomExerciseEditorPage({super.key, this.exerciseId});

  final String? exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = exerciseId;
    if (id == null) return const _Editor(existing: null);
    final custom = ref.watch(customExercisesProvider);
    return switch (custom) {
      AsyncData(:final value) => _Editor(
        existing: value.where((e) => e.id == id).firstOrNull,
      ),
      _ => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AriseColors.gold)),
      ),
    };
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.existing});

  final Exercise? existing;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late CustomExerciseDraft _draft = switch (widget.existing) {
    final exercise? => CustomExerciseDraft.fromExercise(exercise),
    null => const CustomExerciseDraft(),
  };
  late final _nameController = TextEditingController(text: _draft.name);
  bool _showIssues = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _issueText(AppLocalizations l10n, CustomExerciseIssue issue) =>
      switch (issue) {
        CustomExerciseIssue.nameTooShort => l10n.customExerciseNameTooShort(
          CustomExerciseDraft.nameMinLength,
        ),
        CustomExerciseIssue.nameTooLong => l10n.customExerciseNameTooLong(
          CustomExerciseDraft.nameMaxLength,
        ),
        CustomExerciseIssue.noPrimaryMuscle =>
          l10n.customExerciseNoPrimaryMuscle,
      };

  Future<void> _save() async {
    if (!_draft.isValid) {
      setState(() => _showIssues = true);
      return;
    }
    final exercise = _draft.toExercise(
      id: widget.existing?.id ?? 'custom-${generateId()}',
    );
    await ref.read(customExerciseRepositoryProvider).save(exercise);
    if (mounted) context.go(AppRoutes.exerciseDetail(exercise.id));
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.customExerciseDeleteTitle),
        content: Text(l10n.customExerciseDeleteBody(existing.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(customExerciseRepositoryProvider).delete(existing.id);
    if (mounted) context.go(AppRoutes.exercises);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final selected = [
      for (final muscle in MuscleId.values)
        if (_draft.muscles[muscle] case final role?) (muscle, role),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? l10n.customExerciseCreate
              : l10n.customExerciseEdit,
        ),
        actions: [
          if (widget.existing != null)
            IconButton(
              tooltip: l10n.deleteAction,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => unawaited(_delete()),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AriseSpacing.md),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.customExerciseName),
            onChanged: (value) =>
                setState(() => _draft = _draft.copyWith(name: value)),
          ),
          const SizedBox(height: AriseSpacing.md),
          Text(l10n.customExerciseTypeLabel, style: textTheme.titleSmall),
          const SizedBox(height: AriseSpacing.xs),
          SegmentedButton<ExerciseType>(
            segments: [
              for (final type in ExerciseType.values)
                ButtonSegment(
                  value: type,
                  label: Text(l10n.exerciseTypeLabel(type)),
                ),
            ],
            selected: {_draft.type},
            onSelectionChanged: (value) =>
                setState(() => _draft = _draft.copyWith(type: value.first)),
          ),
          const SizedBox(height: AriseSpacing.md),
          DropdownButtonFormField<StatId>(
            initialValue: _draft.stat,
            decoration: InputDecoration(labelText: l10n.customExerciseStat),
            items: [
              for (final stat in StatId.values)
                if (stat != StatId.willpower)
                  DropdownMenuItem(value: stat, child: Text(l10n.stat(stat))),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _draft = _draft.copyWith(stat: value));
              }
            },
          ),
          const SizedBox(height: AriseSpacing.lg),
          Text(l10n.customExerciseMusclesHint, style: textTheme.bodyMedium),
          const SizedBox(height: AriseSpacing.sm),
          Row(
            children: [
              for (final view in BodyView.values)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.bodyViewLabel(view.name),
                        style: textTheme.labelMedium,
                      ),
                      SizedBox(
                        height: 320,
                        child: BodyMap(
                          view: view,
                          highlights: _draft.muscles,
                          semanticLabel: l10n.customExerciseBodySemantics(
                            l10n.bodyViewLabel(view.name),
                          ),
                          onMuscleTap: (muscle) => setState(
                            () => _draft = _draft.cycleMuscle(muscle),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AriseSpacing.sm),
          const MuscleLegend(),
          const SizedBox(height: AriseSpacing.md),
          // Liste accessible des muscles choisis, modifiable sans la
          // silhouette (lecteurs d'écran, gros caractères).
          for (final (muscle, role) in selected)
            ListTile(
              dense: true,
              title: Text(l10n.muscle(muscle)),
              subtitle: Text(
                role == MuscleRole.primary
                    ? l10n.musclePrimaryLegend
                    : l10n.muscleSecondaryLegend,
              ),
              trailing: IconButton(
                tooltip: l10n.customExerciseChangeRole(l10n.muscle(muscle)),
                icon: const Icon(Icons.sync),
                onPressed: () =>
                    setState(() => _draft = _draft.cycleMuscle(muscle)),
              ),
            ),
          _MusclePicker(
            onPicked: (muscle) =>
                setState(() => _draft = _draft.cycleMuscle(muscle)),
            exclude: _draft.muscles.keys.toSet(),
          ),
          if (_showIssues)
            for (final issue in _draft.issues)
              Padding(
                padding: const EdgeInsets.only(top: AriseSpacing.sm),
                child: Text(
                  _issueText(l10n, issue),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AriseColors.danger,
                  ),
                ),
              ),
          const SizedBox(height: AriseSpacing.lg),
          AriseButton(
            label: l10n.saveAction,
            icon: Icons.check,
            onPressed: () => unawaited(_save()),
          ),
        ],
      ),
    );
  }
}

/// Ajout d'un muscle par liste déroulante (alternative à la silhouette).
class _MusclePicker extends StatelessWidget {
  const _MusclePicker({required this.onPicked, required this.exclude});

  final ValueChanged<MuscleId> onPicked;
  final Set<MuscleId> exclude;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muscles = [
      for (final muscle in MuscleId.values)
        if (!exclude.contains(muscle)) muscle,
    ]..sort((a, b) => l10n.muscle(a).compareTo(l10n.muscle(b)));
    return DropdownButton<MuscleId>(
      isExpanded: true,
      hint: Text(l10n.customExerciseAddMuscle),
      items: [
        for (final muscle in muscles)
          DropdownMenuItem(value: muscle, child: Text(l10n.muscle(muscle))),
      ],
      onChanged: (muscle) {
        if (muscle != null) onPicked(muscle);
      },
    );
  }
}
