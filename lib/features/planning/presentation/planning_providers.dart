import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/database/app_database.dart';
import 'package:arise/core/utils/clock.dart';
import 'package:arise/features/planning/data/drift_planning_repositories.dart';
import 'package:arise/features/planning/data/local_notification_reminder_scheduler.dart';
import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/planning_repositories.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/domain/schedule.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'planning_providers.g.dart';

@Riverpod(keepAlive: true)
ProgramRepository programRepository(Ref ref) => DriftProgramRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

@Riverpod(keepAlive: true)
PlanningRepository planningRepository(Ref ref) => DriftPlanningRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(clockProvider),
);

@Riverpod(keepAlive: true)
ReminderScheduler reminderScheduler(Ref ref) {
  final l10n = lookupAppLocalizations(const Locale('fr'));
  return LocalNotificationReminderScheduler(
    plugin: FlutterLocalNotificationsPlugin(),
    channelName: l10n.reminderChannelName,
    channelDescription: l10n.reminderChannelDescription,
    texts: (programName) => (
      title: l10n.reminderTitle,
      body: l10n.reminderBody(
        programName,
        gameConfig.planning.reminderLeadMinutes,
      ),
    ),
  );
}

/// Programmes du joueur, triés par nom.
@Riverpod(keepAlive: true)
Stream<List<Program>> programs(Ref ref) => ref
    .watch(programRepositoryProvider)
    .watchAll()
    .map(
      (list) => [...list]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );

@Riverpod(keepAlive: true)
Stream<List<PlannedSession>> plannedSessions(Ref ref) =>
    ref.watch(planningRepositoryProvider).watchAll();

/// Reprogramme les rappels à chaque changement du planning.
@Riverpod(keepAlive: true)
Future<List<ReminderRequest>> reminderSync(Ref ref) async {
  final sessions = await ref.watch(plannedSessionsProvider.future);
  final programs = await ref.watch(programsProvider.future);
  final reminders = buildReminders(
    sessions: sessions,
    programsById: {for (final p in programs) p.id: p},
    now: ref.read(clockProvider)(),
    leadMinutes: gameConfig.planning.reminderLeadMinutes,
  );
  await ref.read(reminderSchedulerProvider).replaceAll(reminders);
  return reminders;
}

/// Semaine affichée dans le planning (lundi).
@riverpod
class DisplayedWeek extends _$DisplayedWeek {
  @override
  DateTime build() => startOfWeek(ref.read(clockProvider)().toLocal());

  void previous() => state = DateTime(
    state.year,
    state.month,
    state.day - DateTime.daysPerWeek,
  );

  void next() => state = DateTime(
    state.year,
    state.month,
    state.day + DateTime.daysPerWeek,
  );

  void today() => state = startOfWeek(ref.read(clockProvider)().toLocal());
}
