import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/presentation/animation/coach_video_demo.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_animation_player.g.dart';

/// Lecteur de démonstration d'exercice, indépendant de sa source.
///
/// L'implémentation actuelle montre la vidéo du prof du monde, avec le
/// mannequin 2D articulé quand une vidéo manque.
abstract interface class ExerciseAnimationPlayer {
  Widget build({
    required String exerciseId,
    required String? motionId,
    required Map<MuscleId, MuscleRole> highlights,
    required String semanticLabel,
  });
}

/// Mannequin 2D.
class FigureAnimationPlayer implements ExerciseAnimationPlayer {
  const FigureAnimationPlayer();

  @override
  Widget build({
    required String exerciseId,
    required String? motionId,
    required Map<MuscleId, MuscleRole> highlights,
    required String semanticLabel,
  }) {
    return FigureAnimation(
      motionId: motionId,
      highlights: highlights,
      semanticLabel: semanticLabel,
    );
  }
}

/// Vidéo du prof du monde (mannequin 2D pour un mouvement sans vidéo).
class CoachAnimationPlayer implements ExerciseAnimationPlayer {
  const CoachAnimationPlayer();

  @override
  Widget build({
    required String exerciseId,
    required String? motionId,
    required Map<MuscleId, MuscleRole> highlights,
    required String semanticLabel,
  }) {
    return CoachVideoDemo(
      motionId: motionId,
      highlights: highlights,
      semanticLabel: semanticLabel,
    );
  }
}

@Riverpod(keepAlive: true)
ExerciseAnimationPlayer exerciseAnimationPlayer(Ref ref) =>
    const CoachAnimationPlayer();
