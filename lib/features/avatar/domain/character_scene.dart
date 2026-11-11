import 'package:freezed_annotation/freezed_annotation.dart';

/// Éclairage de la scène.
enum SceneLighting { day, night, tavern }

/// Cadrage de la caméra.
enum SceneFocus { body, face }

/// Réglages de la scène autour du personnage (pas enregistrés dans la
/// fiche).
@immutable
class CharacterScene {
  const CharacterScene({
    this.lighting = SceneLighting.tavern,
    this.focus = SceneFocus.body,
  });

  final SceneLighting lighting;
  final SceneFocus focus;

  CharacterScene copyWith({SceneLighting? lighting, SceneFocus? focus}) =>
      CharacterScene(
        lighting: lighting ?? this.lighting,
        focus: focus ?? this.focus,
      );

  @override
  bool operator ==(Object other) =>
      other is CharacterScene &&
      other.lighting == lighting &&
      other.focus == focus;

  @override
  int get hashCode => Object.hash(lighting, focus);
}
