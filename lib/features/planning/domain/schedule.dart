import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';

/// Jour local sans heure.
DateTime dateOnly(DateTime local) =>
    DateTime(local.year, local.month, local.day);

/// Lundi de la semaine contenant [local].
DateTime startOfWeek(DateTime local) {
  final day = dateOnly(local);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

/// Date du jour [weekday] dans la semaine commençant le lundi [weekStart].
DateTime dayOfWeek(DateTime weekStart, int weekday) =>
    DateTime(weekStart.year, weekStart.month, weekStart.day + weekday - 1);

/// Séance placée à une date précise.
typedef SessionOccurrence = ({PlannedSession session, DateTime start});

/// Séances de la semaine commençant à [weekStart], triées par horaire.
List<SessionOccurrence> occurrencesForWeek(
  Iterable<PlannedSession> sessions,
  DateTime weekStart,
) {
  final weekEnd = dayOfWeek(weekStart, DateTime.sunday);
  final result = <SessionOccurrence>[];
  for (final session in sessions) {
    final DateTime day;
    if (session.recurring) {
      day = dayOfWeek(weekStart, session.weekday);
    } else {
      final date = session.date;
      if (date == null) continue;
      final local = dateOnly(date);
      if (local.isBefore(weekStart) || local.isAfter(weekEnd)) continue;
      day = local;
    }
    result.add((
      session: session,
      start: DateTime(day.year, day.month, day.day, 0, session.minuteOfDay),
    ));
  }
  return result..sort((a, b) => a.start.compareTo(b.start));
}

/// Vrai si [program] peut être planifié ce jour-là : les jours de repos
/// déclarés n'acceptent que la mobilité légère (SPEC §7).
bool canPlanOn({
  required Program program,
  required int weekday,
  required Set<int> restDays,
}) {
  return !restDays.contains(weekday) ||
      program.format == ProgramFormat.mobility;
}

/// Déplace une séance vers un autre jour de la semaine affichée.
PlannedSession moveSession(
  PlannedSession session, {
  required int weekday,
  required DateTime weekStart,
}) {
  return session.copyWith(
    weekday: weekday,
    date: session.recurring ? null : dayOfWeek(weekStart, weekday),
  );
}

/// Moment d'un rappel.
sealed class ReminderTime {
  const ReminderTime();
}

/// Rappel chaque semaine, le jour [weekday] à [minuteOfDay].
final class WeeklyReminderTime extends ReminderTime {
  const WeeklyReminderTime({required this.weekday, required this.minuteOfDay});

  final int weekday;
  final int minuteOfDay;

  @override
  bool operator ==(Object other) =>
      other is WeeklyReminderTime &&
      other.weekday == weekday &&
      other.minuteOfDay == minuteOfDay;

  @override
  int get hashCode => Object.hash(weekday, minuteOfDay);
}

/// Rappel unique, à une date et une heure locales.
final class OneOffReminderTime extends ReminderTime {
  const OneOffReminderTime(this.at);

  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is OneOffReminderTime && other.at == at;

  @override
  int get hashCode => at.hashCode;
}

/// Rappel à programmer sur le téléphone.
class ReminderRequest {
  const ReminderRequest({
    required this.notificationId,
    required this.sessionId,
    required this.programName,
    required this.time,
  });

  final int notificationId;
  final String sessionId;
  final String programName;
  final ReminderTime time;

  @override
  bool operator ==(Object other) =>
      other is ReminderRequest &&
      other.notificationId == notificationId &&
      other.sessionId == sessionId &&
      other.programName == programName &&
      other.time == time;

  @override
  int get hashCode => Object.hash(notificationId, sessionId, programName, time);
}

/// Identifiant de notification stable (31 bits) dérivé de l'identifiant de
/// la séance (FNV-1a).
int notificationIdFor(String sessionId) {
  var hash = 0x811c9dc5;
  for (final unit in sessionId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

/// Calcule les rappels à programmer, [leadMinutes] avant chaque séance.
///
/// Les séances ponctuelles déjà passées et celles dont le programme a
/// disparu sont ignorées.
List<ReminderRequest> buildReminders({
  required Iterable<PlannedSession> sessions,
  required Map<String, Program> programsById,
  required DateTime now,
  required int leadMinutes,
}) {
  const minutesPerDay = 24 * 60;
  final result = <ReminderRequest>[];
  for (final session in sessions) {
    final program = programsById[session.programId];
    if (!session.reminder || program == null) continue;

    final ReminderTime time;
    if (session.recurring) {
      var minute = session.minuteOfDay - leadMinutes;
      var weekday = session.weekday;
      while (minute < 0) {
        minute += minutesPerDay;
        weekday = weekday == DateTime.monday ? DateTime.sunday : weekday - 1;
      }
      time = WeeklyReminderTime(weekday: weekday, minuteOfDay: minute);
    } else {
      final date = session.date;
      if (date == null) continue;
      final at = DateTime(
        date.year,
        date.month,
        date.day,
        0,
        session.minuteOfDay - leadMinutes,
      );
      if (!at.isAfter(now)) continue;
      time = OneOffReminderTime(at);
    }
    result.add(
      ReminderRequest(
        notificationId: notificationIdFor(session.id),
        sessionId: session.id,
        programName: program.name,
        time: time,
      ),
    );
  }
  return result;
}
