import 'dart:math' as math;

import 'package:arise/core/anatomy/muscle.dart';

/// Point 2D (unités du mannequin : taille ≈ 1,8).
typedef Point2 = ({double x, double y});

/// Vue d'une animation : de profil ou de face.
enum MotionView { side, front }

/// Pose clé d'une animation.
class MotionKey {
  const MotionKey({
    required this.root,
    required this.hold,
    required this.angles,
    this.anchor = 'root',
    this.target = (x: 0, y: 0),
  });

  factory MotionKey.fromJson(Map<String, dynamic> json) {
    final root = (json['root'] as List<dynamic>).cast<num>();
    final target = (json['target'] as List<dynamic>? ?? const [0, 0])
        .cast<num>();
    return MotionKey(
      root: (x: root[0].toDouble(), y: root[1].toDouble()),
      hold: (json['hold'] as num).toDouble(),
      anchor: json['anchor'] as String? ?? 'root',
      target: (x: target[0].toDouble(), y: target[1].toDouble()),
      angles: {
        for (final entry in (json['angles'] as Map<String, dynamic>).entries)
          entry.key: (entry.value as num).toDouble(),
      },
    );
  }

  /// Position du bassin.
  final Point2 root;

  /// Durée de la transition vers la pose suivante, en secondes.
  final double hold;

  /// Articulation fixée au sol (ou à la barre) pendant la pose.
  final String anchor;

  /// Position de l'articulation d'ancrage.
  final Point2 target;

  /// Angles absolus des segments, en degrés (0 = vers le bas).
  final Map<String, double> angles;
}

/// Animation d'un exercice (`assets/animations/motions.json`).
class FigureMotion {
  const FigureMotion({required this.view, required this.keys});

  factory FigureMotion.fromJson(Map<String, dynamic> json) => FigureMotion(
    view: MotionView.values.byName(json['view'] as String),
    keys: [
      for (final key in json['keys'] as List<dynamic>)
        MotionKey.fromJson(key as Map<String, dynamic>),
    ],
  );

  final MotionView view;
  final List<MotionKey> keys;

  double get cycleSeconds => keys.fold(0, (total, key) => total + key.hold);

  /// Pose à l'instant [t] du cycle (0 ≤ t < 1), avec un lissage doux.
  ({Point2 root, Map<String, double> angles}) poseAt(double t) {
    final total = cycleSeconds;
    var elapsed = (t % 1) * total;
    for (var i = 0; i < keys.length; i++) {
      final from = keys[i];
      if (elapsed <= from.hold || i == keys.length - 1) {
        final to = keys[(i + 1) % keys.length];
        final raw = from.hold == 0
            ? 0
            : (elapsed / from.hold).clamp(0, 1).toDouble();
        final k = 0.5 - math.cos(raw * math.pi) / 2;
        double lerp(double a, double b) => a + (b - a) * k;
        final angles = {
          for (final name in from.angles.keys)
            name: lerp(
              from.angles[name]!,
              to.angles[name] ?? from.angles[name]!,
            ),
        };
        // Même ancrage aux deux poses : on recalcule le bassin pour que
        // l'articulation ancrée reste immobile (pas de pieds qui flottent).
        if (from.anchor == to.anchor) {
          final target = (
            x: lerp(from.target.x, to.target.x),
            y: lerp(from.target.y, to.target.y),
          );
          final free = computeJoints(angles, view, (x: 0, y: 0))[from.anchor];
          if (free != null) {
            return (
              root: (x: target.x - free.x, y: target.y - free.y),
              angles: angles,
            );
          }
        }
        return (
          root: (
            x: lerp(from.root.x, to.root.x),
            y: lerp(from.root.y, to.root.y),
          ),
          angles: angles,
        );
      }
      elapsed -= from.hold;
    }
    return (root: keys.first.root, angles: keys.first.angles);
  }
}

/// Longueurs des segments du mannequin (identiques à l'outil de création).
abstract final class FigureProportions {
  static const torso = 0.55;
  static const neck = 0.17;
  static const headRadius = 0.11;
  static const upperArm = 0.30;
  static const forearm = 0.27;
  static const thigh = 0.45;
  static const shin = 0.43;
  static const foot = 0.13;
  static const frontFoot = 0.05;
  static const shoulderAt = 0.92;
  static const frontShoulderDx = 0.17;
  static const frontHipDx = 0.08;
}

Point2 _step(Point2 from, double degrees, double length) {
  final r = degrees * math.pi / 180;
  return (x: from.x + math.sin(r) * length, y: from.y + math.cos(r) * length);
}

/// Positions des articulations (cinématique directe).
///
/// Clés : `root`, `neck`, `head`, puis `shoulder_n`, `elbow_n`, `hand_n`,
/// `hip_n`, `knee_n`, `ankle_n`, `toe_n` et leurs équivalents `_f` (côté
/// éloigné).
Map<String, Point2> computeJoints(
  Map<String, double> angles,
  MotionView view,
  Point2 root,
) {
  double a(String name) => angles[name] ?? 0;
  final joints = <String, Point2>{'root': root};
  final torso = a('t');
  joints['neck'] = _step(root, torso, FigureProportions.torso);
  joints['head'] = _step(joints['neck']!, torso, FigureProportions.neck);
  final shoulder = _step(
    root,
    torso,
    FigureProportions.torso * FigureProportions.shoulderAt,
  );
  for (final (side, sign) in const [('n', 1.0), ('f', -1.0)]) {
    final front = view == MotionView.front;
    double mirror(double degrees) => front ? degrees * sign : degrees;
    final s = front
        ? (
            x: shoulder.x + sign * FigureProportions.frontShoulderDx,
            y: shoulder.y,
          )
        : shoulder;
    final hip = front
        ? (x: root.x + sign * FigureProportions.frontHipDx, y: root.y)
        : root;
    joints['shoulder_$side'] = s;
    joints['elbow_$side'] = _step(
      s,
      mirror(a('ua_$side')),
      FigureProportions.upperArm,
    );
    joints['hand_$side'] = _step(
      joints['elbow_$side']!,
      mirror(a('fa_$side')),
      FigureProportions.forearm,
    );
    joints['hip_$side'] = hip;
    joints['knee_$side'] = _step(
      hip,
      mirror(a('th_$side')),
      FigureProportions.thigh,
    );
    joints['ankle_$side'] = _step(
      joints['knee_$side']!,
      mirror(a('sh_$side')),
      FigureProportions.shin,
    );
    joints['toe_$side'] = front
        ? _step(joints['ankle_$side']!, 0, FigureProportions.frontFoot)
        : _step(joints['ankle_$side']!, a('ft_$side'), FigureProportions.foot);
  }
  return joints;
}

/// Segment visible du mannequin.
enum FigureSegment {
  head,
  torso,
  shoulder,
  upperArm,
  forearm,
  pelvis,
  thigh,
  shin,
}

/// Muscles représentés par chaque segment du mannequin (répartition
/// purement graphique, indépendante des exercices).
const figureSegmentMuscles = <FigureSegment, Set<MuscleId>>{
  FigureSegment.head: {MuscleId.sternocleidomastoid},
  FigureSegment.torso: {
    MuscleId.pectoralisUpper,
    MuscleId.pectoralisMidLower,
    MuscleId.rectusAbdominis,
    MuscleId.obliques,
    MuscleId.transversusAbdominis,
    MuscleId.serratusAnterior,
    MuscleId.trapeziusUpper,
    MuscleId.trapeziusMidLower,
    MuscleId.rhomboids,
    MuscleId.latissimusDorsi,
    MuscleId.teresMajor,
    MuscleId.rotatorCuff,
    MuscleId.erectorSpinae,
  },
  FigureSegment.shoulder: {
    MuscleId.deltoidAnterior,
    MuscleId.deltoidLateral,
    MuscleId.deltoidPosterior,
  },
  FigureSegment.upperArm: {
    MuscleId.bicepsBrachii,
    MuscleId.brachialis,
    MuscleId.tricepsBrachii,
  },
  FigureSegment.forearm: {
    MuscleId.forearmFlexors,
    MuscleId.brachioradialis,
    MuscleId.forearmExtensors,
  },
  FigureSegment.pelvis: {
    MuscleId.gluteusMaximus,
    MuscleId.gluteusMedius,
    MuscleId.hipFlexors,
    MuscleId.abductors,
  },
  FigureSegment.thigh: {
    MuscleId.quadriceps,
    MuscleId.hamstrings,
    MuscleId.adductors,
  },
  FigureSegment.shin: {
    MuscleId.tibialisAnterior,
    MuscleId.gastrocnemius,
    MuscleId.soleus,
  },
};

/// Rôle le plus fort parmi les muscles d'un segment.
MuscleRole? segmentRole(
  FigureSegment segment,
  Map<MuscleId, MuscleRole> highlights,
) {
  MuscleRole? best;
  for (final muscle in figureSegmentMuscles[segment]!) {
    final role = highlights[muscle];
    if (role == MuscleRole.primary) return role;
    best ??= role;
  }
  return best;
}
