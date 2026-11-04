import 'package:arise/features/planning/domain/planned_session.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:arise/features/planning/domain/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

const _strength = Program(
  id: 'force',
  name: 'Force',
  format: ProgramFormat.strength,
);
const _mobility = Program(
  id: 'souple',
  name: 'Souplesse',
  format: ProgramFormat.mobility,
);

void main() {
  // Semaine du lundi 2 au dimanche 8 novembre 2026.
  final monday = DateTime(2026, 11, 2);

  test('startOfWeek renvoie le lundi à minuit', () {
    expect(startOfWeek(DateTime(2026, 11, 4, 15, 30)), monday);
    expect(startOfWeek(DateTime(2026, 11, 8, 23)), monday);
    expect(startOfWeek(monday), monday);
  });

  group('occurrencesForWeek', () {
    const weekly = PlannedSession(
      id: 'a',
      programId: 'force',
      weekday: DateTime.wednesday,
      minuteOfDay: 18 * 60,
    );
    final oneOff = PlannedSession(
      id: 'b',
      programId: 'force',
      weekday: DateTime.monday,
      minuteOfDay: 7 * 60,
      recurring: false,
      date: DateTime(2026, 11, 2),
    );

    test('place les séances récurrentes et ponctuelles, triées', () {
      final result = occurrencesForWeek([weekly, oneOff], monday);
      expect([for (final o in result) o.session.id], ['b', 'a']);
      expect(result.last.start, DateTime(2026, 11, 4, 18));
    });

    test('ignore une séance ponctuelle d’une autre semaine', () {
      final next = DateTime(2026, 11, 9);
      expect(
        [
          for (final o in occurrencesForWeek([weekly, oneOff], next))
            o.session.id,
        ],
        ['a'],
      );
    });
  });

  test('un jour de repos n’accepte que la mobilité', () {
    const rest = {DateTime.sunday};
    expect(
      canPlanOn(program: _strength, weekday: DateTime.sunday, restDays: rest),
      isFalse,
    );
    expect(
      canPlanOn(program: _mobility, weekday: DateTime.sunday, restDays: rest),
      isTrue,
    );
    expect(
      canPlanOn(program: _strength, weekday: DateTime.monday, restDays: rest),
      isTrue,
    );
  });

  test('déplacer une séance ponctuelle change aussi sa date', () {
    final session = PlannedSession(
      id: 'b',
      programId: 'force',
      weekday: DateTime.monday,
      minuteOfDay: 420,
      recurring: false,
      date: DateTime(2026, 11, 2),
    );
    final moved = moveSession(
      session,
      weekday: DateTime.friday,
      weekStart: monday,
    );
    expect(moved.weekday, DateTime.friday);
    expect(moved.date, DateTime(2026, 11, 6));
  });

  group('buildReminders', () {
    final programs = {'force': _strength};
    final now = DateTime(2026, 11, 4, 12);

    test('rappel hebdomadaire 30 minutes avant, y compris la veille', () {
      final reminders = buildReminders(
        sessions: const [
          PlannedSession(
            id: 'a',
            programId: 'force',
            weekday: DateTime.monday,
            minuteOfDay: 15,
          ),
        ],
        programsById: programs,
        now: now,
        leadMinutes: 30,
      );
      expect(
        reminders.single.time,
        const WeeklyReminderTime(
          weekday: DateTime.sunday,
          minuteOfDay: 24 * 60 - 15,
        ),
      );
      expect(reminders.single.programName, 'Force');
    });

    test('ignore les rappels désactivés, passés ou sans programme', () {
      final reminders = buildReminders(
        sessions: [
          const PlannedSession(
            id: 'off',
            programId: 'force',
            weekday: 1,
            minuteOfDay: 600,
            reminder: false,
          ),
          PlannedSession(
            id: 'past',
            programId: 'force',
            weekday: 2,
            minuteOfDay: 600,
            recurring: false,
            date: DateTime(2026, 11, 3),
          ),
          const PlannedSession(
            id: 'orphan',
            programId: 'gone',
            weekday: 3,
            minuteOfDay: 600,
          ),
          PlannedSession(
            id: 'soon',
            programId: 'force',
            weekday: 5,
            minuteOfDay: 600,
            recurring: false,
            date: DateTime(2026, 11, 6),
          ),
        ],
        programsById: programs,
        now: now,
        leadMinutes: 30,
      );
      expect(reminders.single.sessionId, 'soon');
      expect(
        reminders.single.time,
        OneOffReminderTime(DateTime(2026, 11, 6, 9, 30)),
      );
    });
  });

  test('l’identifiant de notification est stable et positif', () {
    expect(notificationIdFor('session-1'), notificationIdFor('session-1'));
    expect(
      notificationIdFor('session-1'),
      isNot(notificationIdFor('session-2')),
    );
    expect(notificationIdFor('session-1'), greaterThanOrEqualTo(0));
  });
}
