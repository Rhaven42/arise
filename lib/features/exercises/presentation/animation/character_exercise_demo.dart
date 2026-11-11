import 'package:arise/core/anatomy/muscle.dart';
import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/domain/character_scene.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:arise/features/character_creation/domain/character_rules.dart';
import 'package:arise/features/character_creation/presentation/character_providers.dart';
import 'package:arise/features/exercises/presentation/animation/figure_animation.dart';
import 'package:arise/features/exercises/presentation/animation/figure_motion.dart';
import 'package:arise/features/inventory/domain/inventory.dart';
import 'package:arise/features/inventory/domain/inventory_rules.dart';
import 'package:arise/features/inventory/presentation/inventory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Démonstration d'un exercice par le personnage du joueur (ou un
/// personnage par défaut tant qu'il n'a pas été créé), en 3D, avec son
/// équipement.
///
/// Le mannequin 2D reste utilisé quand le système demande de réduire les
/// animations (il peut être mis en pause) ou si le mouvement est inconnu.
class CharacterExerciseDemo extends ConsumerWidget {
  const CharacterExerciseDemo({
    required this.motionId,
    required this.highlights,
    required this.semanticLabel,
    super.key,
  });

  final String? motionId;
  final Map<MuscleId, MuscleRole> highlights;
  final String semanticLabel;

  /// Cadrage adapté à la vue du mouvement.
  static SceneFocus focusFor(MotionView view) => switch (view) {
    MotionView.side => SceneFocus.exerciseSide,
    MotionView.front => SceneFocus.exerciseFront,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motions = ref.watch(figureMotionsProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Mouvements en cours de lecture : rien n'est affiché (pas d'aller-retour
    // entre le mannequin et le personnage).
    if (!motions.hasValue && !motions.hasError && !reduceMotion) {
      return Semantics(label: semanticLabel, child: const SizedBox.expand());
    }
    final motion = motions.value?[motionId];
    if (motion == null || reduceMotion) {
      return FigureAnimation(
        motionId: motionId,
        highlights: highlights,
        semanticLabel: semanticLabel,
      );
    }
    final sheet = ref.watch(savedCharacterProvider).value ?? defaultSheet();
    final inventory = ref.watch(inventoryProvider).value ?? const Inventory();
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: ref
            .watch(characterRendererProvider)
            .build(
              appearance: CharacterAppearance.of(
                sheet,
                loadout: loadoutOf(inventory),
              ),
              scene: CharacterScene(
                focus: focusFor(motion.view),
                motion: motionId,
              ),
            ),
      ),
    );
  }
}
