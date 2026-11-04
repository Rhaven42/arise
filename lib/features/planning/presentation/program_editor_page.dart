import 'dart:async';

import 'package:arise/core/design_system/widgets/arise_button.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/utils/ids.dart';
import 'package:arise/features/exercises/domain/exercise.dart';
import 'package:arise/features/exercises/domain/exercise_filter.dart';
import 'package:arise/features/exercises/presentation/exercise_providers.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/domain/program_rules.dart';
import 'package:arise/features/planning/presentation/number_stepper.dart';
import 'package:arise/features/planning/presentation/planning_labels.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Création ou modification d'un programme.
class ProgramEditorPage extends ConsumerWidget {
  const ProgramEditorPage({super.key, this.programId});

  final String? programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsProvider);
    final exercises = ref.watch(exercisesByIdProvider);
    if (programs is! AsyncData || exercises is! AsyncData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AriseColors.gold)),
      );
    }
    final id = programId;
    final existing = id == null
        ? null
        : programs.value!.where((p) => p.id == id).firstOrNull;
    return _ProgramEditor(existing: existing, exercisesById: exercises.value!);
  }
}

class _ProgramEditor extends ConsumerStatefulWidget {
  const _ProgramEditor({required this.existing, required this.exercisesById});

  final Program? existing;
  final Map<String, Exercise> exercisesById;

  @override
  ConsumerState<_ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends ConsumerState<_ProgramEditor> {
  late Program _program =
      widget.existing ??
      newProgram(id: 'program-${generateId()}', format: ProgramFormat.strength);
  late final _nameController = TextEditingController(text: _program.name);
  bool _showIssues = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(Program program) => setState(() => _program = program);

  void _updateItem(int index, ProgramItem item) {
    final items = [..._program.items];
    items[index] = item;
    _update(_program.copyWith(items: items));
  }

  void _moveItem(int index, int delta) {
    final items = [..._program.items];
    final item = items.removeAt(index);
    items.insert(index + delta, item);
    _update(_program.copyWith(items: items));
  }

  void _removeItem(int index) {
    final items = [..._program.items]..removeAt(index);
    _update(_program.copyWith(items: items));
  }

  Future<void> _addExercise() async {
    final exercise = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: _ExercisePicker(exercises: widget.exercisesById.values),
      ),
    );
    if (exercise == null) return;
    _update(
      _program.copyWith(
        items: [
          ..._program.items,
          ProgramItem.defaultsFor(exercise, _program.format),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final issues = validateProgram(_program);
    if (issues.isNotEmpty) {
      setState(() => _showIssues = true);
      return;
    }
    await ref
        .read(programRepositoryProvider)
        .save(_program.copyWith(name: _program.name.trim()));
    if (mounted) context.go(AppRoutes.programs);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.programDeleteTitle),
        content: Text(l10n.programDeleteBody(_program.name)),
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
    await ref.read(programRepositoryProvider).delete(_program.id);
    if (mounted) context.go(AppRoutes.programs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final issues = validateProgram(_program);
    final duration = estimateDuration(_program);
    final interval = _program.interval;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? l10n.programCreate : l10n.programEdit,
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
            decoration: InputDecoration(labelText: l10n.programName),
            onChanged: (value) => _update(_program.copyWith(name: value)),
          ),
          const SizedBox(height: AriseSpacing.md),
          Text(l10n.programFormatLabel, style: textTheme.titleSmall),
          const SizedBox(height: AriseSpacing.xs),
          Wrap(
            spacing: AriseSpacing.sm,
            children: [
              for (final format in ProgramFormat.values)
                ChoiceChip(
                  label: Text(l10n.format(format)),
                  selected: _program.format == format,
                  onSelected: (_) => _update(
                    changeFormat(_program, format, widget.exercisesById),
                  ),
                ),
            ],
          ),
          if (interval != null) ...[
            const SizedBox(height: AriseSpacing.md),
            _IntervalSettingsEditor(
              settings: interval,
              onChanged: (value) => _update(_program.copyWith(interval: value)),
            ),
          ],
          const SizedBox(height: AriseSpacing.md),
          Text(l10n.programExercisesTitle, style: textTheme.titleMedium),
          for (final (index, item) in _program.items.indexed)
            _ProgramItemCard(
              key: ValueKey('item-$index-${item.exerciseId}'),
              format: _program.format,
              item: item,
              exercise: widget.exercisesById[item.exerciseId],
              canMoveUp: index > 0,
              canMoveDown: index < _program.items.length - 1,
              onChanged: (value) => _updateItem(index, value),
              onMoveUp: () => _moveItem(index, -1),
              onMoveDown: () => _moveItem(index, 1),
              onRemove: () => _removeItem(index),
            ),
          const SizedBox(height: AriseSpacing.sm),
          AriseButton(
            label: l10n.programAddExercise,
            icon: Icons.add,
            variant: AriseButtonVariant.secondary,
            onPressed: () => unawaited(_addExercise()),
          ),
          const SizedBox(height: AriseSpacing.md),
          if (duration != null)
            Text(
              l10n.programEstimatedDuration(l10n.duration(duration)),
              style: textTheme.bodyMedium,
            ),
          if (_showIssues)
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(top: AriseSpacing.sm),
                child: Text(
                  l10n.programIssue(issue),
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

class _IntervalSettingsEditor extends StatelessWidget {
  const _IntervalSettingsEditor({
    required this.settings,
    required this.onChanged,
  });

  final IntervalSettings settings;
  final ValueChanged<IntervalSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    NumberStepper seconds(
      String label,
      int value,
      ({int min, int max}) range,
      int step,
      IntervalSettings Function(int) apply,
    ) {
      return NumberStepper(
        label: label,
        value: value,
        display: l10n.duration(Duration(seconds: value)),
        step: step,
        min: range.min,
        max: range.max,
        decreaseLabel: l10n.decreaseLabel(label),
        increaseLabel: l10n.increaseLabel(label),
        onChanged: (v) => onChanged(apply(v.toInt())),
      );
    }

    NumberStepper count(
      String label,
      int value,
      ({int min, int max}) range,
      IntervalSettings Function(int) apply,
    ) {
      return NumberStepper(
        label: label,
        value: value,
        display: '$value',
        step: 1,
        min: range.min,
        max: range.max,
        decreaseLabel: l10n.decreaseLabel(label),
        increaseLabel: l10n.increaseLabel(label),
        onChanged: (v) => onChanged(apply(v.toInt())),
      );
    }

    return Column(
      children: [
        seconds(
          l10n.intervalWork,
          settings.workSeconds,
          ProgramLimits.workSeconds,
          5,
          (v) => settings.copyWith(workSeconds: v),
        ),
        seconds(
          l10n.intervalRest,
          settings.restSeconds,
          ProgramLimits.intervalRestSeconds,
          5,
          (v) => settings.copyWith(restSeconds: v),
        ),
        count(
          l10n.intervalRounds,
          settings.rounds,
          ProgramLimits.rounds,
          (v) => settings.copyWith(rounds: v),
        ),
        count(
          l10n.intervalCycles,
          settings.cycles,
          ProgramLimits.cycles,
          (v) => settings.copyWith(cycles: v),
        ),
        seconds(
          l10n.intervalRestBetweenCycles,
          settings.restBetweenCyclesSeconds,
          ProgramLimits.restBetweenCyclesSeconds,
          15,
          (v) => settings.copyWith(restBetweenCyclesSeconds: v),
        ),
      ],
    );
  }
}

class _ProgramItemCard extends StatelessWidget {
  const _ProgramItemCard({
    required this.format,
    required this.item,
    required this.exercise,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    super.key,
  });

  final ProgramFormat format;
  final ProgramItem item;
  final Exercise? exercise;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<ProgramItem> onChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    NumberStepper stepper({
      required String label,
      required num value,
      required String display,
      required num step,
      required ({num min, num max}) range,
      required ProgramItem Function(num) apply,
    }) {
      return NumberStepper(
        label: label,
        value: value,
        display: display,
        step: step,
        min: range.min,
        max: range.max,
        decreaseLabel: l10n.decreaseLabel(label),
        increaseLabel: l10n.increaseLabel(label),
        onChanged: (v) => onChanged(apply(v)),
      );
    }

    final fields = <Widget>[
      if (format == ProgramFormat.strength) ...[
        stepper(
          label: l10n.programSets,
          value: item.sets ?? 1,
          display: '${item.sets ?? 1}',
          step: 1,
          range: ProgramLimits.sets,
          apply: (v) => item.copyWith(sets: v.toInt()),
        ),
        if (item.reps != null)
          stepper(
            label: l10n.programReps,
            value: item.reps!,
            display: '${item.reps}',
            step: 1,
            range: ProgramLimits.reps,
            apply: (v) => item.copyWith(reps: v.toInt()),
          )
        else
          stepper(
            label: l10n.programDuration,
            value: item.durationSeconds ?? 30,
            display: l10n.duration(
              Duration(seconds: item.durationSeconds ?? 30),
            ),
            step: 5,
            range: ProgramLimits.durationSeconds,
            apply: (v) => item.copyWith(durationSeconds: v.toInt()),
          ),
        stepper(
          label: l10n.programLoad,
          value: item.loadKg ?? 0,
          display: item.loadKg == null || item.loadKg == 0
              ? l10n.programNoLoad
              : l10n.programLoadValue(item.loadKg!.toStringAsFixed(1)),
          step: 2.5,
          range: ProgramLimits.loadKg,
          apply: (v) => item.copyWith(loadKg: v == 0 ? null : v.toDouble()),
        ),
        stepper(
          label: l10n.programRest,
          value: item.restSeconds ?? 60,
          display: l10n.duration(Duration(seconds: item.restSeconds ?? 60)),
          step: 15,
          range: ProgramLimits.restSeconds,
          apply: (v) => item.copyWith(restSeconds: v.toInt()),
        ),
      ],
      if (format == ProgramFormat.cardio)
        if (item.distanceMeters != null)
          stepper(
            label: l10n.programDistance,
            value: item.distanceMeters!,
            display: l10n.distance(item.distanceMeters!),
            step: 500,
            range: ProgramLimits.distanceMeters,
            apply: (v) => item.copyWith(distanceMeters: v.toInt()),
          )
        else
          stepper(
            label: l10n.programDuration,
            value: item.durationSeconds ?? 1200,
            display: l10n.duration(
              Duration(seconds: item.durationSeconds ?? 1200),
            ),
            step: 300,
            range: ProgramLimits.durationSeconds,
            apply: (v) => item.copyWith(durationSeconds: v.toInt()),
          ),
      if (format == ProgramFormat.mobility)
        stepper(
          label: l10n.programHold,
          value: item.holdSeconds ?? 30,
          display: l10n.duration(Duration(seconds: item.holdSeconds ?? 30)),
          step: 5,
          range: ProgramLimits.holdSeconds,
          apply: (v) => item.copyWith(holdSeconds: v.toInt()),
        ),
    ];

    return Card(
      margin: const EdgeInsets.only(top: AriseSpacing.sm),
      color: AriseColors.stone,
      child: Padding(
        padding: const EdgeInsets.all(AriseSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise?.name ?? l10n.exerciseNotFound,
                    style: textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l10n.moveUpAction,
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: canMoveUp ? onMoveUp : null,
                ),
                IconButton(
                  tooltip: l10n.moveDownAction,
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: canMoveDown ? onMoveDown : null,
                ),
                IconButton(
                  tooltip: l10n.removeAction,
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            ...fields,
          ],
        ),
      ),
    );
  }
}

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({required this.exercises});

  final Iterable<Exercise> exercises;

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = filterExercises(
      widget.exercises,
      ExerciseFilter(query: _query),
      ownedEquipment: const {},
    );
    return Padding(
      padding: const EdgeInsets.all(AriseSpacing.md),
      child: Column(
        children: [
          Text(
            l10n.programPickExercise,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AriseSpacing.sm),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.exercisesSearchHint,
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final exercise = results[index];
                return ListTile(
                  title: Text(exercise.name),
                  onTap: () => Navigator.of(context).pop(exercise),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
