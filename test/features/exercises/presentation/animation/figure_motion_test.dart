import 'dart:convert';
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
        expect(_distance(j[anchor]!, first), lessThan(1e-3), reason: id);
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

  test('chaque exercice du catalogue a son mouvement', () {
    final catalog = jsonDecode(
      File('assets/catalog/exercises.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final exercise
        in (catalog['exercises'] as List<dynamic>)
            .cast<Map<String, dynamic>>()) {
      expect(
        motions,
        contains(exercise['motion']),
        reason: exercise['id'] as String,
      );
    }
  });

  test('les mains restent posées pendant les pompes', () {
    for (final id in ['push_up', 'knee_push_up', 'pike_push_up']) {
      final motion = motions[id]!;
      final first = computeJoints(
        motion.keys.first.angles,
        motion.view,
        motion.keys.first.root,
      )['hand_n']!;
      expect(first.y, closeTo(0, 0.01), reason: id);
      for (var i = 0; i < 24; i++) {
        final pose = motion.poseAt(i / 24);
        final hand = computeJoints(
          pose.angles,
          motion.view,
          pose.root,
        )['hand_n']!;
        expect(_distance(hand, first), lessThan(0.05), reason: '$id $i');
      }
    }
  });

  test('au sol, aucun membre ne traverse le plancher', () {
    for (final id in [
      'burpee',
      'glute_bridge',
      'dead_bug',
      'donkey_kick',
      'cobra_stretch',
      'pigeon_stretch',
      'crunch',
      'bench_dips',
      'hip_thrust',
    ]) {
      final motion = motions[id]!;
      for (var i = 0; i < 48; i++) {
        final pose = motion.poseAt(i / 48);
        for (final p in computeJoints(
          pose.angles,
          motion.view,
          pose.root,
        ).values) {
          expect(p.y, lessThan(0.07), reason: '$id $i');
        }
      }
    }
  });

  test('accessoires : barre de traction, banc, sans sol sous la barre', () {
    final pullUp = motions['pull_up']!;
    expect(pullUp.ground, isFalse);
    expect(pullUp.props.single, isA<PropBar>());
    final dips = motions['bench_dips']!;
    expect(dips.ground, isTrue);
    final bench = dips.props.single as PropBox;
    expect(bench.bottomRight.y, 0);
    expect(bench.topLeft.y, lessThan(0));
  });

  test('vu de dos, le tronc et les tibias apparaissent raccourcis', () {
    final j = computeJoints(
      {'t': 180, 'tz': 0.5, 'shz_n': 0.2},
      MotionView.front,
      (x: 0, y: 0),
    );
    expect(
      _distance(j['root']!, j['neck']!),
      closeTo(FigureProportions.torso * 0.5, 1e-9),
    );
    expect(
      _distance(j['knee_n']!, j['ankle_n']!),
      closeTo(FigureProportions.shin * 0.2, 1e-9),
    );
    expect(
      _distance(j['knee_f']!, j['ankle_f']!),
      closeTo(FigureProportions.shin, 1e-9),
    );
  });
}
