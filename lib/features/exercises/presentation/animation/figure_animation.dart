import 'dart:convert';
import 'dart:math' as math;

import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/features/exercises/presentation/animation/figure_motion.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'figure_animation.g.dart';

const String motionsAsset = 'assets/animations/motions.json';

/// Décode le fichier des mouvements.
Map<String, FigureMotion> decodeMotions(String content) {
  final json = jsonDecode(content) as Map<String, dynamic>;
  return {
    for (final entry in json.entries)
      entry.key: FigureMotion.fromJson(entry.value as Map<String, dynamic>),
  };
}

@Riverpod(keepAlive: true)
Future<Map<String, FigureMotion>> figureMotions(Ref ref) async =>
    decodeMotions(await rootBundle.loadString(motionsAsset));

/// Mannequin 2D qui exécute l'exercice en boucle, muscles colorés.
///
/// L'animation s'arrête si le système demande de réduire les animations ;
/// un bouton permet aussi de la mettre en pause.
class FigureAnimation extends ConsumerStatefulWidget {
  const FigureAnimation({
    required this.motionId,
    required this.highlights,
    required this.semanticLabel,
    super.key,
  });

  /// Bouton pause / lecture.
  static const pauseKey = Key('figure-animation-pause');

  final String? motionId;
  final Map<MuscleId, MuscleRole> highlights;
  final String semanticLabel;

  @override
  ConsumerState<FigureAnimation> createState() => _FigureAnimationState();
}

class _FigureAnimationState extends ConsumerState<FigureAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _paused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync(FigureMotion? motion, {required bool reduceMotion}) {
    if (motion == null) return;
    final duration = Duration(
      milliseconds: (motion.cycleSeconds * 1000).round(),
    );
    if (_controller.duration != duration) _controller.duration = duration;
    final shouldRun = !_paused && !reduceMotion;
    if (shouldRun && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldRun && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final motions = ref.watch(figureMotionsProvider).value;
    final motion = motions?[widget.motionId];
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync(motion, reduceMotion: reduceMotion);

    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: motion == null
                ? const SizedBox.shrink()
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      painter: FigurePainter(
                        motion: motion,
                        t: _controller.value,
                        highlights: widget.highlights,
                      ),
                    ),
                  ),
          ),
          if (motion != null && !reduceMotion)
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                key: FigureAnimation.pauseKey,
                tooltip: _paused ? l10n.animationPlay : l10n.animationPause,
                icon: Icon(
                  _paused ? Icons.play_arrow : Icons.pause,
                  color: AriseColors.parchment,
                ),
                onPressed: () => setState(() => _paused = !_paused),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dessin du mannequin à l'instant [t] de l'animation : mannequin
/// articulé aux membres galbés, muscles travaillés colorés, positions
/// extrêmes en transparence, accessoires et ombre au sol.
class FigurePainter extends CustomPainter {
  FigurePainter({
    required this.motion,
    required this.t,
    required this.highlights,
  });

  final FigureMotion motion;
  final double t;
  final Map<MuscleId, MuscleRole> highlights;

  static final Map<FigureMotion, Rect> _boundsCache = Map.identity();

  /// Cadre englobant toutes les poses de l'animation et ses accessoires.
  static Rect boundsOf(FigureMotion motion) {
    return _boundsCache.putIfAbsent(motion, () {
      Rect? rect;
      void include(Rect r) => rect = rect?.expandToInclude(r) ?? r;
      const samples = 24;
      for (var i = 0; i < samples; i++) {
        final pose = motion.poseAt(i / samples);
        for (final p in computeJoints(
          pose.angles,
          motion.view,
          pose.root,
        ).values) {
          include(
            Rect.fromCircle(
              center: Offset(p.x, p.y),
              radius: FigureProportions.headRadius + 0.06,
            ),
          );
        }
      }
      for (final prop in motion.props) {
        include(switch (prop) {
          PropBox(:final topLeft, :final bottomRight) => Rect.fromLTRB(
            topLeft.x,
            // Un mur ne fait pas grandir le cadre au-dessus du mannequin.
            math.max(topLeft.y, rect?.top ?? topLeft.y),
            bottomRight.x,
            bottomRight.y,
          ),
          PropBar(:final at) => Rect.fromCircle(
            center: Offset(at.x, at.y),
            radius: 0.08,
          ),
        });
      }
      return rect ?? Rect.zero;
    });
  }

  // Épaisseurs (rayons) des segments, en unités du mannequin.
  static const Map<FigureSegment, (double, double)> _limbRadii = {
    FigureSegment.upperArm: (0.046, 0.037),
    FigureSegment.forearm: (0.036, 0.027),
    FigureSegment.thigh: (0.066, 0.047),
    FigureSegment.shin: (0.046, 0.032),
  };

  Color _colorFor(FigureSegment segment, {required bool far}) {
    final base = switch (segmentRole(segment, highlights)) {
      MuscleRole.primary => AriseColors.musclePrimary,
      MuscleRole.secondary => AriseColors.muscleSecondary,
      null => AriseColors.parchment,
    };
    return far ? Color.lerp(base, AriseColors.abyss, 0.5)! : base;
  }

  bool _worked(FigureSegment segment) =>
      segmentRole(segment, highlights) != null;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = boundsOf(motion);
    final scale = math.min(
      size.width / bounds.width,
      size.height / bounds.height,
    );
    final offset = Offset(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );
    Offset at(Point2 p) => Offset(p.x * scale, p.y * scale) + offset;

    final pose = motion.poseAt(t);
    final j = computeJoints(pose.angles, motion.view, pose.root);

    // Sol : au niveau y = 0 s'il est visible, sinon sous le mouvement.
    final floorY = math.min(0, bounds.bottom) * scale + offset.dy;
    final groundY = (motion.ground && bounds.bottom > -0.05)
        ? math.max(floorY, bounds.bottom * scale + offset.dy - 0.06 * scale)
        : null;
    if (groundY != null) _ground(canvas, size, groundY, j, at, scale);

    for (final prop in motion.props) {
      _prop(canvas, prop, at, scale);
    }

    // Positions extrêmes en transparence : l'amplitude se lit d'un coup
    // d'œil, même en pause.
    if (motion.keys.length == 2) {
      for (final key in motion.keys) {
        _ghost(
          canvas,
          computeJoints(key.angles, motion.view, key.root),
          at,
          scale,
        );
      }
    }

    _figure(canvas, j, at, scale);
  }

  void _ground(
    Canvas canvas,
    Size size,
    double y,
    Map<String, Point2> j,
    Offset Function(Point2) at,
    double scale,
  ) {
    canvas
      ..drawRect(
        Rect.fromLTRB(0, y, size.width, size.height),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AriseColors.wood.withValues(alpha: 0.35),
              AriseColors.wood.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(0, y, size.width, size.height)),
      )
      ..drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0x00D4A84B), AriseColors.gold, Color(0x00D4A84B)],
          ).createShader(Rect.fromLTWH(0, y - 1, size.width, 2))
          ..strokeWidth = 1.5,
      );
    // Ombre portée sous le mannequin (largeur des appuis).
    final xs = [for (final p in j.values) at(p).dx]..sort();
    final width = (xs.last - xs.first).clamp(0.3 * scale, 2.2 * scale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset((xs.first + xs.last) / 2, y),
        width: width + 0.2 * scale,
        height: 0.07 * scale,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
  }

  void _prop(
    Canvas canvas,
    FigureProp prop,
    Offset Function(Point2) at,
    double scale,
  ) {
    switch (prop) {
      case PropBox(:final topLeft, :final bottomRight):
        final rect = Rect.fromPoints(at(topLeft), at(bottomRight));
        final wall = (bottomRight.y - topLeft.y) > 1.2;
        final r = RRect.fromRectAndRadius(rect, Radius.circular(0.02 * scale));
        canvas
          ..drawRRect(
            r,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: wall
                    ? const [AriseColors.stoneLight, AriseColors.stone]
                    : const [AriseColors.woodLight, AriseColors.wood],
              ).createShader(rect),
          )
          ..drawRRect(
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = AriseColors.abyss,
          );
        if (!wall) {
          // Arête claire du plateau.
          canvas.drawLine(
            rect.topLeft + const Offset(2, 1.5),
            rect.topRight + const Offset(-2, 1.5),
            Paint()
              ..color = AriseColors.goldBright.withValues(alpha: 0.5)
              ..strokeWidth = 1.5,
          );
        }
      case PropBar(at: final point):
        final c = at(point);
        canvas
          ..drawCircle(c, 0.045 * scale, Paint()..color = AriseColors.abyss)
          ..drawCircle(
            c,
            0.035 * scale,
            Paint()
              ..shader = const RadialGradient(
                center: Alignment(-0.4, -0.4),
                colors: [AriseColors.coinSilver, AriseColors.stoneLight],
              ).createShader(Rect.fromCircle(center: c, radius: 0.035 * scale)),
          );
    }
  }

  void _ghost(
    Canvas canvas,
    Map<String, Point2> j,
    Offset Function(Point2) at,
    double scale,
  ) {
    final paint = Paint()
      ..color = AriseColors.goldBright.withValues(alpha: 0.13)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.06 * scale;
    for (final (a, b) in _bones) {
      canvas.drawLine(at(j[a]!), at(j[b]!), paint);
    }
    canvas.drawCircle(
      at(j['head']!),
      FigureProportions.headRadius * scale,
      Paint()..color = AriseColors.goldBright.withValues(alpha: 0.13),
    );
  }

  static const _bones = [
    ('root', 'neck'),
    ('shoulder_n', 'elbow_n'),
    ('elbow_n', 'hand_n'),
    ('shoulder_f', 'elbow_f'),
    ('elbow_f', 'hand_f'),
    ('hip_n', 'knee_n'),
    ('knee_n', 'ankle_n'),
    ('hip_f', 'knee_f'),
    ('knee_f', 'ankle_f'),
  ];

  void _figure(
    Canvas canvas,
    Map<String, Point2> j,
    Offset Function(Point2) at,
    double scale,
  ) {
    final outline = 0.016 * scale;

    // Segment galbé : deux disques reliés, cerné de sombre ; halo coloré
    // quand le segment travaille.
    void limb(
      String a,
      String b,
      FigureSegment segment, {
      required bool far,
      double? r1,
      double? r2,
    }) {
      final radii = _limbRadii[segment];
      final from = at(j[a]!);
      final to = at(j[b]!);
      final ra = (r1 ?? radii!.$1) * scale;
      final rb = (r2 ?? radii!.$2) * scale;
      if (!far && _worked(segment)) {
        _capsule(
          canvas,
          from,
          to,
          ra + 0.03 * scale,
          rb + 0.03 * scale,
          Paint()
            ..color = _colorFor(segment, far: false).withValues(alpha: 0.22),
        );
      }
      _capsule(
        canvas,
        from,
        to,
        ra + outline,
        rb + outline,
        Paint()..color = AriseColors.abyss,
      );
      _capsule(
        canvas,
        from,
        to,
        ra,
        rb,
        Paint()..color = _colorFor(segment, far: far),
      );
    }

    void joint(String name, double radius, {required bool far}) {
      final c = at(j[name]!);
      canvas
        ..drawCircle(
          c,
          (radius + 0.012) * scale,
          Paint()..color = AriseColors.abyss,
        )
        ..drawCircle(
          c,
          radius * scale,
          Paint()
            ..color = far
                ? Color.lerp(
                    AriseColors.parchmentMuted,
                    AriseColors.abyss,
                    0.5,
                  )!
                : AriseColors.parchmentMuted,
        );
    }

    void leg(String side, {required bool far}) {
      limb('hip_$side', 'knee_$side', FigureSegment.thigh, far: far);
      limb('knee_$side', 'ankle_$side', FigureSegment.shin, far: far);
      limb(
        'ankle_$side',
        'toe_$side',
        FigureSegment.shin,
        far: far,
        r1: 0.03,
        r2: 0.022,
      );
      joint('knee_$side', 0.04, far: far);
    }

    void arm(String side, {required bool far}) {
      limb('shoulder_$side', 'elbow_$side', FigureSegment.upperArm, far: far);
      limb('elbow_$side', 'hand_$side', FigureSegment.forearm, far: far);
      joint('elbow_$side', 0.03, far: far);
      final hand = at(j['hand_$side']!);
      canvas
        ..drawCircle(hand, 0.04 * scale, Paint()..color = AriseColors.abyss)
        ..drawCircle(
          hand,
          0.028 * scale,
          Paint()..color = _colorFor(FigureSegment.forearm, far: far),
        );
    }

    final front = motion.view == MotionView.front;
    // Côté éloigné d'abord, assombri.
    leg('f', far: !front);
    arm('f', far: !front);
    // Tronc : bassin étroit, buste large.
    limb('root', 'neck', FigureSegment.torso, far: false, r1: 0.085, r2: 0.11);
    final pelvis = at(j['root']!);
    canvas
      ..drawCircle(
        pelvis,
        0.1 * scale + outline,
        Paint()..color = AriseColors.abyss,
      )
      ..drawCircle(
        pelvis,
        0.1 * scale,
        Paint()..color = _colorFor(FigureSegment.pelvis, far: false),
      );
    leg('n', far: false);
    for (final side in front ? const ['n', 'f'] : const ['n']) {
      final c = at(j['shoulder_$side']!);
      canvas
        ..drawCircle(
          c,
          0.07 * scale + outline,
          Paint()..color = AriseColors.abyss,
        )
        ..drawCircle(
          c,
          0.07 * scale,
          Paint()..color = _colorFor(FigureSegment.shoulder, far: false),
        );
    }
    limb('neck', 'head', FigureSegment.head, far: false, r1: 0.04, r2: 0.035);
    _head(canvas, j, at, scale, outline);
    arm('n', far: false);
  }

  void _head(
    Canvas canvas,
    Map<String, Point2> j,
    Offset Function(Point2) at,
    double scale,
    double outline,
  ) {
    final c = at(j['head']!);
    final r = FigureProportions.headRadius * scale;
    canvas
      ..drawCircle(c, r + outline, Paint()..color = AriseColors.abyss)
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [AriseColors.parchment, AriseColors.parchmentMuted],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    // Regard : de profil, un œil du côté où le visage est tourné ; de face,
    // deux yeux.
    final neck = at(j['neck']!);
    final up = (c - neck) / math.max((c - neck).distance, 1e-6);
    final eye = Paint()..color = AriseColors.abyss;
    if (motion.view == MotionView.side) {
      final facing = Offset(-up.dy, up.dx);
      canvas.drawCircle(c + facing * r * 0.55 + up * r * 0.15, r * 0.14, eye);
    } else {
      final side = Offset(-up.dy, up.dx);
      for (final s in const [-1.0, 1.0]) {
        canvas.drawCircle(
          c + side * r * 0.38 * s + up * r * 0.1,
          r * 0.12,
          eye,
        );
      }
    }
  }

  static void _capsule(
    Canvas canvas,
    Offset a,
    Offset b,
    double ra,
    double rb,
    Paint paint,
  ) {
    final d = b - a;
    final length = d.distance;
    if (length < 1e-3) {
      canvas.drawCircle(a, math.max(ra, rb), paint);
      return;
    }
    final n = Offset(-d.dy, d.dx) / length;
    final path = Path()
      ..moveTo(a.dx + n.dx * ra, a.dy + n.dy * ra)
      ..lineTo(b.dx + n.dx * rb, b.dy + n.dy * rb)
      ..lineTo(b.dx - n.dx * rb, b.dy - n.dy * rb)
      ..lineTo(a.dx - n.dx * ra, a.dy - n.dy * ra)
      ..close();
    canvas
      ..drawPath(path, paint)
      ..drawCircle(a, ra, paint)
      ..drawCircle(b, rb, paint);
  }

  @override
  bool shouldRepaint(covariant FigurePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.motion != motion ||
      oldDelegate.highlights != highlights;
}
