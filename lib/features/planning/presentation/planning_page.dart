import 'dart:async';

import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/design_system/widgets/stone_frame.dart';
import 'package:arise/core/router/app_routes.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/utils/ids.dart';
import 'package:arise/core/utils/weekdays.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/domain/schedule.dart';
import 'package:arise/features/planning/presentation/planning_labels.dart';
import 'package:arise/features/planning/presentation/planning_providers.dart';
import 'package:arise/features/profile/presentation/profile_providers.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Planning hebdomadaire : séances glissables d'un jour à l'autre.
class PlanningPage extends ConsumerWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final weekStart = ref.watch(displayedWeekProvider);
    final week = ref.read(displayedWeekProvider.notifier);
    final sessions = ref.watch(plannedSessionsProvider).value ?? const [];
    final programs = ref.watch(programsProvider).value ?? const [];
    final restDays = ref.watch(playerProfileProvider).value?.restDays ?? {};
    final programsById = {for (final p in programs) p.id: p};
    final occurrences = occurrencesForWeek(sessions, weekStart);
    final range = DateFormat.MMMd('fr');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.planningTitle),
        actions: [
          IconButton(
            tooltip: l10n.programsTitle,
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.go(AppRoutes.programs),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AriseSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.planningPreviousWeek,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: week.previous,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: week.today,
                    child: Text(
                      l10n.planningWeekRange(
                        range.format(weekStart),
                        range.format(dayOfWeek(weekStart, DateTime.sunday)),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.planningNextWeek,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: week.next,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AriseSpacing.md),
            child: Text(
              l10n.planningDragHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AriseSpacing.md),
              children: [
                for (
                  var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++
                )
                  _DayColumn(
                    weekday: weekday,
                    date: dayOfWeek(weekStart, weekday),
                    isRestDay: restDays.contains(weekday),
                    occurrences: [
                      for (final o in occurrences)
                        if (o.start.weekday == weekday) o,
                    ],
                    programsById: programsById,
                    restDays: restDays,
                    weekStart: weekStart,
                    programs: programs,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends ConsumerWidget {
  const _DayColumn({
    required this.weekday,
    required this.date,
    required this.isRestDay,
    required this.occurrences,
    required this.programsById,
    required this.restDays,
    required this.weekStart,
    required this.programs,
  });

  final int weekday;
  final DateTime date;
  final bool isRestDay;
  final List<SessionOccurrence> occurrences;
  final Map<String, Program> programsById;
  final Set<int> restDays;
  final DateTime weekStart;
  final List<Program> programs;

  Future<void> _drop(
    BuildContext context,
    WidgetRef ref,
    PlannedSession session,
  ) async {
    final l10n = AppLocalizations.of(context);
    final program = programsById[session.programId];
    if (program == null || session.weekday == weekday && session.recurring) {
      return;
    }
    if (!canPlanOn(program: program, weekday: weekday, restDays: restDays)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.planningRestDayRefused)));
      return;
    }
    await ref
        .read(planningRepositoryProvider)
        .save(moveSession(session, weekday: weekday, weekStart: weekStart));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final dayName = l10n.weekdayLong(weekdayKey(weekday));
    final dayLabel = '$dayName ${DateFormat.MMMd('fr').format(date)}';

    return DragTarget<PlannedSession>(
      onAcceptWithDetails: (details) =>
          unawaited(_drop(context, ref, details.data)),
      builder: (context, candidates, _) => Padding(
        padding: const EdgeInsets.only(bottom: AriseSpacing.sm),
        child: StoneFrame(
          material: candidates.isEmpty
              ? FrameMaterial.stone
              : FrameMaterial.wood,
          padding: const EdgeInsets.all(AriseSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(dayLabel, style: textTheme.titleSmall),
                    ),
                  ),
                  if (isRestDay)
                    Chip(
                      avatar: const Icon(Icons.bedtime_outlined, size: 18),
                      label: Text(l10n.planningRestDay),
                    ),
                  IconButton(
                    tooltip: l10n.planningAddSession(
                      l10n.weekdayLong(weekdayKey(weekday)),
                    ),
                    icon: const Icon(Icons.add),
                    onPressed: programs.isEmpty
                        ? () => context.go(AppRoutes.programNew)
                        : () => unawaited(
                            showSessionDialog(
                              context: context,
                              ref: ref,
                              programs: programs,
                              weekday: weekday,
                              date: date,
                              restDays: restDays,
                            ),
                          ),
                  ),
                ],
              ),
              if (occurrences.isEmpty)
                Text(
                  isRestDay ? l10n.planningRestDayHint : l10n.planningNoSession,
                  style: textTheme.bodySmall,
                ),
              for (final occurrence in occurrences)
                _SessionChip(
                  session: occurrence.session,
                  program: programsById[occurrence.session.programId],
                  onTap: () => unawaited(
                    showSessionDialog(
                      context: context,
                      ref: ref,
                      programs: programs,
                      weekday: weekday,
                      date: date,
                      restDays: restDays,
                      existing: occurrence.session,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  const _SessionChip({
    required this.session,
    required this.program,
    required this.onTap,
  });

  final PlannedSession session;
  final Program? program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tile = Material(
      color: AriseColors.stoneLight,
      borderRadius: BorderRadius.circular(AriseSpacing.radius),
      child: ListTile(
        dense: true,
        leading: Text(
          l10n.timeOfDay(session.minuteOfDay),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        title: Text(program?.name ?? l10n.exerciseNotFound),
        subtitle: Text(
          [
            if (program != null) l10n.format(program!.format),
            if (session.recurring)
              l10n.planningRecurring
            else
              l10n.planningOneOff,
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              session.reminder
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              semanticLabel: session.reminder
                  ? l10n.planningReminderOn
                  : l10n.planningReminderOff,
            ),
            if (program case final program?)
              IconButton(
                tooltip: l10n.workoutStartTooltip(program.name),
                icon: const Icon(Icons.play_circle, color: AriseColors.gold),
                onPressed: () => context.go(AppRoutes.workout(program.id)),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: AriseSpacing.xs),
      child: LongPressDraggable<PlannedSession>(
        data: session,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 280,
            child: Opacity(opacity: 0.9, child: tile),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.4, child: tile),
        child: tile,
      ),
    );
  }
}

/// Ajout ou modification d'une séance planifiée.
Future<void> showSessionDialog({
  required BuildContext context,
  required WidgetRef ref,
  required List<Program> programs,
  required int weekday,
  required DateTime date,
  required Set<int> restDays,
  PlannedSession? existing,
}) async {
  final result = await showDialog<_SessionDialogResult>(
    context: context,
    builder: (_) => _SessionDialog(
      programs: programs,
      weekday: weekday,
      date: date,
      restDays: restDays,
      existing: existing,
    ),
  );
  if (result == null) return;
  final repository = ref.read(planningRepositoryProvider);
  switch (result) {
    case _SessionDeleted():
      if (existing != null) await repository.delete(existing.id);
    case _SessionSaved(:final session):
      if (session.reminder && !(existing?.reminder ?? false)) {
        await ref.read(reminderSchedulerProvider).requestPermission();
      }
      await repository.save(session);
  }
}

sealed class _SessionDialogResult {
  const _SessionDialogResult();
}

final class _SessionSaved extends _SessionDialogResult {
  const _SessionSaved(this.session);

  final PlannedSession session;
}

final class _SessionDeleted extends _SessionDialogResult {
  const _SessionDeleted();
}

class _SessionDialog extends StatefulWidget {
  const _SessionDialog({
    required this.programs,
    required this.weekday,
    required this.date,
    required this.restDays,
    required this.existing,
  });

  final List<Program> programs;
  final int weekday;
  final DateTime date;
  final Set<int> restDays;
  final PlannedSession? existing;

  @override
  State<_SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<_SessionDialog> {
  late String _programId =
      widget.existing?.programId ?? widget.programs.first.id;
  late int _minuteOfDay = widget.existing?.minuteOfDay ?? 18 * 60;
  late bool _recurring = widget.existing?.recurring ?? true;
  late bool _reminder = widget.existing?.reminder ?? true;

  Program? get _program =>
      widget.programs.where((p) => p.id == _programId).firstOrNull;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _minuteOfDay ~/ 60,
        minute: _minuteOfDay % 60,
      ),
    );
    if (picked != null) {
      setState(() => _minuteOfDay = picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final program = _program;
    final allowed =
        program != null &&
        canPlanOn(
          program: program,
          weekday: widget.weekday,
          restDays: widget.restDays,
        );

    return AlertDialog(
      title: Text(
        widget.existing == null
            ? l10n.planningAddSessionTitle
            : l10n.planningEditSessionTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _programId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.planningProgram),
              items: [
                for (final p in widget.programs)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _programId = value);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.planningTime),
              trailing: Text(l10n.timeOfDay(_minuteOfDay)),
              onTap: () => unawaited(_pickTime()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.planningRecurringSwitch),
              value: _recurring,
              onChanged: (value) => setState(() => _recurring = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.planningReminderSwitch),
              subtitle: Text(
                l10n.planningReminderHint(
                  gameConfig.planning.reminderLeadMinutes,
                ),
              ),
              value: _reminder,
              onChanged: (value) => setState(() => _reminder = value),
            ),
            if (!allowed)
              Text(
                l10n.planningRestDayRefused,
                style: const TextStyle(color: AriseColors.danger),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _SessionDeleted()),
            child: Text(l10n.deleteAction),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(
          onPressed: allowed
              ? () => Navigator.of(context).pop(
                  _SessionSaved(
                    PlannedSession(
                      id: widget.existing?.id ?? 'session-${generateId()}',
                      programId: _programId,
                      weekday: widget.weekday,
                      minuteOfDay: _minuteOfDay,
                      recurring: _recurring,
                      date: _recurring ? null : dateOnly(widget.date),
                      reminder: _reminder,
                    ),
                  ),
                )
              : null,
          child: Text(l10n.saveAction),
        ),
      ],
    );
  }
}
