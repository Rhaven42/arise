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
      expect(
        entry.value.keys.length,
        greaterThanOrEqualTo(2),
        reason: entry.key,
      );
      expect(entry.value.cycleSeconds, greaterThan(0), reason: entry.key);
    }
  });

  test('la cinématique respecte les longueurs des segments', () {
    final squat = motions['squat']!;
    for (final key in squat.keys) {
      final j = computeJoints(key.angles, squat.view, key.root);
      expect(
        _distance(j['root']!, j['neck']!),
        closeTo(FigureProportions.torso, 1e-9),
      );
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

  test('tête inclinée et épaules haussées', () {
    const upright = {'t': 180.0};
    final base = computeJoints(upright, MotionView.front, (x: 0, y: 0));
    final tilted = computeJoints(
      {...upright, 'hd': 30, 'sl': 0.06},
      MotionView.front,
      (x: 0, y: 0),
    );
    // La tête penche sans changer de distance au cou.
    expect(tilted['head']!.x, isNot(closeTo(base['head']!.x, 1e-3)));
    expect(
      _distance(tilted['neck']!, tilted['head']!),
      closeTo(FigureProportions.neck, 1e-9),
    );
    // Les épaules montent (y vers le bas), le cou ne bouge pas.
    expect(
      tilted['shoulder_n']!.y,
      closeTo(base['shoulder_n']!.y - 0.06, 1e-9),
    );
    expect(tilted['neck'], base['neck']);
  });

  test('les mouvements au sol gardent leur appui pendant tout le cycle', () {
    for (final id in ['cat_cow', 'dead_bug', 'wall_sit', 'side_lunge']) {
      final motion = motions[id]!;
      final anchor = motion.keys.first.anchor;
      final first = computeJoints(
        motion.keys.first.angles,
        motion.view,
        motion.keys.first.root,
      )[anchor]!;
      for (var i = 0; i < 10; i++) {
        final pose = motion.poseAt(i / 10);
        final j = computeJoints(pose.angles, motion.view, pose.root);
        expect(_distance(j[anchor]!, first), lessThan(1e-6), reason: id);
      }
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
