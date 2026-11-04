import 'dart:io';
import 'dart:math' as math;

import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:arise/features/exercises/presentation/animation/figure_motion.dart';
import 'package:flutter_test/flutter_test.dart';

double _distance(Point2 a, Point2 b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

void main() {
  final motions = decodeMotions(File(motionsAsset).readAsStringSync());

  test('toutes les animations se décodent avec au moins deux poses', () {
    expect(motions, isNotEmpty);
    for (final entry in motions.entries) {
      expect(entry.value.keys.length, greaterThanOrEqualTo(2), reason: entry.key);
      expect(entry.value.cycleSeconds, greaterThan(0), reason: entry.key);
    }
  });

  test('la cinématique respecte les longueurs des segments', () {
    final squat = motions['squat']!;
    for (final key in squat.keys) {
      final j = computeJoints(key.angles, squat.view, key.root);
      expect(_distance(j['root']!, j['neck']!), closeTo(FigureProportions.torso, 1e-9));
      expect(
        _distance(j['hip_n']!, j['knee_n']!),
        closeTo(FigureProportions.thigh, 1e-9),
      );
      expect(
        _distance(j['knee_n']!, j['ankle_n']!),
        closeTo(FigureProportions.shin, 1e-9),
      );
    }
  });

  test('les pieds restent au sol pendant le squat', () {
    final squat = motions['squat']!;
    for (var i = 0; i < 10; i++) {
      final pose = squat.poseAt(i / 10);
      final j = computeJoints(pose.angles, squat.view, pose.root);
      expect(j['ankle_n']!.y, closeTo(0, 1e-6));
    }
  });

  test('la pose au début du cycle est la première pose clé', () {
    final pushUp = motions['push_up']!;
    final pose = pushUp.poseAt(0);
    expect(pose.angles, pushUp.keys.first.angles);
    expect(pose.root.x, closeTo(pushUp.keys.first.root.x, 1e-3));
    expect(pose.root.y, closeTo(pushUp.keys.first.root.y, 1e-3));
  });

  test('chaque muscle est représenté par exactement un segment', () {
    final all = [for (final set in figureSegmentMuscles.values) ...set];
    expect(all.toSet(), MuscleId.values.toSet());
    expect(all, hasLength(MuscleId.values.length));
  });

  test('le segment prend le rôle le plus fort de ses muscles', () {
    expect(
      segmentRole(FigureSegment.thigh, const {
        MuscleId.adductors: MuscleRole.secondary,
        MuscleId.quadriceps: MuscleRole.primary,
      }),
      MuscleRole.primary,
    );
    expect(
      segmentRole(FigureSegment.shin, const {
        MuscleId.soleus: MuscleRole.secondary,
      }),
      MuscleRole.secondary,
    );
    expect(segmentRole(FigureSegment.head, const {}), isNull);
  });
}
