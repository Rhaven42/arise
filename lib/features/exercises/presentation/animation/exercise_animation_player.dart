import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_animation_player.g.dart';

/// Lecteur d'animation d'exercice, indépendant du moteur de rendu.
///
/// L'implémentation actuelle dessine un mannequin 2D original ; un lecteur
/// 3D (Rive, glb, Unity) pourra la remplacer sans changer les écrans.
abstract interface class ExerciseAnimationPlayer {
  Widget build({
    required String? motionId,
    required Map<MuscleId, MuscleRole> highlights,
    required String semanticLabel,
  });
}

/// Lecteur 2D par défaut.
class FigureAnimationPlayer implements ExerciseAnimationPlayer {
  const FigureAnimationPlayer();

  @override
  Widget build({
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
