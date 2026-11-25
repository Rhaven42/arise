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
    this.landscape = false,
  });

  final SceneLighting lighting;
  final SceneFocus focus;

  /// Le personnage est peint devant un paysage fourni par l'écran :
  /// l'éclairage ne fait plus que teinter ce paysage (pas de dégradé).
  final bool landscape;

  CharacterScene copyWith({
    SceneLighting? lighting,
    SceneFocus? focus,
    bool? landscape,
  }) => CharacterScene(
    lighting: lighting ?? this.lighting,
    focus: focus ?? this.focus,
    landscape: landscape ?? this.landscape,
  );

  @override
  bool operator ==(Object other) =>
      other is CharacterScene &&
      other.lighting == lighting &&
      other.focus == focus &&
      other.landscape == landscape;

  @override
  int get hashCode => Object.hash(lighting, focus, landscape);
}
