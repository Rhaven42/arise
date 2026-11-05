import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/muscle_analysis/domain/muscle_volume.dart';
import 'package:arise/features/planning/domain/program.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  test('musculation : 1 point par principal, 0,5 par secondaire', () {
    final v = sessionVolume(
      session(ProgramFormat.strength, [set('push_up'), set('push_up')]),
      exercises,
    );
    expect(v.points[MuscleId.pectoralisMidLower], 2);
    expect(v.points[MuscleId.tricepsBrachii], 2);
    expect(v.points[MuscleId.rectusAbdominis], 1);
    expect(v.pushSets, 2);
    expect(v.pullSets, 0);
  });

  test('une série sous 6/10 ou passée ne compte pas', () {
    final v = sessionVolume(
      session(ProgramFormat.strength, [
        set('push_up', rpe: 5),
        set('push_up', skip: true),
        set('row', rpe: 6),
      ]),
      exercises,
    );
    expect(v.points[MuscleId.pectoralisMidLower], isNull);
    expect(v.points[MuscleId.latissimusDorsi], 1);
    expect(v.pullSets, 1);
  });

  test('Tabata : 0,25 point par round, moitié pour les secondaires', () {
    final v = sessionVolume(
      session(ProgramFormat.interval, [
        for (var i = 0; i < 8; i++) set('push_up', seconds: 20),
      ]),
      exercises,
    );
    expect(v.points[MuscleId.pectoralisMidLower], 2);
    expect(v.points[MuscleId.rectusAbdominis], 1);
  });

  test('cardio : 1 point par 10 minutes, 3 au plus par séance', () {
    final short = sessionVolume(
      session(ProgramFormat.cardio, [set('walking', seconds: 25 * 60)]),
      exercises,
    );
    expect(short.points[MuscleId.quadriceps], closeTo(2.5, 1e-9));
    final long = sessionVolume(
      session(ProgramFormat.cardio, [
        set('walking', seconds: 30 * 60),
        set('walking', seconds: 30 * 60),
      ]),
      exercises,
    );
    expect(long.points[MuscleId.quadriceps], 3);
  });

  test('la mobilité n’alimente que l’indicateur de souplesse', () {
    final v = sessionVolume(
      session(ProgramFormat.mobility, [
        set('stretch', seconds: 90),
        set('stretch', seconds: 30),
      ]),
      exercises,
    );
    expect(v.points, isEmpty);
    expect(v.flexibilitySeconds, 120);
  });
}
