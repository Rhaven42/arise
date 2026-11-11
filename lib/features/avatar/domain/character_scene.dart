import 'package:freezed_annotation/freezed_annotation.dart';

/// Éclairage de la scène.
enum SceneLighting { day, night, tavern }

/// Cadrage de la caméra.
enum SceneFocus {
  body,
  face,

  /// Démonstration d'exercice vue de profil.
  exerciseSide,

  /// Démonstration d'exercice vue de face.
  exerciseFront,
}

/// Réglages de la scène autour du personnage (pas enregistrés dans la
/// fiche).
@immutable
class CharacterScene {
  const CharacterScene({
    this.lighting = SceneLighting.tavern,
    this.focus = SceneFocus.body,
    this.motion,
  });

  final SceneLighting lighting;
  final SceneFocus focus;

  /// Mouvement d'exercice joué en boucle (identifiant d'animation), ou
  /// `null` pour la pose détendue.
  final String? motion;

  CharacterScene copyWith({SceneLighting? lighting, SceneFocus? focus}) =>
      CharacterScene(
        lighting: lighting ?? this.lighting,
        focus: focus ?? this.focus,
        motion: motion,
      );

  @override
  bool operator ==(Object other) =>
      other is CharacterScene &&
      other.lighting == lighting &&
      other.focus == focus &&
      other.motion == motion;

  @override
  int get hashCode => Object.hash(lighting, focus, motion);
}
