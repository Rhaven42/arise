import 'package:arise/features/avatar/domain/character_appearance.dart';
import 'package:arise/features/avatar/presentation/character_renderer.dart';
import 'package:flutter/widgets.dart';

/// Rendu factice pour les tests : affiche l'identifiant du modèle et garde
/// la dernière apparence demandée.
class FakeCharacterRenderer implements CharacterRenderer {
  CharacterAppearance? last;

  @override
  Widget build({required CharacterAppearance appearance, Key? key}) {
    last = appearance;
    return Center(key: key, child: Text('rendu:${appearance.modelId}'));
  }
}
