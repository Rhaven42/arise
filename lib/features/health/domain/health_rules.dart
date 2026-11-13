import 'dart:math' as math;

import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/health/domain/health_log.dart';
import 'package:arise/features/progression/domain/civil_date.dart';

/// Plage horaire (activité lue sur le téléphone, séance de l'application).
typedef TimeSpan = ({DateTime start, DateTime end});

/// XP de stat que mérite une journée, plafonds compris (SPEC §13) :
/// pas et activités → Endurance ; sommeil suffisant et hydratation →
/// Vitalité. Jamais de pénalité.
Map<StatId, int> healthReward(HealthDay day, {HealthConfig? config}) {
  final c = config ?? gameConfig.health;
  final steps = math.min(day.steps, c.stepsCap);
  final activity = math.min(day.activityMinutes, c.activityMinutesCap);
  final endurance =
      steps ~/ c.stepsPerBlock * c.xpPerStepBlock +
      activity ~/ c.activityMinutesPerXp;
  final vitality =
      (day.sleepMinutes >= c.sleepBonusMinHours * 60 ? c.sleepBonusXp : 0) +
      (day.glasses >= c.hydrationGoalGlasses ? c.hydrationBonusXp : 0);
  return {
    if (endurance > 0) StatId.endurance: endurance,
    if (vitality > 0) StatId.vitality: vitality,
  };
}

/// XP encore à verser pour la journée (ce qui est mérité moins ce qui a
/// déjà été versé ; jamais négatif).
Map<StatId, int> pendingHealthXp(HealthDay day, {HealthConfig? config}) {
  final reward = healthReward(day, config: config);
  return {
    for (final e in reward.entries)
      if (e.value > (day.credited[e.key] ?? 0))
        e.key: e.value - (day.credited[e.key] ?? 0),
  };
}

/// Journée après versement de [paid].
HealthDay markCredited(HealthDay day, Map<StatId, int> paid) => day.copyWith(
  credited: {
    for (final stat in {...day.credited.keys, ...paid.keys})
      stat: (day.credited[stat] ?? 0) + (paid[stat] ?? 0),
  },
);

/// Minutes d'activité lues sur le téléphone qui ne recouvrent aucune séance
/// de l'application (une séance faite dans l'appli ne compte pas deux fois).
int externalActivityMinutes(
  Iterable<TimeSpan> activities,
  Iterable<TimeSpan> appSessions,
) {
  var total = Duration.zero;
  for (final a in activities) {
    if (!a.end.isAfter(a.start)) continue;
    var free = a.end.difference(a.start);
    // Recouvrements, fusionnés pour ne pas retirer deux fois la même minute.
    final overlaps = <TimeSpan>[
      for (final s in appSessions)
        if (s.start.isBefore(a.end) && s.end.isAfter(a.start))
          (
            start: s.start.isAfter(a.start) ? s.start : a.start,
            end: s.end.isBefore(a.end) ? s.end : a.end,
          ),
    ]..sort((x, y) => x.start.compareTo(y.start));
    DateTime? cursor;
    for (final o in overlaps) {
      final start = cursor != null && cursor.isAfter(o.start)
          ? cursor
          : o.start;
      if (o.end.isAfter(start)) free -= o.end.difference(start);
      if (cursor == null || o.end.isAfter(cursor)) cursor = o.end;
    }
    total += free;
  }
  return total.inMinutes;
}

/// Journée mise à jour par une lecture du téléphone. Les valeurs ne
/// baissent jamais (une lecture partielle n'efface rien).
HealthDay withReading(
  HealthDay day, {
  required int steps,
  required int activityMinutes,
  required int sleepMinutes,
}) => day.copyWith(
  steps: math.max(day.steps, steps),
  activityMinutes: math.max(day.activityMinutes, activityMinutes),
  sleepMinutes: math.max(day.sleepMinutes, sleepMinutes),
);

/// Ajoute (ou retire, [delta] négatif) des verres d'eau, entre 0 et le
/// maximum prévu.
HealthDay addGlasses(HealthDay day, int delta, {HealthConfig? config}) {
  final c = config ?? gameConfig.health;
  return day.copyWith(glasses: (day.glasses + delta).clamp(0, c.maxGlasses));
}

/// Historique avec [day] remplacée ou ajoutée, limité aux derniers jours.
HealthLog upsertDay(HealthLog log, HealthDay day, {HealthConfig? config}) {
  final c = config ?? gameConfig.health;
  final oldest = day.day.addDays(-(c.historyDays - 1));
  final days = [
    for (final d in log.days)
      if (d.day != day.day && !d.day.isBefore(oldest)) d,
    day,
  ]..sort((a, b) => a.day.compareTo(b.day));
  return log.copyWith(days: days);
}

/// Jours à relire sur le téléphone : aujourd'hui et hier (le sommeil de la
/// nuit et les données synchronisées en retard).
List<CivilDate> daysToRead(CivilDate today) => [today.previous, today];
