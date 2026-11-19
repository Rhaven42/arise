import 'dart:io';
import 'dart:math' as math;

import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:arise/features/exercises/presentation/animation/figure_motion.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrôle de tous les mouvements sur tout leur cycle (images serrées) :
/// sol, sens de flexion des articulations, continuité de l'animation.
void main() {
  final motions = decodeMotions(File(motionsAsset).readAsStringSync());
  const frames = 480;

  // Angle d'un membre dans [-180, 180].
  double wrap(double a) => (a + 540) % 360 - 180;

  test('aucune articulation ne passe sous le sol dessiné', () {
    final faults = <String>[];
    for (final MapEntry(key: id, value: m) in motions.entries) {
      if (!m.ground) continue;
      // Même ligne de sol que le dessin (FigurePainter).
      final bottom = FigurePainter.boundsOf(m).bottom;
      final ground = math.max(math.min(0, bottom), bottom - 0.06);
      for (var i = 0; i < frames; i++) {
        final pose = m.poseAt(i / frames);
        final j = computeJoints(pose.angles, m.view, pose.root);
        for (final MapEntry(key: name, value: p) in j.entries) {
          // La tête est un disque : son bord ne doit pas non plus entrer.
          final limit = name == 'head'
              ? ground - FigureProportions.headRadius
              : ground;
          if (p.y > limit + 0.005) {
            faults.add('$id image $i : $name à ${p.y.toStringAsFixed(3)}');
            break;
          }
        }
      }
    }
    expect(faults, isEmpty, reason: faults.take(20).join('\n'));
  });

  test('genoux et coudes ne plient jamais à l’envers (vue de profil)', () {
    final faults = <String>[];
    for (final MapEntry(key: id, value: m) in motions.entries) {
      if (m.view != MotionView.side) continue;
      for (var i = 0; i < frames; i += 4) {
        final a = m.poseAt(i / frames).angles;
        for (final side in ['n', 'f']) {
          // Genou : le tibia part vers l'arrière de la cuisse (flexion
          // négative), à 5° près d'une jambe tendue.
          final knee = wrap(a['sh_$side']! - a['th_$side']!);
          if (knee > 6 || knee < -165) {
            faults.add('$id image $i : genou $side ${knee.round()}°');
          }
          // Coude : l'avant-bras part vers l'avant du bras.
          final elbow = wrap(a['fa_$side']! - a['ua_$side']!);
          if (elbow < -12 || elbow > 155) {
            faults.add('$id image $i : coude $side ${elbow.round()}°');
          }
        }
      }
    }
    expect(faults, isEmpty, reason: faults.take(30).join('\n'));
  });

  test('l’animation est continue : aucun à-coup entre deux images', () {
    final faults = <String>[];
    for (final MapEntry(key: id, value: m) in motions.entries) {
      final steps = <double>[];
      Map<String, Point2>? previous;
      for (var i = 0; i <= frames; i++) {
        final pose = m.poseAt(i / frames);
        final j = computeJoints(pose.angles, m.view, pose.root);
        if (previous != null) {
          var step = 0.0;
          for (final MapEntry(key: name, value: p) in j.entries) {
            final q = previous[name]!;
            step = math.max(
              step,
              math.sqrt(math.pow(p.x - q.x, 2) + math.pow(p.y - q.y, 2)),
            );
          }
          steps.add(step);
        }
        previous = j;
      }
      // Un à-coup : un pas bien plus grand que ses voisins (une rupture,
      // pas un mouvement rapide).
      for (var i = 1; i < steps.length - 1; i++) {
        final around = math.max(math.max(steps[i - 1], steps[i + 1]), 1e-4);
        if (steps[i] > 0.02 && steps[i] > 2.5 * around) {
          faults.add('$id image $i : à-coup de ${steps[i]}');
        }
      }
    }
    expect(faults, isEmpty, reason: faults.take(30).join('\n'));
  });

  test('un appui reste fixe tant que sa pose clé le maintient', () {
    final faults = <String>[];
    for (final MapEntry(key: id, value: m) in motions.entries) {
      for (var k = 0; k < m.keys.length; k++) {
        final from = m.keys[k];
        final to = m.keys[(k + 1) % m.keys.length];
        if (from.anchor != to.anchor ||
            from.anchor == 'root' ||
            from.target != to.target) {
          continue;
        }
        // Instant de début de cette pose clé dans le cycle.
        final start = m.keys
            .take(k)
            .fold<double>(0, (total, key) => total + key.hold);
        for (var s = 0; s <= 10; s++) {
          final t = (start + from.hold * s / 10) / m.cycleSeconds;
          final pose = m.poseAt(t.clamp(0, 0.9999));
          final p = computeJoints(pose.angles, m.view, pose.root)[from.anchor]!;
          final d = math.sqrt(
            math.pow(p.x - from.target.x, 2) + math.pow(p.y - from.target.y, 2),
          );
          if (d > 0.01) {
            faults.add('$id pose $k : ${from.anchor} glisse de $d');
            break;
          }
        }
      }
    }
    expect(faults, isEmpty, reason: faults.take(20).join('\n'));
  });
}
