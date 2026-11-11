import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/exercises/presentation/animation/character_exercise_demo.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_animation_player.g.dart';

/// Lecteur d'animation d'exercice, indépendant du moteur de rendu.
///
/// L'implémentation par défaut fait exécuter le mouvement au personnage 3D
/// du joueur ; le mannequin 2D reste disponible.
abstract interface class ExerciseAnimationPlayer {
  Widget build({
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

/// Personnage du joueur en 3D.
class CharacterAnimationPlayer implements ExerciseAnimationPlayer {
  const CharacterAnimationPlayer();

  @override
  Widget build({
    required String? motionId,
    required Map<MuscleId, MuscleRole> highlights,
    required String semanticLabel,
  }) {
    return CharacterExerciseDemo(
      motionId: motionId,
      highlights: highlights,
      semanticLabel: semanticLabel,
    );
  }
}

@Riverpod(keepAlive: true)
ExerciseAnimationPlayer exerciseAnimationPlayer(Ref ref) =>
    const CharacterAnimationPlayer();
