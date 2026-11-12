import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_animation_player.g.dart';

/// Lecteur de démonstration d'exercice, indépendant de sa source.
///
/// L'implémentation actuelle est le mannequin 2D articulé ; un rendu 3D
/// pourra la remplacer sans toucher aux écrans.
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

@Riverpod(keepAlive: true)
ExerciseAnimationPlayer exerciseAnimationPlayer(Ref ref) =>
    const FigureAnimationPlayer();
