import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/presentation/animation/exercise_photo_demo.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_animation_player.g.dart';

/// Lecteur de démonstration d'exercice, indépendant de sa source.
///
/// L'implémentation par défaut montre les photos d'un athlète (départ et
/// arrivée en fondu) ; le mannequin 2D reste disponible.
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

/// Photos d'un athlète (mannequin 2D pour un exercice sans photo).
class PhotoAnimationPlayer implements ExerciseAnimationPlayer {
  const PhotoAnimationPlayer();

  @override
  Widget build({
    required String exerciseId,
    required String? motionId,
    required Map<MuscleId, MuscleRole> highlights,
    required String semanticLabel,
  }) {
    return ExercisePhotoDemo(
      exerciseId: exerciseId,
      motionId: motionId,
      highlights: highlights,
      semanticLabel: semanticLabel,
    );
  }
}

@Riverpod(keepAlive: true)
ExerciseAnimationPlayer exerciseAnimationPlayer(Ref ref) =>
    const PhotoAnimationPlayer();
