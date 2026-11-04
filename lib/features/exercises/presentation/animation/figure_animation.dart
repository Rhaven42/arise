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

/// Dessin du mannequin à l'instant [t] de l'animation.
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

  /// Cadre englobant toutes les poses de l'animation.
  static Rect boundsOf(FigureMotion motion) {
    return _boundsCache.putIfAbsent(motion, () {
      var rect = Rect.zero;
      var first = true;
      const samples = 24;
      for (var i = 0; i < samples; i++) {
        final pose = motion.poseAt(i / samples);
        for (final p in computeJoints(
          pose.angles,
          motion.view,
          pose.root,
        ).values) {
          final point = Rect.fromCircle(
            center: Offset(p.x, p.y),
            radius: FigureProportions.headRadius + 0.06,
          );
          rect = first ? point : rect.expandToInclude(point);
          first = false;
        }
      }
      return rect;
    });
  }

  Color _colorFor(FigureSegment segment, {required bool far}) {
    final base = switch (segmentRole(segment, highlights)) {
      MuscleRole.primary => AriseColors.musclePrimary,
      MuscleRole.secondary => AriseColors.muscleSecondary,
      null => AriseColors.parchmentMuted,
    };
    return far ? Color.lerp(base, AriseColors.abyss, 0.45)! : base;
  }

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

    // Sol au point le plus bas de l'animation.
    final groundY = bounds.bottom * scale + offset.dy - 0.05 * scale;
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = AriseColors.woodLight
        ..strokeWidth = 2,
    );

    void bone(
      String a,
      String b,
      FigureSegment segment,
      double width, {
      required bool far,
    }) {
      final from = at(j[a]!);
      final to = at(j[b]!);
      canvas
        ..drawLine(
          from,
          to,
          Paint()
            ..color = AriseColors.abyss
            ..strokeWidth = (width + 0.025) * scale
            ..strokeCap = StrokeCap.round,
        )
        ..drawLine(
          from,
          to,
          Paint()
            ..color = _colorFor(segment, far: far)
            ..strokeWidth = width * scale
            ..strokeCap = StrokeCap.round,
        );
    }

    void limbs(String side, {required bool far}) {
      bone('hip_$side', 'knee_$side', FigureSegment.thigh, 0.11, far: far);
      bone('knee_$side', 'ankle_$side', FigureSegment.shin, 0.085, far: far);
      bone('ankle_$side', 'toe_$side', FigureSegment.shin, 0.05, far: far);
    }

    void arm(String side, {required bool far}) {
      bone(
        'shoulder_$side',
        'elbow_$side',
        FigureSegment.upperArm,
        0.08,
        far: far,
      );
      bone('elbow_$side', 'hand_$side', FigureSegment.forearm, 0.065, far: far);
    }

    final front = motion.view == MotionView.front;
    limbs('f', far: !front);
    arm('f', far: !front);
    bone('root', 'neck', FigureSegment.torso, 0.17, far: false);
    canvas
      ..drawCircle(
        at(j['root']!),
        0.1 * scale,
        Paint()..color = AriseColors.abyss,
      )
      ..drawCircle(
        at(j['root']!),
        0.085 * scale,
        Paint()..color = _colorFor(FigureSegment.pelvis, far: false),
      );
    limbs('n', far: false);
    for (final side in front ? const ['n', 'f'] : const ['n']) {
      canvas
        ..drawCircle(
          at(j['shoulder_$side']!),
          0.075 * scale,
          Paint()..color = AriseColors.abyss,
        )
        ..drawCircle(
          at(j['shoulder_$side']!),
          0.06 * scale,
          Paint()..color = _colorFor(FigureSegment.shoulder, far: false),
        );
    }
    arm('n', far: false);
    bone('neck', 'head', FigureSegment.head, 0.06, far: false);
    canvas
      ..drawCircle(
        at(j['head']!),
        (FigureProportions.headRadius + 0.012) * scale,
        Paint()..color = AriseColors.abyss,
      )
      ..drawCircle(
        at(j['head']!),
        FigureProportions.headRadius * scale,
        Paint()..color = AriseColors.parchment,
      );
  }

  @override
  bool shouldRepaint(covariant FigurePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.motion != motion ||
      oldDelegate.highlights != highlights;
}
