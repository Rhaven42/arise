import 'package:arise/core/config/game_config.dart';
import 'package:arise/features/exercises/domain/stat_id.dart';
import 'package:arise/features/health/domain/health_log.dart';
import 'package:arise/features/health/domain/health_rules.dart';
import 'package:arise/features/progression/domain/civil_date.dart';
import 'package:flutter_test/flutter_test.dart';

const _today = CivilDate(2026, 11, 4);
final HealthConfig _c = gameConfig.health;

DateTime _at(int hour, [int minute = 0]) => DateTime(2026, 11, 4, hour, minute);

void main() {
  group('healthReward', () {
    test('une journée vide ne rapporte rien et ne pénalise jamais', () {
      expect(healthReward(const HealthDay(day: _today)), isEmpty);
    });

    test('les pas rapportent de l Endurance par tranche complète', () {
      final reward = healthReward(
        HealthDay(day: _today, steps: _c.stepsPerBlock * 3 + 10),
      );
      expect(reward, {StatId.endurance: 3 * _c.xpPerStepBlock});
    });

    test('pas et activités sont plafonnés chaque jour', () {
      final capped = healthReward(
        HealthDay(
          day: _today,
          steps: _c.stepsCap,
          activityMinutes: _c.activityMinutesCap,
        ),
      );
      final beyond = healthReward(
        HealthDay(
          day: _today,
          steps: _c.stepsCap * 5,
          activityMinutes: _c.activityMinutesCap * 5,
        ),
      );
      expect(beyond, capped);
      expect(
        capped[StatId.endurance],
        _c.stepsCap ~/ _c.stepsPerBlock * _c.xpPerStepBlock +
            _c.activityMinutesCap ~/ _c.activityMinutesPerXp,
      );
    });

    test('sommeil suffisant et hydratation donnent de la Vitalité', () {
      final short = healthReward(
        HealthDay(day: _today, sleepMinutes: _c.sleepBonusMinHours * 60 - 1),
      );
      expect(short, isEmpty);
      final rested = healthReward(
        HealthDay(
          day: _today,
          sleepMinutes: _c.sleepBonusMinHours * 60,
          glasses: _c.hydrationGoalGlasses,
        ),
      );
      expect(rested, {StatId.vitality: _c.sleepBonusXp + _c.hydrationBonusXp});
    });
  });

  test('l XP n est versée qu une fois par journée', () {
    var day = HealthDay(day: _today, steps: _c.stepsPerBlock * 2);
    final first = pendingHealthXp(day);
    expect(first, {StatId.endurance: 2 * _c.xpPerStepBlock});
    day = markCredited(day, first);
    expect(pendingHealthXp(day), isEmpty);

    day = withReading(
      day,
      steps: _c.stepsPerBlock * 5,
      activityMinutes: 0,
      sleepMinutes: 0,
    );
    expect(pendingHealthXp(day), {StatId.endurance: 3 * _c.xpPerStepBlock});
  });

  test('une lecture plus basse n efface rien', () {
    const day = HealthDay(
      day: _today,
      steps: 5000,
      activityMinutes: 20,
      sleepMinutes: 400,
    );
    final read = withReading(
      day,
      steps: 100,
      activityMinutes: 0,
      sleepMinutes: 450,
    );
    expect(read.steps, 5000);
    expect(read.activityMinutes, 20);
    expect(read.sleepMinutes, 450);
  });

  group('externalActivityMinutes', () {
    test('une activité hors séance compte entièrement', () {
      expect(
        externalActivityMinutes([(start: _at(7), end: _at(7, 45))], []),
        45,
      );
    });

    test('le temps passé en séance dans l appli ne compte pas deux fois', () {
      final minutes = externalActivityMinutes(
        [(start: _at(7), end: _at(8))],
        [
          (start: _at(7, 30), end: _at(8, 30)),
          (start: _at(7, 40), end: _at(7, 50)),
        ],
      );
      expect(minutes, 30);
    });

    test('une activité vide ou à l envers est ignorée', () {
      expect(externalActivityMinutes([(start: _at(9), end: _at(8))], []), 0);
    });
  });

  test('les verres restent entre zéro et le maximum', () {
    const day = HealthDay(day: _today);
    expect(addGlasses(day, -1).glasses, 0);
    expect(addGlasses(day, _c.maxGlasses + 5).glasses, _c.maxGlasses);
    expect(addGlasses(addGlasses(day, 2), -1).glasses, 1);
  });

  test('l historique garde seulement les derniers jours, triés', () {
    var log = const HealthLog();
    for (var i = _c.historyDays + 5; i >= 0; i--) {
      log = upsertDay(log, HealthDay(day: _today.addDays(-i), steps: i));
    }
    expect(log.days, hasLength(_c.historyDays));
    expect(log.days.last.day, _today);
    expect(log.days.first.day, _today.addDays(-(_c.historyDays - 1)));

    log = upsertDay(log, const HealthDay(day: _today, steps: 999));
    expect(log.days, hasLength(_c.historyDays));
    expect(log.dayOf(_today).steps, 999);
  });

  test('on relit hier et aujourd hui', () {
    expect(daysToRead(_today), [const CivilDate(2026, 11, 3), _today]);
  });

  test('HealthLog survit à un aller-retour JSON', () {
    const log = HealthLog(
      days: [
        HealthDay(
          day: _today,
          steps: 4200,
          glasses: 3,
          credited: {StatId.endurance: 8},
        ),
      ],
    );
    expect(HealthLog.fromJson(log.toJson()), log);
  });
}
