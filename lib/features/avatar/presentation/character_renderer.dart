import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/presentation/webview_character_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'character_renderer.g.dart';

/// Affiche un personnage, quel que soit le moteur (WebGL embarqué
/// aujourd'hui, Unity ou Godot plus tard). Aucun type de moteur n'apparaît
/// dans cette interface.
abstract interface class CharacterRenderer {
  Widget build({required CharacterAppearance appearance, Key? key});
}

/// Moteur de rendu utilisé par l'application (remplacé dans les tests).
@Riverpod(keepAlive: true)
CharacterRenderer characterRenderer(Ref ref) =>
    const WebViewCharacterRenderer();
